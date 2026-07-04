import AVFoundation
import CoreGraphics
import Foundation

final class SoundEngine {
    static let shared = SoundEngine()

    private struct SamplePool {
        let buffer: AVAudioPCMBuffer
        let playerNodes: [AVAudioPlayerNode]
    }

    private let playersPerSample = 4
    private let lock = NSLock()

    private let engine = AVAudioEngine()
    private let environmentNode = AVAudioEnvironmentNode()
    private let mixerNode = AVAudioMixerNode()

    private var profile: SoundProfile = SoundProfile.standard(for: .default)
    private var samplePools: [KeyCategory: [SamplePool]] = [:]
    private var roundRobinIndexes: [KeyCategory: Int] = [:]
    private var spatialAudioEnabled = true

    private init() {
        setupEngine()
        reloadProfile(.default)
    }

    deinit {
        engine.stop()
    }

    func reloadProfile(_ profileID: SoundProfileID) {
        lock.lock()
        defer { lock.unlock() }

        teardownSamplePools()

        profile = SoundProfile.standard(for: profileID)
        samplePools = [:]
        roundRobinIndexes = [:]

        for category in [KeyCategory.normal, .space, .enter, .backspace, .modifier] {
            let urls = profile.bundleURLs(for: category)
            let pools = urls.compactMap { url -> SamplePool? in
                guard let buffer = loadPCMBuffer(from: url) else {
                    return nil
                }

                let playerNodes = (0..<playersPerSample).compactMap { _ -> AVAudioPlayerNode? in
                    let playerNode = AVAudioPlayerNode()
                    engine.attach(playerNode)
                    connectPlayerNode(playerNode, format: buffer.format)
                    return playerNode
                }

                return playerNodes.isEmpty ? nil : SamplePool(buffer: buffer, playerNodes: playerNodes)
            }

            if !pools.isEmpty {
                samplePools[category] = pools
            }
        }

        ensureEngineRunning()

        #if DEBUG
        if samplePools.isEmpty {
            print("[Taptaap] No sound files found for profile '\(profileID.rawValue)'. Add .wav files under Resources/Sounds/\(profileID.rawValue)/")
        }
        #endif
    }

    func setOutputVolume(_ volume: Float) {
        lock.lock()
        mixerNode.outputVolume = max(0, min(volume, 1))
        lock.unlock()
    }

    func setSpatialAudioEnabled(_ enabled: Bool) {
        lock.lock()
        defer { lock.unlock() }

        guard spatialAudioEnabled != enabled else { return }
        spatialAudioEnabled = enabled
        reconnectAllPlayerNodes()
        applySpatialEnvironmentSettings()
    }

    /// Plays a short preview of the active profile's normal key sound.
    /// Safe to call from the menu UI without Input Monitoring permission.
    func playPreview() {
        lock.lock()
        guard let pools = samplePools[.normal], let pool = pools.first else {
            lock.unlock()
            return
        }

        let playerNode = pool.playerNodes[0]
        let buffer = pool.buffer
        lock.unlock()

        schedulePlayback(on: playerNode, buffer: buffer, position: Self.previewPosition)
    }

    /// Called directly from the CGEventTap callback for minimum latency.
    func play(keyCode: CGKeyCode) {
        let category = KeyCodeMapper.category(for: keyCode)
        let position = KeyCodeMapper.spatialPosition(for: keyCode)

        lock.lock()
        guard let pools = samplePools[category], !pools.isEmpty else {
            lock.unlock()
            return
        }

        let poolIndex = roundRobinIndexes[category, default: 0]
        roundRobinIndexes[category] = poolIndex + 1

        let pool = pools[poolIndex % pools.count]
        let playerNode = pool.playerNodes[(poolIndex / pools.count) % pool.playerNodes.count]
        let buffer = pool.buffer
        lock.unlock()

        schedulePlayback(on: playerNode, buffer: buffer, position: position)
    }

    private static let previewPosition = AVAudio3DPoint(x: 0, y: 0, z: -0.35)

    private func schedulePlayback(
        on playerNode: AVAudioPlayerNode,
        buffer: AVAudioPCMBuffer,
        position: AVAudio3DPoint
    ) {
        ensureEngineRunning()

        if spatialAudioEnabled {
            playerNode.position = position
        }
        if playerNode.isPlaying {
            playerNode.stop()
        }
        playerNode.scheduleBuffer(buffer, at: nil, options: .interrupts)
        playerNode.play()
    }

    private func setupEngine() {
        engine.attach(environmentNode)
        engine.attach(mixerNode)
        engine.connect(environmentNode, to: mixerNode, format: nil)
        engine.connect(mixerNode, to: engine.outputNode, format: nil)

        applySpatialEnvironmentSettings()
        ensureEngineRunning()
    }

    private func applySpatialEnvironmentSettings() {
        environmentNode.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
        environmentNode.listenerAngularOrientation = AVAudio3DAngularOrientation(yaw: 0, pitch: 0, roll: 0)
        environmentNode.reverbParameters.enable = spatialAudioEnabled
        environmentNode.reverbBlend = spatialAudioEnabled ? 0.1 : 0
    }

    private func connectPlayerNode(_ playerNode: AVAudioPlayerNode, format: AVAudioFormat) {
        let destination: AVAudioNode = spatialAudioEnabled ? environmentNode : mixerNode
        engine.connect(playerNode, to: destination, format: format)
        configurePlayerNode(playerNode)
    }

    private func configurePlayerNode(_ playerNode: AVAudioPlayerNode) {
        guard spatialAudioEnabled else { return }

        playerNode.renderingAlgorithm = .HRTFHQ
        playerNode.sourceMode = .pointSource
        playerNode.pointSourceInHeadMode = .mono
    }

    private func reconnectAllPlayerNodes() {
        let wasRunning = engine.isRunning
        if wasRunning {
            engine.stop()
        }

        for pools in samplePools.values {
            for pool in pools {
                for playerNode in pool.playerNodes {
                    if playerNode.isPlaying {
                        playerNode.stop()
                    }
                    engine.disconnectNodeOutput(playerNode)
                    connectPlayerNode(playerNode, format: pool.buffer.format)
                }
            }
        }

        if wasRunning {
            ensureEngineRunning()
        }
    }

    private func teardownSamplePools() {
        if engine.isRunning {
            engine.stop()
        }

        for pools in samplePools.values {
            for pool in pools {
                for playerNode in pool.playerNodes {
                    if playerNode.isPlaying {
                        playerNode.stop()
                    }
                    engine.disconnectNodeOutput(playerNode)
                    engine.detach(playerNode)
                }
            }
        }
    }

    private func loadPCMBuffer(from url: URL) -> AVAudioPCMBuffer? {
        guard let audioFile = try? AVAudioFile(forReading: url) else {
            return nil
        }

        let frameCount = AVAudioFrameCount(audioFile.length)
        guard frameCount > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: frameCount) else {
            return nil
        }

        do {
            try audioFile.read(into: buffer)
            buffer.frameLength = frameCount
            return buffer
        } catch {
            #if DEBUG
            print("[Taptaap] Failed to load sound file at \(url.lastPathComponent): \(error.localizedDescription)")
            #endif
            return nil
        }
    }

    private func ensureEngineRunning() {
        guard !engine.isRunning else { return }

        do {
            try engine.start()
        } catch {
            #if DEBUG
            print("[Taptaap] Failed to start audio engine: \(error.localizedDescription)")
            #endif
        }
    }
}

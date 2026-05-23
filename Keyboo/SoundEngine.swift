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

    private var profile: SoundProfile = SoundProfile.standard(for: .default)
    private var samplePools: [KeyCategory: [SamplePool]] = [:]
    private var roundRobinIndexes: [KeyCategory: Int] = [:]

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
                    engine.connect(playerNode, to: environmentNode, format: buffer.format)
                    configurePlayerNode(playerNode)
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
            print("[Keyboo] No sound files found for profile '\(profileID.rawValue)'. Add .wav files under Resources/Sounds/\(profileID.rawValue)/")
        }
        #endif
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

        ensureEngineRunning()

        playerNode.position = position
        if playerNode.isPlaying {
            playerNode.stop()
        }
        playerNode.scheduleBuffer(buffer, at: nil, options: .interrupts)
        playerNode.play()
    }

    private func setupEngine() {
        engine.attach(environmentNode)
        engine.connect(environmentNode, to: engine.outputNode, format: nil)

        environmentNode.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
        environmentNode.listenerAngularOrientation = AVAudio3DAngularOrientation(yaw: 0, pitch: 0, roll: 0)
        environmentNode.reverbParameters.enable = true
        environmentNode.reverbBlend = 0.1

        ensureEngineRunning()
    }

    private func configurePlayerNode(_ playerNode: AVAudioPlayerNode) {
        playerNode.renderingAlgorithm = .auto
        playerNode.sourceMode = .pointSource
        playerNode.pointSourceInHeadMode = .mono
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
            print("[Keyboo] Failed to load sound file at \(url.lastPathComponent): \(error.localizedDescription)")
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
            print("[Keyboo] Failed to start audio engine: \(error.localizedDescription)")
            #endif
        }
    }
}

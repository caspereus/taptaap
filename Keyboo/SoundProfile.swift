import Foundation
import SwiftUI

enum SoundProfileID: String, CaseIterable, Identifiable {
    case `default`
    case thock
    case mxBlue
    case speedSilver
    case boxJade
    case clicky
    case holyPanda
    case typewriter
    case topre
    case lavender
    case oreo

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .default: "Default"
        case .thock: "Thock"
        case .mxBlue: "MX Blue"
        case .speedSilver: "Speed Silver"
        case .boxJade: "Box Jade"
        case .clicky: "Clicky"
        case .holyPanda: "Holy Panda"
        case .typewriter: "Typewriter"
        case .topre: "Topre"
        case .lavender: "Lavender Purple"
        case .oreo: "Oreo"
        }
    }

    var brand: String {
        switch self {
        case .default, .thock: "Keychron"
        case .mxBlue, .speedSilver: "Cherry"
        case .boxJade: "Kailh"
        case .clicky: "Durock"
        case .holyPanda: "C³Equalz"
        case .typewriter: "NovelKeys"
        case .topre: "Topre"
        case .lavender: "Akko"
        case .oreo: "Everglide"
        }
    }

    var switchName: String {
        switch self {
        case .default: "K2 Max · Gateron Red"
        case .thock: "K2 Max · Gateron Brown"
        case .mxBlue: "MX Blue · ABS"
        case .speedSilver: "MX Speed Silver"
        case .boxJade: "Box Jade"
        case .clicky: "Alpaca"
        case .holyPanda: "Banana Split · Lubed"
        case .typewriter: "Cream"
        case .topre: "Purple Hybrid · PBT"
        case .lavender: "Lavender Purple"
        case .oreo: "Oreo"
        }
    }

    var swatchColor: Color {
        switch self {
        case .default:
            Color(red: 0.82, green: 0.18, blue: 0.18)
        case .thock:
            Color(red: 0.55, green: 0.35, blue: 0.22)
        case .mxBlue:
            Color(red: 0.15, green: 0.45, blue: 0.85)
        case .speedSilver:
            Color(red: 0.72, green: 0.74, blue: 0.78)
        case .boxJade:
            Color(red: 0.20, green: 0.62, blue: 0.45)
        case .clicky:
            Color(red: 0.78, green: 0.70, blue: 0.58)
        case .holyPanda:
            Color(red: 0.77, green: 0.65, blue: 0.42)
        case .typewriter:
            Color(red: 0.88, green: 0.84, blue: 0.72)
        case .topre:
            Color(red: 0.48, green: 0.38, blue: 0.65)
        case .lavender:
            Color(red: 0.61, green: 0.48, blue: 0.72)
        case .oreo:
            Color(red: 0.18, green: 0.18, blue: 0.20)
        }
    }

    static var profilesGroupedByBrand: [(brand: String, profiles: [SoundProfileID])] {
        let brandOrder = [
            "Keychron", "Cherry", "Kailh", "Durock", "C³Equalz",
            "NovelKeys", "Topre", "Akko", "Everglide"
        ]
        return brandOrder.compactMap { brand in
            let profiles = allCases.filter { $0.brand == brand }
            return profiles.isEmpty ? nil : (brand, profiles)
        }
    }
}

struct SoundProfile {
    let id: SoundProfileID
    let keySamples: [String]
    let spaceSamples: [String]
    let enterSamples: [String]
    let backspaceSamples: [String]
    let modifierSamples: [String]

    static let allProfiles: [SoundProfileID: SoundProfile] = Dictionary(
        uniqueKeysWithValues: SoundProfileID.allCases.map { ($0, SoundProfile.standard(for: $0)) }
    )

    static func standard(for id: SoundProfileID) -> SoundProfile {
        SoundProfile(
            id: id,
            keySamples: ["key_01.wav", "key_02.wav"],
            spaceSamples: ["space_01.wav"],
            enterSamples: ["enter_01.wav"],
            backspaceSamples: ["backspace_01.wav"],
            modifierSamples: ["modifier_01.wav"]
        )
    }

    /// Resolves bundled sound URLs. Tries profile subfolders first, then profile-prefixed
    /// flat names (Xcode synchronized groups may flatten nested resource folders).
    func bundleURLs(for category: KeyCategory) -> [URL] {
        filenames(for: category).compactMap { url(for: $0) }
    }

    private func url(for filename: String) -> URL? {
        let resourceName = filename.replacingOccurrences(of: ".wav", with: "")
        let profileFolder = id.rawValue
        let prefixedName = "\(profileFolder)_\(resourceName)"

        if let url = Bundle.main.url(
            forResource: resourceName,
            withExtension: "wav",
            subdirectory: "Sounds/\(profileFolder)"
        ) {
            return url
        }

        if let url = Bundle.main.url(
            forResource: resourceName,
            withExtension: "wav",
            subdirectory: "Resources/Sounds/\(profileFolder)"
        ) {
            return url
        }

        if let url = Bundle.main.url(forResource: prefixedName, withExtension: "wav") {
            return url
        }

        return Bundle.main.url(forResource: resourceName, withExtension: "wav")
    }

    private func filenames(for category: KeyCategory) -> [String] {
        switch category {
        case .normal: keySamples
        case .space: spaceSamples
        case .enter: enterSamples
        case .backspace: backspaceSamples
        case .modifier: modifierSamples
        }
    }
}

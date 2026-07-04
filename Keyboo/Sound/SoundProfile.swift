import Foundation
import SwiftUI

enum SoundProfileID: String, CaseIterable, Identifiable {
    case `default`
    case thock
    case mxBlue
    case mxBlack
    case mxBrown
    case mxRed
    case speedSilver
    case boxJade
    case boxWhite
    case clicky
    case holyPanda
    case bananaStock
    case typewriter
    case topre
    case lavender
    case oreo
    case crystalPurple
    case razerGreen
    case apexPro

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .default: "Default"
        case .thock: "Thock"
        case .mxBlue: "MX Blue"
        case .mxBlack: "MX Black"
        case .mxBrown: "MX Brown"
        case .mxRed: "MX Red"
        case .speedSilver: "Speed Silver"
        case .boxJade: "Box Jade"
        case .boxWhite: "Box White"
        case .clicky: "Clicky"
        case .holyPanda: "Holy Panda"
        case .bananaStock: "Banana Split"
        case .typewriter: "Typewriter"
        case .topre: "Topre"
        case .lavender: "Lavender Purple"
        case .oreo: "Oreo"
        case .crystalPurple: "Crystal Purple"
        case .razerGreen: "Razer Green"
        case .apexPro: "Apex Pro"
        }
    }

    var brand: String {
        switch self {
        case .default, .thock: "Keychron"
        case .mxBlue, .mxBlack, .mxBrown, .mxRed, .speedSilver: "Cherry"
        case .boxJade, .boxWhite: "Kailh"
        case .clicky: "Durock"
        case .holyPanda, .bananaStock: "C³Equalz"
        case .typewriter: "NovelKeys"
        case .topre: "Topre"
        case .lavender: "Akko"
        case .oreo, .crystalPurple: "Everglide"
        case .razerGreen: "Razer"
        case .apexPro: "SteelSeries"
        }
    }

    var switchName: String {
        switch self {
        case .default: "K2 Max · Gateron Red"
        case .thock: "K2 Max · Gateron Brown"
        case .mxBlue: "MX Blue · ABS"
        case .mxBlack: "MX Black · PBT"
        case .mxBrown: "MX Brown · PBT"
        case .mxRed: "MX Red · PBT"
        case .speedSilver: "MX Speed Silver"
        case .boxJade: "Box Jade"
        case .boxWhite: "Box White"
        case .clicky: "Alpaca"
        case .holyPanda: "Banana Split · Lubed"
        case .bananaStock: "Banana Split · Stock"
        case .typewriter: "Cream"
        case .topre: "Purple Hybrid · PBT"
        case .lavender: "Lavender Purple"
        case .oreo: "Oreo"
        case .crystalPurple: "Crystal Purple"
        case .razerGreen: "Green · BlackWidow"
        case .apexPro: "Apex Pro"
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
        case .mxBlack:
            Color(red: 0.12, green: 0.12, blue: 0.14)
        case .mxBrown:
            Color(red: 0.42, green: 0.28, blue: 0.18)
        case .mxRed:
            Color(red: 0.90, green: 0.22, blue: 0.24)
        case .speedSilver:
            Color(red: 0.72, green: 0.74, blue: 0.78)
        case .boxJade:
            Color(red: 0.20, green: 0.62, blue: 0.45)
        case .boxWhite:
            Color(red: 0.92, green: 0.94, blue: 0.96)
        case .clicky:
            Color(red: 0.78, green: 0.70, blue: 0.58)
        case .holyPanda:
            Color(red: 0.77, green: 0.65, blue: 0.42)
        case .bananaStock:
            Color(red: 0.92, green: 0.78, blue: 0.32)
        case .typewriter:
            Color(red: 0.88, green: 0.84, blue: 0.72)
        case .topre:
            Color(red: 0.48, green: 0.38, blue: 0.65)
        case .lavender:
            Color(red: 0.61, green: 0.48, blue: 0.72)
        case .oreo:
            Color(red: 0.18, green: 0.18, blue: 0.20)
        case .crystalPurple:
            Color(red: 0.55, green: 0.32, blue: 0.78)
        case .razerGreen:
            Color(red: 0.28, green: 0.82, blue: 0.38)
        case .apexPro:
            Color(red: 0.95, green: 0.45, blue: 0.12)
        }
    }

    static var profilesGroupedByBrand: [(brand: String, profiles: [SoundProfileID])] {
        let brandOrder = [
            "Keychron", "Cherry", "Kailh", "Durock", "C³Equalz",
            "NovelKeys", "Topre", "Akko", "Everglide", "Razer", "SteelSeries"
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

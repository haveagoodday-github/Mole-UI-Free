//
//  LanguageManager.swift
//  Mole
//
//  Created by Kehong-IOS-Dev01 on 2026/9/23.
//

import Combine
import Foundation
import SwiftUI

public enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case en = "en"
    case zhHans = "zh-Hans"
    case zhHant = "zh-Hant"
    case zhHantTW = "zh-Hant-TW"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .en:
            return "English"
        case .zhHans:
            return "简体中文"
        case .zhHant:
            return "繁體中文"
        case .zhHantTW:
            return "繁體中文 (台灣)"
        }
    }

    public var locale: Locale {
        Locale(identifier: rawValue)
    }
}

@MainActor
public final class LanguageManager: ObservableObject {
    public static let shared = LanguageManager()

    private let userDefaultsKey = "app_language"

    @Published public private(set) var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: userDefaultsKey)
            UserDefaults.standard.set([currentLanguage.rawValue], forKey: "AppleLanguages")
            updateCurrentBundle()
        }
    }

    private var currentBundle: Bundle = Bundle.main

    private init() {
        if let savedCode = UserDefaults.standard.string(forKey: userDefaultsKey),
           let matched = AppLanguage(rawValue: savedCode) {
            self.currentLanguage = matched
        } else {
            // Match preferred language from system or default to zh-Hans
            let preferred = Locale.preferredLanguages.first ?? "zh-Hans"
            if preferred.hasPrefix("zh-Hant-TW") || preferred.hasPrefix("zh-TW") {
                self.currentLanguage = .zhHantTW
            } else if preferred.hasPrefix("zh-Hant") || preferred.hasPrefix("zh-HK") || preferred.hasPrefix("zh-MO") {
                self.currentLanguage = .zhHant
            } else if preferred.hasPrefix("zh") {
                self.currentLanguage = .zhHans
            } else if preferred.hasPrefix("en") {
                self.currentLanguage = .en
            } else {
                self.currentLanguage = .zhHans
            }
        }
        updateCurrentBundle()
    }

    public func setLanguage(_ language: AppLanguage) {
        guard language != currentLanguage else { return }
        currentLanguage = language
    }

    private func updateCurrentBundle() {
        if let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            self.currentBundle = bundle
        } else {
            self.currentBundle = Bundle.main
        }
    }

    public func localizedString(_ key: String) -> String {
        currentBundle.localizedString(forKey: key, value: nil, table: nil)
    }

    public func localizedString(_ key: String, _ arguments: CVarArg...) -> String {
        let format = localizedString(key)
        return String(format: format, locale: currentLanguage.locale, arguments: arguments)
    }
}

// MARK: - String Convenience Extensions
public extension String {
    var localized: String {
        LanguageManager.shared.localizedString(self)
    }

    func localized(with arguments: CVarArg...) -> String {
        let format = LanguageManager.shared.localizedString(self)
        return String(format: format, locale: LanguageManager.shared.currentLanguage.locale, arguments: arguments)
    }

    var localizedKey: LocalizedStringKey {
        LocalizedStringKey(self)
    }
}

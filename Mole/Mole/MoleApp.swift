//
//  MoleApp.swift
//  Mole
//
//  Created by Kehong-IOS-Dev01 on 2026/9/23.
//

import SwiftUI

@main
struct MoleApp: App {
    @ObservedObject var languageManager = LanguageManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 980, minHeight: 640)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            SidebarCommands()
            CommandGroup(replacing: .appInfo) {
                Button("关于 / About") {
                    NotificationCenter.default.post(name: .showAboutWindow, object: nil)
                }
            }
            CommandGroup(after: .appInfo) {
                Button("全文件夹访问权限... / Full Disk Access...") {
                    NotificationCenter.default.post(name: .showPermissionGuide, object: nil)
                }
                Menu("语言 / Language") {
                    ForEach(AppLanguage.allCases) { lang in
                        Button(lang.displayName) {
                            languageManager.setLanguage(lang)
                        }
                    }
                }
            }
        }
    }
}

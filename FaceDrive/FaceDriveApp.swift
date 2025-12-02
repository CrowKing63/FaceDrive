//
//  FaceDriveApp.swift
//  FaceDrive
//
//  Created by 최의택 on 12/2/25.
//

import SwiftUI

@main
struct FaceDriveApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No default window; main UI is opened from the menu bar status item.
        Settings {
            EmptyView()
        }
    }
}

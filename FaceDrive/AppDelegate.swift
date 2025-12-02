import SwiftUI
import AppKit
import Combine
import ServiceManagement

// Shared services so camera/vision/mapping keep running even without a window
final class AppServices {
    static let shared = AppServices()

    let cameraManager = CameraManager()
    let faceDetector = FaceDetector()
    let actionMapper = ActionMapper()

    private var cancellables = Set<AnyCancellable>()

    private init() {
        cameraManager.setDelegate(
            faceDetector,
            queue: DispatchQueue(label: "com.facedrive.camera.delegate")
        )
        cameraManager.start()

        // Pipe face observations into the action mapper
        faceDetector.$faceObservation
            .compactMap { $0 }
            .sink { [weak self] obs in
                self?.actionMapper.process(observation: obs)
            }
            .store(in: &cancellables)
    }
}

final class LaunchAtLoginManager: ObservableObject {
    @Published var isEnabled: Bool = false

    init() {
        if #available(macOS 13.0, *) {
            isEnabled = SMAppService.mainApp.status == .enabled
        } else {
            isEnabled = false
        }
    }

    func toggle() {
        guard #available(macOS 13.0, *) else { return }

        if isEnabled {
            do {
                try SMAppService.mainApp.unregister()
                isEnabled = false
            } catch {
                print("Failed to unregister login item: \(error)")
            }
        } else {
            do {
                try SMAppService.mainApp.register()
                isEnabled = true
            } catch {
                print("Failed to register login item: \(error)")
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var dashboardWindow: NSWindow?
    private let launchAtLoginManager = LaunchAtLoginManager()
    
    // For dynamic menu updates
    private let actionMapper = AppServices.shared.actionMapper
    private let faceDetector = AppServices.shared.faceDetector
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide app from Dock and App Switcher; show only as a menu bar accessory
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "face.smiling",
                                   accessibilityDescription: "FaceDrive")
        }

        rebuildMenu()

        // Subscribe to profile changes to rebuild the menu
        actionMapper.$profiles
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.rebuildMenu()
            }
            .store(in: &cancellables)

        actionMapper.$activeProfileID
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.rebuildMenu()
            }
            .store(in: &cancellables)
            
        // Dynamic Icon Updates
        // Dynamic Icon Updates (3 States based on Calibration)
        Publishers.CombineLatest3(actionMapper.$isStartupCalibrated, actionMapper.$isPerformingAction, actionMapper.$isCalibrating)
            .receive(on: RunLoop.main)
            .sink { [weak self] (isCalibrated, isActive, isCalibrating) in
                guard let self = self, let button = self.statusItem.button else { return }
                
                if !isCalibrated || isCalibrating {
                    // Not Calibrated or Calibrating: Gray Dashed Face
                    button.image = NSImage(systemSymbolName: "face.dashed", accessibilityDescription: "Calibrating")
                    button.contentTintColor = .secondaryLabelColor
                } else if isActive {
                    // Expression Active: Green Smiling Face
                    button.image = NSImage(systemSymbolName: "face.smiling", accessibilityDescription: "Expression Active")
                    button.contentTintColor = .systemGreen
                } else {
                    // Calibrated & Idle: Default Color Smiling Face
                    button.image = NSImage(systemSymbolName: "face.smiling", accessibilityDescription: "Ready")
                    button.contentTintColor = nil // System default (white/light in dark mode)
                }
            }
            .store(in: &cancellables)
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let openItem = NSMenuItem(
            title: "Open Dashboard",
            action: #selector(openDashboard),
            keyEquivalent: ""
        )
        openItem.target = self
        menu.addItem(openItem)
        
        // Calibrate Face
        let calibrateItem = NSMenuItem(
            title: "Calibrate Face (Neutral)",
            action: #selector(calibrateFace),
            keyEquivalent: ""
        )
        calibrateItem.target = self
        menu.addItem(calibrateItem)
        
        menu.addItem(.separator())

        // --- Profiles Submenu ---
        let profilesMenuItem = NSMenuItem(title: "Profiles", action: nil, keyEquivalent: "")
        let profilesMenu = NSMenu()

        for profile in actionMapper.profiles {
            let item = NSMenuItem(
                title: profile.name,
                action: #selector(selectProfile(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = profile.id
            if profile.id == actionMapper.activeProfileID {
                item.state = .on
            }
            profilesMenu.addItem(item)
        }

        menu.setSubmenu(profilesMenu, for: profilesMenuItem)
        menu.addItem(profilesMenuItem)
        
        menu.addItem(.separator())
        
        // --- General Settings ---

        let launchItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin(_:)),
            keyEquivalent: ""
        )
        launchItem.target = self
        launchItem.state = launchAtLoginManager.isEnabled ? .on : .off
        menu.addItem(launchItem)

        let dockIconItem = NSMenuItem(
            title: "Show Dock Icon",
            action: #selector(toggleDockIcon(_:)),
            keyEquivalent: ""
        )
        dockIconItem.target = self
        dockIconItem.state = NSApp.activationPolicy() == .regular ? .on : .off
        if dockIconItem.state == .on {
            dockIconItem.title = "Hide Dock Icon"
        }
        menu.addItem(dockIconItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit FaceDrive",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func openDashboard() {
        if dashboardWindow == nil {
            let services = AppServices.shared

            let rootView = ContentView()
                .environmentObject(services.cameraManager)
                .environmentObject(services.faceDetector)
                .environmentObject(services.actionMapper)

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1200, height: 600),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.title = "FaceDrive"
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: rootView)
            dashboardWindow = window
        }

        dashboardWindow?.level = .floating // Keep on top
        dashboardWindow?.makeKeyAndOrderFront(nil)
        dashboardWindow?.orderFrontRegardless() // Force to front even if app is background
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func selectProfile(_ sender: NSMenuItem) {
        if let profileID = sender.representedObject as? UUID {
            actionMapper.selectProfile(profileID: profileID)
        }
    }
    
    @objc private func calibrateFace() {
        actionMapper.calibrate()
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        launchAtLoginManager.toggle()
        sender.state = launchAtLoginManager.isEnabled ? .on : .off
    }

    @objc private func toggleDockIcon(_ sender: NSMenuItem) {
        if NSApp.activationPolicy() == .accessory {
            NSApp.setActivationPolicy(.regular)
            sender.title = "Hide Dock Icon"
            sender.state = .on
        } else {
            NSApp.setActivationPolicy(.accessory)
            sender.title = "Show Dock Icon"
            sender.state = .off
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}


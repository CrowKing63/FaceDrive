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
            queue: DispatchQueue(label: "com.magicscroll.camera.delegate", qos: .userInteractive)
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
        
        // Prevent App Nap / Throttling
        ProcessInfo.processInfo.beginActivity(options: [.userInitiatedAllowingIdleSystemSleep, .latencyCritical], reason: "Face Tracking")

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "face.smiling",
                                   accessibilityDescription: "MagicScroll")
        }

        rebuildMenu()

        actionMapper.$isPaused
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.rebuildMenu()
            }
            .store(in: &cancellables)
            
        // Dynamic Icon Updates
        // Dynamic Icon Updates (4 States: Paused, Calibrating, Active, Idle)
        Publishers.CombineLatest4(actionMapper.$isPaused, actionMapper.$isStartupCalibrated, actionMapper.$isPerformingAction, actionMapper.$isCalibrating)
            .receive(on: RunLoop.main)
            .sink { [weak self] (isPaused, isCalibrated, isActive, isCalibrating) in
                guard let self = self, let button = self.statusItem.button else { return }
                
                if isPaused {
                    // Paused: Gray Dashed Face (like face not detected)
                    button.image = NSImage(systemSymbolName: "face.dashed", accessibilityDescription: "Paused")
                    button.contentTintColor = .secondaryLabelColor
                } else if !isCalibrated || isCalibrating {
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
        
        // Pause/Resume Toggle
        let pauseItem = NSMenuItem(
            title: actionMapper.isPaused ? "Resume" : "Pause",
            action: #selector(togglePause(_:)),
            keyEquivalent: ""
        )
        pauseItem.target = self
        menu.addItem(pauseItem)
        
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
            title: "Quit MagicScroll",
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
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 500),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.title = "MagicScroll"
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: rootView)
            dashboardWindow = window
        }

        dashboardWindow?.level = .floating // Keep on top
        dashboardWindow?.makeKeyAndOrderFront(nil)
        dashboardWindow?.orderFrontRegardless() // Force to front even if app is background
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func calibrateFace() {
        actionMapper.calibrate()
    }
    
    @objc private func togglePause(_ sender: NSMenuItem) {
        actionMapper.isPaused.toggle()
        rebuildMenu()
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


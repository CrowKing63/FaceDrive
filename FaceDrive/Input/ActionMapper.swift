import Cocoa
import Vision
import CoreGraphics
import Combine

class ActionMapper: ObservableObject {
    private let inputController = InputController()
    
    @Published var state = ExpressionState()
    @Published var config = ExpressionConfig()
    @Published var lastTriggeredAction: String?
    @Published var isPerformingAction: Bool = false
    
    // Profile Management
    @Published var profiles: [Profile] = []
    @Published var activeProfileID: UUID?
    
    // Previous state for smoothing
    private var previousState = ExpressionState()
    
    // Hold state tracking
    private var isLeftButtonHeld = false
    private var isRightButtonHeld = false
    
    // Debug log throttling
    private var lastDebugLogTime: Date?
    
    // Combo Debounce
    private var comboDebounceTimer: TimeInterval = 0.0
    private var lastActiveComboAction: FaceAction?
    
    // Debounce
    private var lastActionTime: [FaceAction: Date] = [:]
    private let clickCooldown: TimeInterval = 0.15
    
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Load profiles and the last active one
        loadProfiles()
        if let activeID = activeProfileID {
            selectProfile(profileID: activeID)
        } else if let firstProfile = profiles.first {
            selectProfile(profileID: firstProfile.id)
        } else {
            let defaultConfig = ExpressionConfig()
            let defaultProfile = Profile(name: "Default", config: defaultConfig)
            profiles.append(defaultProfile)
            saveProfiles()
            selectProfile(profileID: defaultProfile.id)
        }

        // Save active profile ID when it changes
        $activeProfileID
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveActiveProfileID()
            }
            .store(in: &cancellables)

        // Save config changes to the active profile
        $config
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] newConfig in
                self?.updateActiveProfile(with: newConfig)
            }
            .store(in: &cancellables)

        // Safety Kill Switch
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let cgEvent = event.cgEvent, cgEvent.getIntegerValueField(.eventSourceUserData) == 0xFACE {
                return
            }
            
            DispatchQueue.main.async {
                guard let self = self else { return }
                if self.isLeftButtonHeld || self.isRightButtonHeld {
                    print("⚠️ Safety Kill Switch Triggered! Releasing all buttons.")
                    if self.isLeftButtonHeld {
                        self.inputController.click(button: .left, down: false)
                        self.isLeftButtonHeld = false
                    }
                    if self.isRightButtonHeld {
                        self.inputController.click(button: .right, down: false)
                        self.isRightButtonHeld = false
                    }
                    NSSound.beep()
                }
            }
        }
        
        // Monitor mouse movement
        NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self = self else { return }
            if self.isLeftButtonHeld {
                let pos = NSEvent.mouseLocation
                if let screen = NSScreen.main {
                    let cgY = screen.frame.height - pos.y
                    self.inputController.sendDragEvent(position: CGPoint(x: pos.x, y: cgY), button: .left)
                }
            } else if self.isRightButtonHeld {
                let pos = NSEvent.mouseLocation
                if let screen = NSScreen.main {
                    let cgY = screen.frame.height - pos.y
                    self.inputController.sendDragEvent(position: CGPoint(x: pos.x, y: cgY), button: .right)
                }
            }
        }
    }
    
    private func resetAllHeldButtons() {
        if isLeftButtonHeld {
            inputController.click(button: .left, down: false)
            isLeftButtonHeld = false
            print("Emergency: Released held left button")
        }
        if isRightButtonHeld {
            inputController.click(button: .right, down: false)
            isRightButtonHeld = false
            print("Emergency: Released held right button")
        }
    }
    
    private var eyeClosedDuration: TimeInterval = 0
    private var lastFrameTime: Date = Date()
    
    func calibrate() {
        // Reset calibration state to trigger new calibration
        self.isCalibrating = true
        self.isStartupCalibrated = false
        self.calibrationStartTime = nil
        self.calibrationSamples = []
        print("⏳ Starting Manual Calibration...")
    }
    
    @Published var isCalibrating = false
    @Published var isStartupCalibrated = false
    private var calibrationStartTime: Date?
    private var calibrationSamples: [ExpressionState] = []
    private let calibrationDuration: TimeInterval = 3.0
    
    func process(observation: VNFaceObservation) {
        let now = Date()
        let dt = now.timeIntervalSince(lastFrameTime)
        lastFrameTime = now
        
        guard let landmarks = observation.landmarks else { return }
        
        // 1. Calculate Metrics
        let newState = ExpressionDetector.calculate(landmarks: landmarks, config: config)
        
        // --- Unified Calibration Logic (Auto & Manual) ---
        if !isStartupCalibrated || isCalibrating {
            if calibrationStartTime == nil {
                calibrationStartTime = now
                if isCalibrating {
                    print("⏳ Starting Manual Calibration...")
                } else {
                    print("⏳ Starting Auto-Calibration...")
                }
            }
            
            if let startTime = calibrationStartTime, now.timeIntervalSince(startTime) < calibrationDuration {
                calibrationSamples.append(newState)
                DispatchQueue.main.async {
                    self.state = newState
                }
                return
            } else {
                performStartupCalibration(landmarks: landmarks)
                isStartupCalibrated = true
                isCalibrating = false
                if isCalibrating {
                    print("✅ Manual Calibration Complete!")
                } else {
                    print("✅ Auto-Calibration Complete!")
                }
            }
        }
        
        // 2. Update State (for UI) with Smoothing
        let alpha = 1.0 - config.smoothFactor
        
        let smoothedLeftOpen = alpha * newState.leftEyeOpenness + config.smoothFactor * previousState.leftEyeOpenness
        let smoothedRightOpen = alpha * newState.rightEyeOpenness + config.smoothFactor * previousState.rightEyeOpenness
        let smoothedMouthHeight = alpha * newState.mouthOpenness + config.smoothFactor * previousState.mouthOpenness
        let smoothedMouthWidth = alpha * newState.mouthWidth + config.smoothFactor * previousState.mouthWidth
        let smoothedMouthPucker = alpha * newState.mouthPucker + config.smoothFactor * previousState.mouthPucker
        let smoothedMouthLeft = alpha * newState.mouthLeft + config.smoothFactor * previousState.mouthLeft
        let smoothedMouthRight = alpha * newState.mouthRight + config.smoothFactor * previousState.mouthRight
        let smoothedEyebrowRaise = alpha * newState.eyebrowRaise + config.smoothFactor * previousState.eyebrowRaise
        let smoothedSquint = alpha * newState.squint + config.smoothFactor * previousState.squint
        let smoothedLipsPressed = alpha * newState.lipsPressed + config.smoothFactor * previousState.lipsPressed
        
        // Local state for logic
        var currentFrameState = ExpressionState()
        currentFrameState.leftEyeOpenness = smoothedLeftOpen
        currentFrameState.rightEyeOpenness = smoothedRightOpen
        currentFrameState.mouthOpenness = smoothedMouthHeight
        currentFrameState.mouthWidth = smoothedMouthWidth
        currentFrameState.mouthPucker = smoothedMouthPucker
        currentFrameState.mouthLeft = smoothedMouthLeft
        currentFrameState.mouthRight = smoothedMouthRight
        currentFrameState.eyebrowRaise = smoothedEyebrowRaise
        currentFrameState.squint = smoothedSquint
        currentFrameState.lipsPressed = smoothedLipsPressed
        
        // Debug log
        if lastDebugLogTime == nil || now.timeIntervalSince(lastDebugLogTime!) > 1.0 {
            print("👁️ L:\(String(format: "%.2f", smoothedLeftOpen)) R:\(String(format: "%.2f", smoothedRightOpen)) | 👄 H:\(String(format: "%.2f", smoothedMouthHeight))")
            lastDebugLogTime = now
        }
        
        DispatchQueue.main.async {
            self.state = currentFrameState
            self.previousState = currentFrameState
        }
        
        // 3. Determine Active Actions
        var activeActions = Set<FaceAction>()
        var suppressIndividualActions = false
        
        // Helper to check expression status
        let isExpressionActive: (FaceExpression) -> Bool = { [weak self] expression in
            guard let self = self else { return false }
            switch expression {
            case .eyeClosed:
                let isLeftClosed = self.config.eyeClosedTriggerBelow ? (currentFrameState.leftEyeOpenness < self.config.eyeClosedThreshold) : (currentFrameState.leftEyeOpenness > self.config.eyeClosedThreshold)
                let isRightClosed = self.config.eyeClosedTriggerBelow ? (currentFrameState.rightEyeOpenness < self.config.eyeClosedThreshold) : (currentFrameState.rightEyeOpenness > self.config.eyeClosedThreshold)
                return isLeftClosed || isRightClosed
            case .mouthOpen:
                return self.config.mouthOpenTriggerBelow ? (currentFrameState.mouthOpenness < self.config.mouthOpenThreshold) : (currentFrameState.mouthOpenness > self.config.mouthOpenThreshold)
            case .smile:
                return self.config.smileTriggerBelow ? (currentFrameState.mouthWidth < self.config.smileThreshold) : (currentFrameState.mouthWidth > self.config.smileThreshold)
            case .pucker:
                return self.config.puckerTriggerBelow ? (currentFrameState.mouthPucker < self.config.puckerThreshold) : (currentFrameState.mouthPucker > self.config.puckerThreshold)
            case .mouthLeft:
                return self.config.mouthDirTriggerBelow ? (currentFrameState.mouthLeft < self.config.mouthDirThreshold) : (currentFrameState.mouthLeft > self.config.mouthDirThreshold)
            case .mouthRight:
                return self.config.mouthDirTriggerBelow ? (currentFrameState.mouthRight < self.config.mouthDirThreshold) : (currentFrameState.mouthRight > self.config.mouthDirThreshold)
            case .eyebrowRaise:
                return self.config.eyebrowRaiseTriggerBelow ? (currentFrameState.eyebrowRaise < self.config.eyebrowRaiseThreshold) : (currentFrameState.eyebrowRaise > self.config.eyebrowRaiseThreshold)
            case .squint:
                return self.config.squintTriggerBelow ? (currentFrameState.squint < self.config.squintThreshold) : (currentFrameState.squint > self.config.squintThreshold)
            case .lipsPressed:
                return self.config.lipsPressedTriggerBelow ? (currentFrameState.lipsPressed < self.config.lipsPressedThreshold) : (currentFrameState.lipsPressed > self.config.lipsPressedThreshold)
            }
        }
        
        // Check Combinations
        var comboDetected = false
        
        for combo in config.gestureCombos where combo.isEnabled {
            if isExpressionActive(combo.primary) && isExpressionActive(combo.secondary) {
                activeActions.insert(combo.action)
                suppressIndividualActions = true
                comboDetected = true
                
                // Reset debounce timer since we have a signal
                comboDebounceTimer = 0.15 // Keep alive for 150ms after loss
                lastActiveComboAction = combo.action
                
                print("⚡️ Combo Active: \(combo.primary.rawValue) + \(combo.secondary.rawValue)")
            }
        }
        
        // Debounce Logic: If no combo detected this frame, but we have time left on timer
        if !comboDetected && comboDebounceTimer > 0 {
            comboDebounceTimer -= dt
            if let lastAction = lastActiveComboAction {
                activeActions.insert(lastAction)
                suppressIndividualActions = true
                // print("⏳ Combo Sustained (Debounce)")
            }
        } else if !comboDetected {
            lastActiveComboAction = nil
        }
        
        // Check Individual Expressions (if not suppressed)
        if !suppressIndividualActions {
            // Eye Closed (Wink) with Duration Logic
            if isExpressionActive(.eyeClosed) {
                eyeClosedDuration += dt
            } else {
                eyeClosedDuration = 0
            }
            if eyeClosedDuration >= config.winkHoldDuration {
                activeActions.insert(config.eyeCloseAction)
            }
            
            if isExpressionActive(.mouthOpen) { activeActions.insert(config.mouthOpenAction) }
            if isExpressionActive(.smile) { activeActions.insert(config.smileAction) }
            if isExpressionActive(.pucker) { activeActions.insert(config.puckerAction) }
            if isExpressionActive(.mouthLeft) { activeActions.insert(config.mouthLeftAction) }
            if isExpressionActive(.mouthRight) { activeActions.insert(config.mouthRightAction) }
            if isExpressionActive(.eyebrowRaise) { activeActions.insert(config.eyebrowRaiseAction) }
            if isExpressionActive(.squint) { activeActions.insert(config.squintAction) }
            if isExpressionActive(.lipsPressed) { activeActions.insert(config.lipsPressedAction) }
        } else {
            // Reset wink duration if suppressed to prevent accidental trigger after combo
            eyeClosedDuration = 0
        }
        
        // 4. Execute Actions
        let hasActiveActions = !activeActions.filter({ $0 != .none }).isEmpty
        
        DispatchQueue.main.async {
            self.isPerformingAction = hasActiveActions
        }
        
        for action in FaceAction.allCases {
            if action == .none { continue }
            updateActionState(action: action, shouldBeActive: activeActions.contains(action))
        }
    }
    
    private func updateActionState(action: FaceAction, shouldBeActive: Bool) {
        // Handle Toggle Actions (Clicks)
        if action == .leftClick {
            if shouldBeActive && !isLeftButtonHeld {
                inputController.click(button: .left, down: true)
                isLeftButtonHeld = true
                updateLastAction(action)
                print("Left Mouse DOWN")
            } else if !shouldBeActive && isLeftButtonHeld {
                inputController.click(button: .left, down: false)
                isLeftButtonHeld = false
                print("Left Mouse UP")
            }
            return
        }
        
        if action == .rightClick {
            if shouldBeActive && !isRightButtonHeld {
                inputController.click(button: .right, down: true)
                isRightButtonHeld = true
                updateLastAction(action)
                print("Right Mouse DOWN")
            } else if !shouldBeActive && isRightButtonHeld {
                inputController.click(button: .right, down: false)
                isRightButtonHeld = false
                print("Right Mouse UP")
            }
            return
        }
        
        // Handle Continuous/Discrete Actions
        if shouldBeActive {
            perform(action: action)
        }
    }
    
    private func performStartupCalibration(landmarks: VNFaceLandmarks2D) {
        performCalibration(landmarks: landmarks)
    }
    
    private func performCalibration(landmarks: VNFaceLandmarks2D) {
        // 1. Eye Openness (Raw)
        let leftOpen = ExpressionDetector.getEyeOpenness(eye: landmarks.leftEye, gain: 1.0)
        let rightOpen = ExpressionDetector.getEyeOpenness(eye: landmarks.rightEye, gain: 1.0)
        config.neutralEyeOpenness = (leftOpen + rightOpen) / 2.0
        
        // 2. Mouth Metrics (Raw)
        config.neutralMouthHeight = ExpressionDetector.getRawMouthHeight(innerLips: landmarks.innerLips)
        config.neutralMouthWidth = ExpressionDetector.getRawMouthWidth(outerLips: landmarks.outerLips)
        
        if config.neutralMouthWidth > 0 {
            config.neutralMouthRatio = config.neutralMouthHeight / config.neutralMouthWidth
        } else {
            config.neutralMouthRatio = 0.0
        }
        
        // 3. Mouth Direction (Offset)
        if let outerLips = landmarks.outerLips, let nose = landmarks.nose {
            let lipPoints = outerLips.normalizedPoints
            let nosePoints = nose.normalizedPoints
            
            let noseXs = nosePoints.map { $0.x }
            let lipXs = lipPoints.map { $0.x }
            
            if let noseMin = noseXs.min(), let noseMax = noseXs.max(),
               let lipLeftX = lipXs.min(), let lipRightX = lipXs.max() {
                
                let noseCenterX = (noseMin + noseMax) / 2.0
                let leftDistance = abs(noseCenterX - lipLeftX)
                let rightDistance = abs(lipRightX - noseCenterX)
                
                config.neutralMouthDiff = rightDistance - leftDistance
            }
        }
        
        // 4. Eyebrow Raise
        if let leftBrow = landmarks.leftEyebrow, let rightBrow = landmarks.rightEyebrow,
           let leftEye = landmarks.leftEye, let rightEye = landmarks.rightEye {
            
            let leftBrowY = leftBrow.normalizedPoints.map { $0.y }.reduce(0, +) / CGFloat(leftBrow.pointCount)
            let rightBrowY = rightBrow.normalizedPoints.map { $0.y }.reduce(0, +) / CGFloat(rightBrow.pointCount)
            let avgBrowY = (leftBrowY + rightBrowY) / 2.0
            
            let leftEyeY = leftEye.normalizedPoints.map { $0.y }.reduce(0, +) / CGFloat(leftEye.pointCount)
            let rightEyeY = rightEye.normalizedPoints.map { $0.y }.reduce(0, +) / CGFloat(rightEye.pointCount)
            let avgEyeY = (leftEyeY + rightEyeY) / 2.0
            
            config.neutralBrowRaise = Double(avgBrowY - avgEyeY)
        }
        
        // 5. Squint
        if let leftBrow = landmarks.leftEyebrow, let rightBrow = landmarks.rightEyebrow {
            let leftBrowPoints = leftBrow.normalizedPoints
            let rightBrowPoints = rightBrow.normalizedPoints
            
            let leftBrowInner = leftBrowPoints.max(by: { $0.x < $1.x }) ?? CGPoint.zero
            let rightBrowInner = rightBrowPoints.min(by: { $0.x < $1.x }) ?? CGPoint.zero
            
            config.neutralSquint = Double(rightBrowInner.x - leftBrowInner.x)
        }
        
        print("✅ Calibration Complete: Eye=\(config.neutralEyeOpenness), MouthH=\(config.neutralMouthHeight), MouthW=\(config.neutralMouthWidth)")
        
        updateActiveProfile(with: config)
    }
    
    private func updateLastAction(_ action: FaceAction) {
        DispatchQueue.main.async {
            self.lastTriggeredAction = "\(action.rawValue)!"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if self.lastTriggeredAction == "\(action.rawValue)!" {
                    self.lastTriggeredAction = nil
                }
            }
        }
    }
    
    private func perform(action: FaceAction) {
        // Continuous Actions
        switch action {
        case .scrollDown:
            inputController.scroll(x: 0, y: -5)
            return
        case .scrollUp:
            inputController.scroll(x: 0, y: 5)
            return
        case .moveLeft:
            inputController.moveMouseRelative(dx: -10, dy: 0)
            return
        case .moveRight:
            inputController.moveMouseRelative(dx: 10, dy: 0)
            return
        case .moveUp:
            inputController.moveMouseRelative(dx: 0, dy: -10)
            return
        case .moveDown:
            inputController.moveMouseRelative(dx: 0, dy: 10)
            return
        default:
            break
        }
        
        // Discrete Actions - Check Cooldown
        let now = Date()
        if let lastTime = lastActionTime[action], now.timeIntervalSince(lastTime) < 0.5 {
            return // Cooldown active
        }
        
        switch action {
        case .enter:
            inputController.pressKey(keyCode: 36)
        case .escape:
            inputController.pressKey(keyCode: 53)
        case .space:
            inputController.pressKey(keyCode: 49)
        case .arrowLeft:
            inputController.pressKey(keyCode: 123)
        case .arrowRight:
            inputController.pressKey(keyCode: 124)
        case .arrowDown:
            inputController.pressKey(keyCode: 125)
        case .arrowUp:
            inputController.pressKey(keyCode: 126)
        case .copy:
            inputController.pressKey(keyCode: 8, modifiers: .maskCommand)
        case .paste:
            inputController.pressKey(keyCode: 9, modifiers: .maskCommand)
        case .undo:
            inputController.pressKey(keyCode: 6, modifiers: .maskCommand)
        case .leftClick, .rightClick, .none, .scrollUp, .scrollDown, .moveLeft, .moveRight, .moveUp, .moveDown:
            break
        }
        
        lastActionTime[action] = now
        updateLastAction(action)
    }
    
    // MARK: - Profile Management
    
    func selectProfile(profileID: UUID) {
        if let profile = profiles.first(where: { $0.id == profileID }) {
            self.config = profile.config
            self.activeProfileID = profile.id
            print("✅ Profile '\(profile.name)' selected.")
        }
    }

    func updateActiveProfile(with newConfig: ExpressionConfig) {
        guard let activeID = activeProfileID, let index = profiles.firstIndex(where: { $0.id == activeID }) else { return }
        profiles[index].config = newConfig
        saveProfiles()
        print("✅ Active profile updated with new config.")
    }

    func saveProfile(name: String) {
        var newProfile = Profile(name: name, config: self.config)
        if let index = profiles.firstIndex(where: { $0.name.lowercased() == name.lowercased() }) {
            newProfile.id = profiles[index].id
            profiles[index] = newProfile
            print("✅ Profile '\(name)' updated.")
        } else {
            profiles.append(newProfile)
            print("✅ Profile '\(name)' created.")
        }
        activeProfileID = newProfile.id
        saveProfiles()
    }
    
    func deleteProfile(profileID: UUID) {
        profiles.removeAll { $0.id == profileID }
        if activeProfileID == profileID {
            if let firstProfile = profiles.first {
                selectProfile(profileID: firstProfile.id)
            } else {
                let defaultConfig = ExpressionConfig()
                let defaultProfile = Profile(name: "Default", config: defaultConfig)
                profiles.append(defaultProfile)
                selectProfile(profileID: defaultProfile.id)
            }
        }
        saveProfiles()
        print("🗑️ Profile deleted.")
    }

    private func loadProfiles() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: "savedProfiles") {
            if let decoded = try? decoder.decode([Profile].self, from: data) {
                self.profiles = decoded
                print("✅ Profiles loaded.")
            }
        }
        
        if let uuidString = UserDefaults.standard.string(forKey: "activeProfileID") {
            self.activeProfileID = UUID(uuidString: uuidString)
        }
    }

    private func saveProfiles() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(profiles) {
            UserDefaults.standard.set(encoded, forKey: "savedProfiles")
            print("✅ Profiles saved.")
        }
    }

    private func saveActiveProfileID() {
        if let id = activeProfileID {
            UserDefaults.standard.set(id.uuidString, forKey: "activeProfileID")
            print("✅ Active profile ID saved.")
        }
    }
}

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}

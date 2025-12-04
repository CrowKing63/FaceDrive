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
    @Published var isPaused: Bool = false
    
    // Previous state for smoothing
    private var previousState = ExpressionState()
    
    // Debug log throttling
    private var lastDebugLogTime: Date?
    
    // Debounce
    private var lastActionTime: [FaceAction: Date] = [:]
    
    // Eye close duration tracking
    private var eyeCloseStartTime: Date?
    private var isEyeCloseDurationMet: Bool = false
    
    // Mouth open duration tracking
    private var mouthOpenStartTime: Date?
    private var isMouthOpenDurationMet: Bool = false
    
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Load config from UserDefaults
        loadConfig()

        // Save config changes automatically
        $config
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] newConfig in
                self?.saveConfig()
            }
            .store(in: &cancellables)
    }
    
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
        lastFrameTime = now
        
        // Skip processing if paused
        if isPaused {
            return
        }
        
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
        
        let smoothedMouthHeight = alpha * newState.mouthOpenness + config.smoothFactor * previousState.mouthOpenness
        let smoothedEyeClose = alpha * newState.eyeClose + config.smoothFactor * previousState.eyeClose
        
        // Local state for logic
        var currentFrameState = ExpressionState()
        currentFrameState.mouthOpenness = smoothedMouthHeight
        currentFrameState.eyeClose = smoothedEyeClose
        
        // Debug log
        if lastDebugLogTime == nil || now.timeIntervalSince(lastDebugLogTime!) > 1.0 {
            print("👄 Mouth:\(String(format: "%.2f", smoothedMouthHeight)) | 👁️ Close:\(String(format: "%.2f", smoothedEyeClose))")
            lastDebugLogTime = now
        }
        
        DispatchQueue.main.async {
            self.state = currentFrameState
            self.previousState = currentFrameState
        }
        
        // 3. Determine Active Actions
        var activeActions = Set<FaceAction>()
        
        // Helper to check expression status
        let isExpressionActive: (FaceExpression) -> Bool = { [weak self] expression in
            guard let self = self else { return false }
            switch expression {
            case .mouthOpen:
                return self.config.mouthOpenTriggerBelow ? (currentFrameState.mouthOpenness < self.config.mouthOpenThreshold) : (currentFrameState.mouthOpenness > self.config.mouthOpenThreshold)
            case .eyeClose:
                return self.config.eyeCloseTriggerBelow ? (currentFrameState.eyeClose < self.config.eyeCloseThreshold) : (currentFrameState.eyeClose > self.config.eyeCloseThreshold)
            }
        }
        
        // Check Individual Expressions with Duration Tracking
        
        // Mouth Open with Duration Check
        let mouthOpenActive = isExpressionActive(.mouthOpen)
        if mouthOpenActive {
            if mouthOpenStartTime == nil {
                mouthOpenStartTime = now
                isMouthOpenDurationMet = false
            } else if let startTime = mouthOpenStartTime {
                let duration = now.timeIntervalSince(startTime)
                if duration >= config.mouthOpenDuration {
                    isMouthOpenDurationMet = true
                    activeActions.insert(config.mouthOpenAction)
                }
            }
        } else {
            mouthOpenStartTime = nil
            isMouthOpenDurationMet = false
        }
        
        // Eye Close with Duration Check (to prevent triggering on blinks)
        let eyeCloseActive = isExpressionActive(.eyeClose)
        if eyeCloseActive {
            if eyeCloseStartTime == nil {
                // Start tracking eye close duration
                eyeCloseStartTime = now
                isEyeCloseDurationMet = false
            } else if let startTime = eyeCloseStartTime {
                // Check if duration threshold is met
                let duration = now.timeIntervalSince(startTime)
                if duration >= config.eyeCloseDuration {
                    isEyeCloseDurationMet = true
                    activeActions.insert(config.eyeCloseAction)
                }
            }
        } else {
            // Eyes opened, reset tracking
            eyeCloseStartTime = nil
            isEyeCloseDurationMet = false
        }
        
        // 4. Execute Actions
        let hasActiveActions = !activeActions.filter({ $0 != .none }).isEmpty
        
        DispatchQueue.main.async {
            self.isPerformingAction = hasActiveActions
        }
        
        for action in FaceAction.allCases {
            if action == .none { continue }
            if activeActions.contains(action) {
                perform(action: action)
            }
        }
    }
    
    private func performStartupCalibration(landmarks: VNFaceLandmarks2D) {
        performCalibration(landmarks: landmarks)
    }
    
    private func performCalibration(landmarks: VNFaceLandmarks2D) {
        // 1. Mouth Metrics (Raw)
        config.neutralMouthHeight = ExpressionDetector.getRawMouthHeight(innerLips: landmarks.innerLips)
        
        // 2. Eye Openness (for eye close detection)
        if let leftEye = landmarks.leftEye, let rightEye = landmarks.rightEye {
            // Calculate eye aspect ratio for both eyes
            func getEyeAspectRatio(eye: VNFaceLandmarkRegion2D) -> Double {
                let points = eye.normalizedPoints
                guard let minY = points.map({ $0.y }).min(),
                      let maxY = points.map({ $0.y }).max(),
                      let minX = points.map({ $0.x }).min(),
                      let maxX = points.map({ $0.x }).max() else { return 0.25 }
                
                let height = maxY - minY
                let width = maxX - minX
                
                if width <= 0 { return 0.25 }
                return Double(height / width)
            }
            
            let leftEAR = getEyeAspectRatio(eye: leftEye)
            let rightEAR = getEyeAspectRatio(eye: rightEye)
            config.neutralEyeOpenness = (leftEAR + rightEAR) / 2.0
        }
        
        print("✅ Calibration Complete: MouthH=\(config.neutralMouthHeight), EyeOpen=\(config.neutralEyeOpenness)")
        
        saveConfig()
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
    
    private func getExpressionIntensity(action: FaceAction) -> Double {
        // Find which expression triggers this action
        var expression: FaceExpression?
        var threshold: Double = 0.0
        var isBelow: Bool = false
        var currentValue: Double = 0.0
        
        // Check mapping
        if config.mouthOpenAction == action {
            expression = .mouthOpen
            threshold = config.mouthOpenThreshold
            isBelow = config.mouthOpenTriggerBelow
            currentValue = state.mouthOpenness
        } else if config.eyeCloseAction == action {
            expression = .eyeClose
            threshold = config.eyeCloseThreshold
            isBelow = config.eyeCloseTriggerBelow
            currentValue = state.eyeClose
        }
        
        guard expression != nil else { return 1.0 }
        
        // Calculate intensity (0.0 to 1.0) based on how far past threshold we are
        let range: Double = 0.5 // Default range
        var intensity: Double = 0.0
        
        if isBelow {
            let diff = threshold - currentValue
            intensity = diff / (threshold * 0.8) // Normalize
        } else {
            let diff = currentValue - threshold
            intensity = diff / range
        }
        
        return min(max(intensity, 0.1), 1.0) // Clamp between 0.1 and 1.0
    }
    
    private func perform(action: FaceAction) {
        // Continuous Actions
        switch action {
        case .scrollDown:
            let intensity = getExpressionIntensity(action: action)
            let speed = Int32(max(4.0, config.scrollSpeed * intensity))
            inputController.scroll(x: 0, y: -speed)
            updateLastAction(action)
            return
        case .scrollUp:
            let intensity = getExpressionIntensity(action: action)
            let speed = Int32(max(4.0, config.scrollSpeed * intensity))
            inputController.scroll(x: 0, y: speed)
            updateLastAction(action)
            return
        case .none:
            break
        }
    }
    
    // MARK: - Config Persistence
    
    private func loadConfig() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: "expressionConfig") {
            if let decoded = try? decoder.decode(ExpressionConfig.self, from: data) {
                self.config = decoded
                print("✅ Config loaded.")
            }
        }
    }

    private func saveConfig() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(config) {
            UserDefaults.standard.set(encoded, forKey: "expressionConfig")
            print("✅ Config saved.")
        }
    }
}

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}

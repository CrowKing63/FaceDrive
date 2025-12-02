import Foundation

enum FaceAction: String, CaseIterable, Identifiable, Codable {
    case none = "None"
    case leftClick = "Left Click"
    case rightClick = "Right Click"
    case scrollUp = "Scroll Up"
    case scrollDown = "Scroll Down"
    
    // Mouse Movement
    case moveLeft = "Move Left"
    case moveRight = "Move Right"
    case moveUp = "Move Up"
    case moveDown = "Move Down"
    
    // Keys
    case enter = "Enter"
    case escape = "Escape"
    case space = "Space"
    case arrowLeft = "Arrow Left"
    case arrowRight = "Arrow Right"
    case arrowUp = "Arrow Up"
    case arrowDown = "Arrow Down"
    
    // Shortcuts
    case copy = "Copy (Cmd+C)"
    case paste = "Paste (Cmd+V)"
    case undo = "Undo (Cmd+Z)"
    
    var id: String { rawValue }
}

enum FaceExpression: String, CaseIterable, Identifiable, Codable {
    case eyeClosed = "Eye Closed"
    case mouthOpen = "Mouth Open"
    case smile = "Smile"
    case pucker = "Pucker"
    case mouthLeft = "Mouth Left"
    case mouthRight = "Mouth Right"
    case eyebrowRaise = "Eyebrow Raise"
    case squint = "Squint"
    case lipsPressed = "Lips Pressed"
    
    var id: String { rawValue }
}

struct GestureCombo: Identifiable, Codable, Equatable {
    var id = UUID()
    var primary: FaceExpression
    var secondary: FaceExpression
    var action: FaceAction
    var isEnabled: Bool = true
}

struct ExpressionState {
    var leftEyeOpenness: Double = 1.0
    var rightEyeOpenness: Double = 1.0
    var mouthOpenness: Double = 0.0
    var mouthWidth: Double = 0.0
    var mouthPucker: Double = 0.0
    var mouthLeft: Double = 0.0
    var mouthRight: Double = 0.0
    var eyebrowRaise: Double = 0.0
    var squint: Double = 0.0
    var lipsPressed: Double = 0.0 // 입 다물기
}

struct ExpressionConfig: Codable {
    // Actions
    var eyeCloseAction: FaceAction = .none // Consolidated Eye Closed
    
    var mouthOpenAction: FaceAction = .none
    var smileAction: FaceAction = .none
    var puckerAction: FaceAction = .none
    var mouthLeftAction: FaceAction = .none
    var mouthRightAction: FaceAction = .none
    var eyebrowRaiseAction: FaceAction = .none
    var squintAction: FaceAction = .none
    var lipsPressedAction: FaceAction = .none
    
    // Thresholds
    var eyeClosedThreshold: Double = 0.2
    var mouthOpenThreshold: Double = 0.3
    var smileThreshold: Double = 0.6
    var puckerThreshold: Double = 0.3
    var mouthDirThreshold: Double = 0.05
    var eyebrowRaiseThreshold: Double = 0.3
    var squintThreshold: Double = 0.5
    var lipsPressedThreshold: Double = 0.5
    
    // Trigger Direction (true = Below <, false = Above >)
    var eyeClosedTriggerBelow: Bool = true
    var mouthOpenTriggerBelow: Bool = false
    var smileTriggerBelow: Bool = false
    var puckerTriggerBelow: Bool = false
    var mouthDirTriggerBelow: Bool = false
    var eyebrowRaiseTriggerBelow: Bool = false
    var squintTriggerBelow: Bool = false
    var lipsPressedTriggerBelow: Bool = false
    
    // Calibration Offsets (Neutral State)
    var neutralMouthDiff: Double = 0.0
    var neutralBrowRaise: Double = 0.0
    var neutralSquint: Double = 0.0
    
    // New: Zeroing Baselines
    var neutralEyeOpenness: Double = 0.25 // Default raw eye openness
    var neutralMouthHeight: Double = 0.0
    var neutralMouthWidth: Double = 0.0
    var neutralMouthRatio: Double = 0.0
    
    // Wink Configuration
    var winkHoldDuration: Double = 0.2 // Seconds to hold before triggering
    
    // Gain multipliers for sensitivity adjustment
    var eyeGain: Double = 40.0 // Default: 1/0.025 = 40
    var mouthHeightGain: Double = 10.0
    var mouthWidthGain: Double = 5.0
    var eyebrowGain: Double = 30.0 // Lower than others to reduce sensitivity
    
    // Smoothing factor (0.0 = no smoothing, 1.0 = max smoothing)
    var smoothFactor: Double = 0.7
    
    // Gesture Combinations
    var gestureCombos: [GestureCombo] = []
}

struct Profile: Identifiable, Codable {
    var id = UUID()
    var name: String
    var config: ExpressionConfig
}

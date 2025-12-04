import Foundation

enum FaceAction: String, CaseIterable, Identifiable, Codable {
    case none = "None"
    case scrollUp = "Scroll Up"
    case scrollDown = "Scroll Down"
    
    var id: String { rawValue }
}

enum FaceExpression: String, CaseIterable, Identifiable, Codable {
    case mouthOpen = "Mouth Open"
    case eyeClose = "Eye Close"
    
    var id: String { rawValue }
}

struct ExpressionState {
    var mouthOpenness: Double = 0.0
    var eyeClose: Double = 0.0
}

struct ExpressionConfig: Codable {
    // Actions
    var mouthOpenAction: FaceAction = .none
    var eyeCloseAction: FaceAction = .none
    
    // Thresholds
    var mouthOpenThreshold: Double = 0.3
    var eyeCloseThreshold: Double = 0.5
    
    // Duration (seconds) - how long expression must be held
    var mouthOpenDuration: Double = 0.3 // Must hold mouth open for 0.3s to trigger
    var eyeCloseDuration: Double = 0.3 // Must hold eyes closed for 0.3s to trigger
    
    // Trigger Direction (true = Below < , false = Above > )
    var mouthOpenTriggerBelow: Bool = false
    var eyeCloseTriggerBelow: Bool = false
    
    // Calibration Offsets (Neutral State)
    var neutralMouthHeight: Double = 0.0
    var neutralEyeOpenness: Double = 0.0
    
    // Gain multipliers for sensitivity adjustment
    var mouthHeightGain: Double = 10.0
    var eyeGain: Double = 30.0
    
    // Smoothing factor (0.0 = no smoothing, 1.0 = max smoothing)
    var smoothFactor: Double = 0.5
    
    // Scroll Settings
    var scrollSpeed: Double = 20.0
}

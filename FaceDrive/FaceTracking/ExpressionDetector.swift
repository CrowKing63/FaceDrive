import Vision
import Foundation

struct ExpressionDetector {
    
    // MARK: - Public Methods
    
    static func calculate(landmarks: VNFaceLandmarks2D, config: ExpressionConfig) -> ExpressionState {
        var state = ExpressionState()
        
        // 1. Mouth Metrics (Relative to Neutral)
        let rawMouthHeight = getRawMouthHeight(innerLips: landmarks.innerLips)
        
        // Mouth Open: (Raw - Neutral) * Gain
        state.mouthOpenness = min(max(0.0, (rawMouthHeight - config.neutralMouthHeight) * config.mouthHeightGain), 1.0)
        
        // 2. Eye Close Detection
        state.eyeClose = getEyeClose(
            leftEye: landmarks.leftEye,
            rightEye: landmarks.rightEye,
            gain: config.eyeGain,
            neutralOpenness: config.neutralEyeOpenness
        )
        
        return state
    }
    
    // MARK: - Internal Helpers
    
    static func getRawMouthHeight(innerLips: VNFaceLandmarkRegion2D?) -> Double {
        guard let region = innerLips else { return 0 }
        let points = region.normalizedPoints
        guard let minY = points.map({ $0.y }).min(),
              let maxY = points.map({ $0.y }).max() else { return 0 }
        return Double(maxY - minY)
    }
    
    private static func getEyeClose(leftEye: VNFaceLandmarkRegion2D?, rightEye: VNFaceLandmarkRegion2D?, gain: Double, neutralOpenness: Double) -> Double {
        // Calculate eye aspect ratio (EAR) for both eyes
        // When eyes are open, EAR is higher; when closed, EAR approaches 0
        
        func getEyeAspectRatio(eye: VNFaceLandmarkRegion2D?) -> Double? {
            guard let eye = eye else { return nil }
            let points = eye.normalizedPoints
            guard points.count >= 6 else { return nil }
            
            // Find eye bounds
            guard let minY = points.map({ $0.y }).min(),
                  let maxY = points.map({ $0.y }).max(),
                  let minX = points.map({ $0.x }).min(),
                  let maxX = points.map({ $0.x }).max() else { return nil }
            
            let height = maxY - minY
            let width = maxX - minX
            
            if width <= 0 { return 0 }
            
            // Eye Aspect Ratio: height / width
            // Open eyes have higher ratio, closed eyes have lower ratio
            return Double(height / width)
        }
        
        let leftEAR = getEyeAspectRatio(eye: leftEye)
        let rightEAR = getEyeAspectRatio(eye: rightEye)
        
        var avgEAR: Double
        if let l = leftEAR, let r = rightEAR {
            avgEAR = (l + r) / 2.0
        } else if let l = leftEAR {
            avgEAR = l
        } else if let r = rightEAR {
            avgEAR = r
        } else {
            return 0
        }
        
        // Use calibrated neutral or default (typical open eye ratio is around 0.2-0.3)
        let neutral = (neutralOpenness != 0) ? neutralOpenness : 0.25
        
        // Eye closing: neutral - current (when eyes close, EAR decreases)
        let closeDiff = neutral - avgEAR
        let eyeCloseVal = max(0, closeDiff * gain)
        
        return min(eyeCloseVal, 1.0)
    }
}


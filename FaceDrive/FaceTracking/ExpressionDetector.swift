import Vision
import Foundation

struct ExpressionDetector {
    
    // MARK: - Public Methods
    
    static func calculate(landmarks: VNFaceLandmarks2D, config: ExpressionConfig) -> ExpressionState {
        var state = ExpressionState()
        
        // 1. Eye Openness (Relative to Neutral)
    // Neutral = 1.0 (Fully Open). Closing reduces it.
    // We want "Eye Closed" metric: 0.0 (Open) -> 1.0 (Closed)
    // But existing logic expects "Openness": 1.0 (Open) -> 0.0 (Closed)
    // Let's keep "Openness" but normalize it so Neutral maps to ~0.8-1.0 range?
    // Actually, user wants "Zeroing".
    // If Neutral Eye Openness is 0.2 (raw), then 0.2 should be mapped to 1.0 (Open).
    // If it drops to 0.1, that's 0.5 Open.
    // Formula: value = raw / neutral.
    
    let rawLeftOpen = getEyeOpenness(eye: landmarks.leftEye, gain: 1.0) // Raw gain 1.0
    let rawRightOpen = getEyeOpenness(eye: landmarks.rightEye, gain: 1.0)
    
    // Avoid division by zero
    let neutralEye = max(config.neutralEyeOpenness, 0.01)
    
    // Normalized Openness: 1.0 at neutral, decreases as you close.
    // We apply gain to the *drop*? Or just scale the ratio?
    // Let's just scale the ratio.
    state.leftEyeOpenness = min(rawLeftOpen / neutralEye, 1.0)
    state.rightEyeOpenness = min(rawRightOpen / neutralEye, 1.0)
    
    // 2. Mouth Metrics (Relative to Neutral)
    let rawMouthHeight = getRawMouthHeight(innerLips: landmarks.innerLips)
    let rawMouthWidth = getRawMouthWidth(outerLips: landmarks.outerLips)
    
    // Mouth Open: (Raw - Neutral) * Gain
    state.mouthOpenness = min(max(0.0, (rawMouthHeight - config.neutralMouthHeight) * config.mouthHeightGain), 1.0)
    
    // Smile (Width): (Raw - Neutral) * Gain
    state.mouthWidth = min(max(0.0, (rawMouthWidth - config.neutralMouthWidth) * config.mouthWidthGain), 1.0)
    
    // Pucker: Ratio of Height / Width using RAW values
    if rawMouthWidth > 0 {
        let ratio = rawMouthHeight / rawMouthWidth
        // Relative Pucker: (Ratio - NeutralRatio) * Gain
        // We might need a higher gain for pucker since ratio changes are small?
        // Let's use a fixed multiplier for now or reuse mouthWidthGain?
        // Let's use a hardcoded sensitivity multiplier for pucker relative to ratio.
        state.mouthPucker = min(max(0.0, (ratio - config.neutralMouthRatio) * 2.0), 1.0)
    }
        
        // Mouth Direction (Left/Right)
        let (left, right) = getMouthDirection(
            outerLips: landmarks.outerLips,
            nose: landmarks.nose,
            offset: config.neutralMouthDiff
        )
        state.mouthLeft = left
        state.mouthRight = right
        
        // 3. Eyebrow Metrics
        state.eyebrowRaise = getEyebrowRaise(
            leftBrow: landmarks.leftEyebrow,
            rightBrow: landmarks.rightEyebrow,
            leftEye: landmarks.leftEye,
            rightEye: landmarks.rightEye,
            gain: config.eyebrowGain,
            offset: config.neutralBrowRaise
        )
        
        state.squint = getSquint(
            leftBrow: landmarks.leftEyebrow,
            rightBrow: landmarks.rightEyebrow,
            gain: config.eyebrowGain,
            offset: config.neutralSquint
        )
        
        // 4. Lips Pressed
        // Increase reference to 0.05 to make it easier to trigger
        state.lipsPressed = max(0.0, 1.0 - (rawMouthHeight / 0.05))
        
        return state
    }
    
    // MARK: - Internal Helpers
    
    static func getEyeOpenness(eye: VNFaceLandmarkRegion2D?, gain: Double) -> Double {
        guard let eye = eye else { return 1.0 }
        let points = eye.normalizedPoints
        guard let minY = points.map({ $0.y }).min(),
              let maxY = points.map({ $0.y }).max() else { return 1.0 }
        
        let height = Double(maxY - minY)
        // Default gain is around 40.0. 0.025 * 40 = 1.0
        return min(max(height * gain, 0.0), 1.0)
    }
    
    static func getRawMouthHeight(innerLips: VNFaceLandmarkRegion2D?) -> Double {
        guard let region = innerLips else { return 0 }
        let points = region.normalizedPoints
        guard let minY = points.map({ $0.y }).min(),
              let maxY = points.map({ $0.y }).max() else { return 0 }
        return Double(maxY - minY)
    }
    
    static func getRawMouthWidth(outerLips: VNFaceLandmarkRegion2D?) -> Double {
        guard let region = outerLips else { return 0 }
        let points = region.normalizedPoints
        guard let minX = points.map({ $0.x }).min(),
              let maxX = points.map({ $0.x }).max() else { return 0 }
        return Double(maxX - minX)
    }
    
    private static func getMouthHeight(innerLips: VNFaceLandmarkRegion2D?, gain: Double) -> Double {
        let raw = getRawMouthHeight(innerLips: innerLips)
        return min(raw * gain, 1.0) // Cap at 1.0
    }
    
    private static func getMouthWidth(outerLips: VNFaceLandmarkRegion2D?, gain: Double) -> Double {
        let raw = getRawMouthWidth(outerLips: outerLips)
        return min(raw * gain, 1.0)
    }
    
    private static func getMouthDirection(outerLips: VNFaceLandmarkRegion2D?, nose: VNFaceLandmarkRegion2D?, offset: Double) -> (Double, Double) {
        guard let outerLips = outerLips, let nose = nose else { return (0, 0) }
        
        let lipPoints = outerLips.normalizedPoints
        let nosePoints = nose.normalizedPoints
        
        // Get nose center X
        let noseXs = nosePoints.map { $0.x }
        guard let noseMin = noseXs.min(), let noseMax = noseXs.max() else { return (0, 0) }
        let noseCenterX = (noseMin + noseMax) / 2.0
        
        // Get lip leftmost and rightmost X
        let lipXs = lipPoints.map { $0.x }
        guard let lipLeftX = lipXs.min(), let lipRightX = lipXs.max() else { return (0, 0) }
        
        // Distance from nose center to each lip corner
        let leftDistance = abs(noseCenterX - lipLeftX)
        let rightDistance = abs(lipRightX - noseCenterX)
        
        // Apply offset (Calibration)
        // Diff = Right - Left
        // If neutral face has Right > Left (Diff > 0), we subtract that offset.
        let diff = (rightDistance - leftDistance) - offset
        
        // Sensitivity
        let sensitivity = 20.0
        let deadzone = 0.01
        
        // SWAPPED LOGIC based on user feedback
        // Previous: Diff > 0 => Right (User said this was wrong)
        // New: Diff > 0 => Left
        //      Diff < 0 => Right
        
        if diff > deadzone { // RightDist > LeftDist => Mouth Moved LEFT
             return (min((diff - deadzone) * sensitivity, 1.0), 0.0)
        } else if diff < -deadzone { // LeftDist > RightDist => Mouth Moved RIGHT
            return (0.0, min((-diff - deadzone) * sensitivity, 1.0))
        }
        
        return (0, 0)
    }
    
    private static func getEyebrowRaise(leftBrow: VNFaceLandmarkRegion2D?, rightBrow: VNFaceLandmarkRegion2D?, leftEye: VNFaceLandmarkRegion2D?, rightEye: VNFaceLandmarkRegion2D?, gain: Double, offset: Double) -> Double {
        guard let leftBrow = leftBrow, let rightBrow = rightBrow,
              let leftEye = leftEye, let rightEye = rightEye else { return 0 }
        
        // Average Y of brows
        let leftBrowY = leftBrow.normalizedPoints.map { $0.y }.reduce(0, +) / CGFloat(leftBrow.pointCount)
        let rightBrowY = rightBrow.normalizedPoints.map { $0.y }.reduce(0, +) / CGFloat(rightBrow.pointCount)
        let avgBrowY = (leftBrowY + rightBrowY) / 2.0
        
        // Average Y of eyes
        let leftEyeY = leftEye.normalizedPoints.map { $0.y }.reduce(0, +) / CGFloat(leftEye.pointCount)
        let rightEyeY = rightEye.normalizedPoints.map { $0.y }.reduce(0, +) / CGFloat(rightEye.pointCount)
        let avgEyeY = (leftEyeY + rightEyeY) / 2.0
        
        // Distance
        let distance = Double(avgBrowY - avgEyeY)
        
        // Apply offset
        // If neutral distance is 0.05, and offset is 0.05.
        // Current distance 0.05 -> 0.0.
        // Raised distance 0.08 -> 0.03.
        
        // We use a base offset of 0.04 in addition to calibration?
        // Let's rely on calibration primarily if available.
        // But if offset is 0 (uncalibrated), we need a default.
        // Let's assume offset INCLUDES the base distance.
        // If uncalibrated (offset=0), we use default 0.04.
        
        let effectiveOffset = (offset != 0) ? offset : 0.04
        let value = max(0, distance - effectiveOffset)
        
        return min(value * gain, 1.0)
    }
    
    private static func getSquint(leftBrow: VNFaceLandmarkRegion2D?, rightBrow: VNFaceLandmarkRegion2D?, gain: Double, offset: Double) -> Double {
        guard let leftBrow = leftBrow, let rightBrow = rightBrow else { return 0 }
        
        let leftBrowPoints = leftBrow.normalizedPoints
        let rightBrowPoints = rightBrow.normalizedPoints
        
        // Inner points
        let leftBrowInner = leftBrowPoints.max(by: { $0.x < $1.x }) ?? CGPoint.zero
        let rightBrowInner = rightBrowPoints.min(by: { $0.x < $1.x }) ?? CGPoint.zero
        
        let distance = Double(rightBrowInner.x - leftBrowInner.x)
        
        // Squinting reduces distance.
        // Value = Base - Current.
        // If calibrated, offset is the Neutral Distance.
        // Value = Offset - Current.
        
        let effectiveBase = (offset != 0) ? offset : 0.15
        let value = max(0, effectiveBase - distance)
        
        return min(value * gain, 1.0)
    }
}


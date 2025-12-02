import SwiftUI
import Vision

struct FaceLandmarksOverlay: View {
    let observation: VNFaceObservation?
    
    var body: some View {
        GeometryReader { geometry in
            if let observation = observation, let landmarks = observation.landmarks {
                Path { path in
                    // Draw Face Contour
                    if let contour = landmarks.faceContour {
                        draw(region: contour, into: &path, geometry: geometry)
                    }
                    
                    // Draw Eyes
                    if let leftEye = landmarks.leftEye {
                        draw(region: leftEye, into: &path, geometry: geometry, close: true)
                    }
                    if let rightEye = landmarks.rightEye {
                        draw(region: rightEye, into: &path, geometry: geometry, close: true)
                    }
                    
                    // Draw Lips
                    if let outerLips = landmarks.outerLips {
                        draw(region: outerLips, into: &path, geometry: geometry, close: true)
                    }
                    if let innerLips = landmarks.innerLips {
                        draw(region: innerLips, into: &path, geometry: geometry, close: true)
                    }
                    
                    // Draw Nose
                    if let nose = landmarks.nose {
                        draw(region: nose, into: &path, geometry: geometry)
                    }
                    if let noseCrest = landmarks.noseCrest {
                        draw(region: noseCrest, into: &path, geometry: geometry)
                    }
                    
                    // Draw Eyebrows
                    if let leftEyebrow = landmarks.leftEyebrow {
                        draw(region: leftEyebrow, into: &path, geometry: geometry)
                    }
                    if let rightEyebrow = landmarks.rightEyebrow {
                        draw(region: rightEyebrow, into: &path, geometry: geometry)
                    }
                }
                .stroke(Color.green, lineWidth: 2)
                
                // Draw Bounding Box (Debug)
                Path { path in
                    let rect = observation.boundingBox
                    let convertedRect = CGRect(
                        x: rect.minX * geometry.size.width,
                        y: (1 - rect.maxY) * geometry.size.height,
                        width: rect.width * geometry.size.width,
                        height: rect.height * geometry.size.height
                    )
                    path.addRect(convertedRect)
                }
                .stroke(Color.red, lineWidth: 1)
            }
        }
    }
    
    private func draw(region: VNFaceLandmarkRegion2D, into path: inout Path, geometry: GeometryProxy, close: Bool = false) {
        let points = region.normalizedPoints
        guard let first = points.first else { return }
        
        // Vision coordinates: (0,0) is bottom-left. SwiftUI: (0,0) is top-left.
        // Also, the points are relative to the bounding box of the face, NOT the whole image.
        // Wait, VNFaceLandmarkRegion2D.normalizedPoints are normalized to the bounding box of the face.
        // To draw them correctly on the full image, we need to transform them.
        // Actually, it's easier to draw them relative to the bounding box if we place this view inside the bounding box,
        // BUT the bounding box itself moves.
        // A better approach for a simple overlay is to map everything to the global view coordinates.
        
        // Let's re-calculate:
        // Point in Image = BoundingBox.Origin + (PointInBBox * BoundingBox.Size)
        // Then flip Y.
        
        guard let observation = observation else { return }
        let bbox = observation.boundingBox
        
        let startPoint = convert(point: first, bbox: bbox, geometry: geometry)
        path.move(to: startPoint)
        
        for i in 1..<points.count {
            let point = convert(point: points[i], bbox: bbox, geometry: geometry)
            path.addLine(to: point)
        }
        
        if close {
            path.closeSubpath()
        }
    }
    
    private func convert(point: CGPoint, bbox: CGRect, geometry: GeometryProxy) -> CGPoint {
        // point is normalized (0-1) within the bbox
        // bbox is normalized (0-1) within the image
        
        let x = bbox.origin.x + point.x * bbox.width
        let y = bbox.origin.y + point.y * bbox.height
        
        // Now (x,y) is normalized in image coordinates (0,0 bottom-left)
        // Convert to SwiftUI coordinates (0,0 top-left)
        
        let finalX = x * geometry.size.width
        let finalY = (1 - y) * geometry.size.height
        
        return CGPoint(x: finalX, y: finalY)
    }
}

import Vision
import AVFoundation
import Combine

class FaceDetector: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var faceObservation: VNFaceObservation?
    
    private var requests = [VNRequest]()
    
    override init() {
        super.init()
        setupVision()
    }
    
    func setupVision() {
        let faceLandmarksRequest = VNDetectFaceLandmarksRequest { [weak self] request, error in
            if let error = error {
                print("Vision Error: \(error.localizedDescription)")
                return
            }
            guard let observations = request.results as? [VNFaceObservation],
                  let face = observations.first else {
                DispatchQueue.main.async {
                    self?.faceObservation = nil
                }
                return
            }
            
            DispatchQueue.main.async {
                self?.faceObservation = face
            }
        }
        
        // Use Revision 3 for more points if available (macOS 14+)
        if #available(macOS 14.0, *) {
            faceLandmarksRequest.revision = VNDetectFaceLandmarksRequestRevision3
        }
        
        self.requests = [faceLandmarksRequest]
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print("Failed to perform Vision request: \(error)")
        }
    }
}

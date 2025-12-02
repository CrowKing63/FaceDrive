import AVFoundation
import Combine

class CameraManager: NSObject, ObservableObject {
    @Published var error: Error?
    
    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.facedrive.camera.sessionQueue")
    
    weak var delegate: AVCaptureVideoDataOutputSampleBufferDelegate?
    
    override init() {
        super.init()
        setupSession()
    }
    
    func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .high
            
            // Add Video Input
            do {
                guard let device = AVCaptureDevice.default(for: .video) else {
                    throw CameraError.noCamera
                }
                let input = try AVCaptureDeviceInput(device: device)
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                } else {
                    throw CameraError.cannotAddInput
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error
                }
                self.session.commitConfiguration()
                return
            }
            
            // Add Video Output
            if self.session.canAddOutput(self.videoOutput) {
                self.session.addOutput(self.videoOutput)
                self.videoOutput.alwaysDiscardsLateVideoFrames = true
                self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
                // Note: Delegate will be set by the owner (FaceDetector) or we can set it here if we pass a closure
            } else {
                DispatchQueue.main.async {
                    self.error = CameraError.cannotAddOutput
                }
            }
            
            self.session.commitConfiguration()
        }
    }
    
    func setDelegate(_ delegate: AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue) {
        sessionQueue.async {
            self.videoOutput.setSampleBufferDelegate(delegate, queue: queue)
        }
    }
    
    func start() {
        sessionQueue.async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    func stop() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
}

enum CameraError: Error {
    case noCamera
    case cannotAddInput
    case cannotAddOutput
}

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var cameraManager: CameraManager
    @EnvironmentObject var faceDetector: FaceDetector
    @EnvironmentObject var actionMapper: ActionMapper
    @State private var showPermissionAlert = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Camera Feed (Left)
            ZStack {
                GeometryReader { geo in
                    ZStack {
                        CameraPreview(session: cameraManager.session)
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                        
                        if let observation = faceDetector.faceObservation {
                            FaceLandmarksOverlay(observation: observation)
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                        } else {
                            Text("No Face")
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding(8)
                                .background(.black.opacity(0.7))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .frame(width: 200) // Fixed width for camera
            .background(Color.black)
            
            // Dashboard (Right)
            DashboardView(mapper: actionMapper)
        }
        .onAppear {
            if !InputController().checkAccessibility() {
                showPermissionAlert = true
            }
        }
        .alert("Accessibility Permission Needed", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                NSWorkspace.shared.open(url)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("FaceDrive needs Accessibility permissions to control your mouse and keyboard. Please grant access in System Settings.")
        }
    }
}

#Preview {
    let services = AppServices.shared
    ContentView()
        .environmentObject(services.cameraManager)
        .environmentObject(services.faceDetector)
        .environmentObject(services.actionMapper)
}

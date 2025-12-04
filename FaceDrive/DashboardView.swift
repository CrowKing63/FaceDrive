import SwiftUI

struct DashboardView: View {
    @ObservedObject var mapper: ActionMapper
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("MagicScroll")
                    .font(.headline)
                Spacer()
                if let last = mapper.lastTriggeredAction {
                    Text(last)
                        .font(.caption)
                        .foregroundStyle(.green)
                        .transition(.opacity)
                }
            }
            .padding([.horizontal, .top])
            
            Divider()
            
            // Calibrate Button
            Button(action: {
                mapper.calibrate()
            }) {
                HStack {
                    Image(systemName: "face.dashed")
                    Text("Calibrate Face (Neutral)")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            
            Divider()
            
            // Gain Controls
            VStack(alignment: .leading, spacing: 8) {
                Text("Sensitivity")
                    .font(.headline)
                
                HStack {
                    Text("Mouth:")
                        .frame(width: 60, alignment: .leading)
                    Slider(value: $mapper.config.mouthHeightGain, in: 0.5...30.0)
                }
                
                HStack {
                    Text("Eye:")
                        .frame(width: 60, alignment: .leading)
                    Slider(value: $mapper.config.eyeGain, in: 1.0...50.0)
                }
                
                HStack {
                    Text("Smooth:")
                        .frame(width: 60, alignment: .leading)
                    Slider(value: $mapper.config.smoothFactor, in: 0.0...0.95)
                }
                
                HStack {
                    Text("Scroll:")
                        .frame(width: 60, alignment: .leading)
                    Slider(value: $mapper.config.scrollSpeed, in: 1.0...100.0)
                }
            }
            .font(.caption)
            .padding(.horizontal)
            
            Divider()
            
            // Expression Controls
            ScrollView {
                VStack(spacing: 12) {
                    // Mouth Open
                    ExpressionRow(
                        label: "Mouth Open",
                        value: mapper.state.mouthOpenness,
                        threshold: $mapper.config.mouthOpenThreshold,
                        action: $mapper.config.mouthOpenAction,
                        triggerBelow: $mapper.config.mouthOpenTriggerBelow,
                        isActive: mapper.lastTriggeredAction?.starts(with: mapper.config.mouthOpenAction.rawValue) ?? false
                    )
                    
                    // Mouth Open Duration Control
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text("Duration")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.2fs", mapper.config.mouthOpenDuration))
                                .font(.caption)
                                .monospacedDigit()
                        }
                        Slider(value: $mapper.config.mouthOpenDuration, in: 0.1...2.0, step: 0.1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(8)
                    
                    // Eye Close
                    ExpressionRow(
                        label: "Eye Close",
                        value: mapper.state.eyeClose,
                        threshold: $mapper.config.eyeCloseThreshold,
                        action: $mapper.config.eyeCloseAction,
                        triggerBelow: $mapper.config.eyeCloseTriggerBelow,
                        isActive: mapper.lastTriggeredAction?.starts(with: mapper.config.eyeCloseAction.rawValue) ?? false
                    )
                    
                    // Eye Close Duration Control
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text("Duration (prevent blinks)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.2fs", mapper.config.eyeCloseDuration))
                                .font(.caption)
                                .monospacedDigit()
                        }
                        Slider(value: $mapper.config.eyeCloseDuration, in: 0.1...2.0, step: 0.1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(8)
                }
                .padding()
            }
        }
        .frame(minWidth: 400)
        .background(Material.ultraThinMaterial)
        .overlay(
            Group {
                if !mapper.isStartupCalibrated {
                    ZStack {
                        Color.black.opacity(0.8)
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            Text("Calibrating...")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("Please look at the screen with a neutral expression.")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                }
            }
        )
    }
}

struct ExpressionRow: View {
    let label: String
    let value: Double
    @Binding var threshold: Double
    @Binding var action: FaceAction
    @Binding var triggerBelow: Bool
    var isActive: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(width: 100, alignment: .leading)
                
                Spacer()
                
                // Trigger Direction Toggle
                Button(action: {
                    triggerBelow.toggle()
                }) {
                    Text(triggerBelow ? "< (Less)" : "> (More)")
                        .font(.caption)
                        .frame(width: 60)
                }
                .buttonStyle(.bordered)
                
                Picker("", selection: $action) {
                    ForEach(FaceAction.allCases) { action in
                        Text(action.rawValue).tag(action)
                    }
                }
                .frame(width: 120)
                .labelsHidden()
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 10)
                        .cornerRadius(5)
                    
                    // Value Bar
                    Rectangle()
                        .fill(isActive ? Color.green : Color.blue)
                        .frame(width: min(CGFloat(max(value, 0.0)) * geo.size.width, geo.size.width), height: 10)
                        .cornerRadius(5)
                        .animation(.linear(duration: 0.1), value: value)
                    
                    // Threshold Marker
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 2, height: 14)
                        .offset(x: CGFloat(threshold) * geo.size.width)
                }
            }
            .frame(height: 14)
            
            HStack {
                Text("Sens:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Slider(value: $threshold, in: 0.0...1.0)
                Text(String(format: "%.3f", threshold))
                    .font(.caption)
                    .monospacedDigit()
                    .frame(width: 40)
                
                Button("Set") {
                    threshold = value
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 5)
        .background(Color.black.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal, 5)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isActive ? Color.green : Color.clear, lineWidth: 2)
        )
    }
}

import SwiftUI

struct DashboardView: View {
    @ObservedObject var mapper: ActionMapper
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Expression Dashboard")
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
            
            ProfileManagementView(mapper: mapper)

            Divider()
            
            // Gain Controls
            VStack(alignment: .leading, spacing: 10) {
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
                .padding(.vertical, 5)
                
                Divider()
                
                Text("Sensitivity Gain")
                    .font(.headline)
                    .padding(.top, 5)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 10)], spacing: 10) {
                    HStack {
                        Text("Eye:")
                            .frame(width: 50, alignment: .leading)
                        Slider(value: Binding(
                            get: { 1.0 - ((mapper.config.eyeGain - 10.0) / 90.0) },
                            set: { mapper.config.eyeGain = 10.0 + ((1.0 - $0) * 90.0) }
                        ), in: 0.0...1.0)
                    }
                    
                    HStack {
                        Text("Mouth H:")
                            .frame(width: 60, alignment: .leading)
                        Slider(value: $mapper.config.mouthHeightGain, in: 0.5...3.0)
                    }
                    
                    HStack {
                        Text("Mouth W:")
                            .frame(width: 60, alignment: .leading)
                        Slider(value: $mapper.config.mouthWidthGain, in: 0.5...3.0)
                    }
                    
                    HStack {
                        Text("Eyebrow:")
                            .frame(width: 60, alignment: .leading)
                        Slider(value: $mapper.config.eyebrowGain, in: 1.0...10.0)
                    }
                    
                    HStack {
                        Text("Smooth:")
                            .frame(width: 55, alignment: .leading)
                        Slider(value: $mapper.config.smoothFactor, in: 0.0...0.95)
                    }
                    
                    HStack {
                        Text("Wink:")
                            .frame(width: 40, alignment: .leading)
                        Slider(value: $mapper.config.winkHoldDuration, in: 0.0...1.0)
                    }
                }
                .font(.caption)
            }
            .padding()
            
            Divider()
            
            TabView {
                // Expression Rows
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 15)], spacing: 15) {
                        // Eye Closed (Consolidated)
                        ExpressionRow(
                            label: "Eye Closed",
                            value: min(mapper.state.leftEyeOpenness, mapper.state.rightEyeOpenness),
                            threshold: $mapper.config.eyeClosedThreshold,
                            action: $mapper.config.eyeCloseAction,
                            triggerBelow: $mapper.config.eyeClosedTriggerBelow,
                            isActive: mapper.lastTriggeredAction?.starts(with: mapper.config.eyeCloseAction.rawValue) ?? false
                        )
                        
                        // Mouth Open
                        ExpressionRow(
                            label: "Mouth Open",
                            value: mapper.state.mouthOpenness,
                            threshold: $mapper.config.mouthOpenThreshold,
                            action: $mapper.config.mouthOpenAction,
                            triggerBelow: $mapper.config.mouthOpenTriggerBelow,
                            isActive: mapper.lastTriggeredAction?.starts(with: mapper.config.mouthOpenAction.rawValue) ?? false
                        )
                        
                        // Smile
                        ExpressionRow(
                            label: "Smile",
                            value: mapper.state.mouthWidth,
                            threshold: $mapper.config.smileThreshold,
                            action: $mapper.config.smileAction,
                            triggerBelow: $mapper.config.smileTriggerBelow,
                            isActive: mapper.lastTriggeredAction?.starts(with: mapper.config.smileAction.rawValue) ?? false
                        )
                        
                        // Pucker
                        ExpressionRow(
                            label: "Pucker",
                            value: mapper.state.mouthPucker,
                            threshold: $mapper.config.puckerThreshold,
                            action: $mapper.config.puckerAction,
                            triggerBelow: $mapper.config.puckerTriggerBelow,
                            isActive: mapper.lastTriggeredAction?.starts(with: mapper.config.puckerAction.rawValue) ?? false
                        )
                        
                        // Mouth Left
                        ExpressionRow(
                            label: "Mouth Left",
                            value: mapper.state.mouthLeft,
                            threshold: $mapper.config.mouthDirThreshold,
                            action: $mapper.config.mouthLeftAction,
                            triggerBelow: $mapper.config.mouthDirTriggerBelow,
                            isActive: mapper.lastTriggeredAction?.starts(with: mapper.config.mouthLeftAction.rawValue) ?? false
                        )
                        
                        // Mouth Right
                        ExpressionRow(
                            label: "Mouth Right",
                            value: mapper.state.mouthRight,
                            threshold: $mapper.config.mouthDirThreshold,
                            action: $mapper.config.mouthRightAction,
                            triggerBelow: $mapper.config.mouthDirTriggerBelow,
                            isActive: mapper.lastTriggeredAction?.starts(with: mapper.config.mouthRightAction.rawValue) ?? false
                        )
                        
                        // Eyebrow Raise
                        ExpressionRow(
                            label: "Eyebrow Raise",
                            value: mapper.state.eyebrowRaise,
                            threshold: $mapper.config.eyebrowRaiseThreshold,
                            action: $mapper.config.eyebrowRaiseAction,
                            triggerBelow: $mapper.config.eyebrowRaiseTriggerBelow,
                            isActive: mapper.lastTriggeredAction?.starts(with: mapper.config.eyebrowRaiseAction.rawValue) ?? false
                        )
                        
                        // Squint
                        ExpressionRow(
                            label: "Squint",
                            value: mapper.state.squint,
                            threshold: $mapper.config.squintThreshold,
                            action: $mapper.config.squintAction,
                            triggerBelow: $mapper.config.squintTriggerBelow,
                            isActive: mapper.lastTriggeredAction?.starts(with: mapper.config.squintAction.rawValue) ?? false
                        )
                        
                        // Lips Pressed
                        ExpressionRow(
                            label: "Lips Pressed",
                            value: mapper.state.lipsPressed,
                            threshold: $mapper.config.lipsPressedThreshold,
                            action: $mapper.config.lipsPressedAction,
                            triggerBelow: $mapper.config.lipsPressedTriggerBelow,
                            isActive: mapper.lastTriggeredAction?.starts(with: mapper.config.lipsPressedAction.rawValue) ?? false
                        )
                    }
                    .padding()
                }
                .tabItem {
                    Label("Expressions", systemImage: "face.smiling")
                }
                
                // Combinations Tab
                ComboConfigView(mapper: mapper)
                    .tabItem {
                        Label("Combos", systemImage: "plus.square.on.square")
                    }
            }
        }
        .frame(minWidth: 400) // Allow resizing, set minimum
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

struct ProfileManagementView: View {
    @ObservedObject var mapper: ActionMapper
    @State private var newProfileName: String = ""
    @State private var showingDeleteAlert = false

    var body: some View {
        VStack {
            HStack {
                Text("Profile:")
                Picker("Profile", selection: $mapper.activeProfileID) {
                    ForEach(mapper.profiles) { profile in
                        Text(profile.name).tag(profile.id as UUID?)
                    }
                }
                .labelsHidden()
                .onChange(of: mapper.activeProfileID) { oldID, newID in
                    if let id = newID {
                        mapper.selectProfile(profileID: id)
                        if let profile = mapper.profiles.first(where: { $0.id == id }) {
                            newProfileName = profile.name
                        }
                    }
                }
                
                Button(action: {
                    if mapper.activeProfileID != nil {
                        showingDeleteAlert = true
                    }
                }) {
                    Image(systemName: "trash")
                }
                .disabled(mapper.profiles.count <= 1)
                .alert("Delete Profile", isPresented: $showingDeleteAlert) {
                    Button("Delete", role: .destructive) {
                        if let id = mapper.activeProfileID {
                            mapper.deleteProfile(profileID: id)
                        }
                    }
                } message: {
                    Text("Are you sure you want to delete this profile? This cannot be undone.")
                }
            }
            
            HStack {
                TextField("Profile Name", text: $newProfileName)
                
                Button("Save") {
                    if !newProfileName.isEmpty {
                        mapper.saveProfile(name: newProfileName)
                    }
                }
                .disabled(newProfileName.isEmpty)
            }
        }
        .padding([.horizontal, .bottom])
        .onAppear {
            // Set initial text field value
            if let id = mapper.activeProfileID, let profile = mapper.profiles.first(where: { $0.id == id }) {
                newProfileName = profile.name
            }
        }
    }
}

struct ExpressionRow: View {
    let label: String
    let value: Double
    @Binding var threshold: Double
    @Binding var action: FaceAction
    @Binding var triggerBelow: Bool // New: Trigger Direction
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
                    // If triggerBelow is true (e.g. Wink), we want to show how "closed" it is?
                    // Or just show the raw value and the threshold marker?
                    // Let's show raw value (0..1) always.
                    
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

struct ComboConfigView: View {
    @ObservedObject var mapper: ActionMapper
    @State private var newPrimary: FaceExpression = .eyebrowRaise
    @State private var newSecondary: FaceExpression = .mouthOpen
    @State private var newAction: FaceAction = .leftClick
    
    var body: some View {
        VStack {
            // List of Combos
            List {
                ForEach($mapper.config.gestureCombos) { $combo in
                    HStack {
                        Toggle("", isOn: $combo.isEnabled)
                            .labelsHidden()
                        
                        VStack(alignment: .leading) {
                            Text("\(combo.primary.rawValue) + \(combo.secondary.rawValue)")
                                .fontWeight(.medium)
                            Text("→ \(combo.action.rawValue)")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if let index = mapper.config.gestureCombos.firstIndex(of: combo) {
                                mapper.config.gestureCombos.remove(at: index)
                            }
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .onDelete { indexSet in
                    mapper.config.gestureCombos.remove(atOffsets: indexSet)
                }
            }
            .frame(height: 200)
            .cornerRadius(8)
            
            Divider()
            
            // Add New Combo
            VStack(spacing: 10) {
                Text("Add New Combination")
                    .font(.headline)
                
                HStack {
                    Picker("1st", selection: $newPrimary) {
                        ForEach(FaceExpression.allCases) { expr in
                            Text(expr.rawValue).tag(expr)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 100)
                    
                    Text("+")
                    
                    Picker("2nd", selection: $newSecondary) {
                        ForEach(FaceExpression.allCases) { expr in
                            Text(expr.rawValue).tag(expr)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 100)
                }
                
                HStack {
                    Text("Action:")
                    Picker("Action", selection: $newAction) {
                        ForEach(FaceAction.allCases) { action in
                            Text(action.rawValue).tag(action)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 120)
                }
                
                Button(action: {
                    let newCombo = GestureCombo(primary: newPrimary, secondary: newSecondary, action: newAction)
                    mapper.config.gestureCombos.append(newCombo)
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Combination")
                    }
                }
                .disabled(newPrimary == newSecondary)
            }
            .padding()
            .background(Color.black.opacity(0.05))
            .cornerRadius(8)
        }
        .padding()
    }
}

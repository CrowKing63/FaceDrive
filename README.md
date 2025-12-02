# FaceDrive

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS-lightgrey.svg" alt="Platform: macOS">
  <img src="https://img.shields.io/badge/swift-5.0+-orange.svg" alt="Swift 5.0+">
  <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT">
</p>

**FaceDrive** is a macOS application that enables hands-free computer control using facial expressions. By leveraging Apple's Vision framework for real-time facial landmark detection, FaceDrive translates natural facial movements into mouse and keyboard actions, providing an accessible and intuitive way to interact with your Mac.

## ✨ Features

### 🎭 Comprehensive Expression Detection
FaceDrive detects a wide range of facial expressions and translates them into computer actions:

- **Eye Control**
  - Eye Closed / Wink detection with customizable hold duration
  - Squint detection for subtle control

- **Mouth Expressions**
  - Mouth Open/Close detection
  - Smile (mouth width) detection
  - Pucker (lips forward) detection
  - Lips Pressed detection
  - Directional mouth movement (left/right)

- **Eyebrow Control**
  - Eyebrow Raise detection
  - Independent brow tracking for nuanced control

### 🖱️ Extensive Action Mapping
Each facial expression can be mapped to various computer actions:

- **Mouse Actions**: Left Click, Right Click, Scroll Up/Down
- **Mouse Movement**: Move Left/Right/Up/Down
- **Keyboard Keys**: Enter, Escape, Space, Arrow Keys
- **Shortcuts**: Copy (Cmd+C), Paste (Cmd+V), Undo (Cmd+Z)

### 🎯 Advanced Features

#### Gesture Combinations
Create complex gesture combinations by pairing two facial expressions for a single action (e.g., "Eyebrow Raise + Mouth Open" → Left Click). This allows for more sophisticated control workflows and reduces accidental triggers.

#### Calibration System
- **Automatic Startup Calibration**: Automatically calibrates to your neutral facial expression on launch
- **Manual Calibration**: Recalibrate anytime with a single button click
- **Zeroing Baseline**: All expression values are normalized relative to your neutral face, ensuring consistent detection across users and sessions

#### Sensitivity Controls
Fine-tune detection sensitivity with adjustable gain controls:
- **Eye Gain**: Adjust eye openness/closure sensitivity (10.0 - 100.0)
- **Mouth Height Gain**: Control mouth open/close sensitivity (0.5 - 3.0)
- **Mouth Width Gain**: Adjust smile detection sensitivity (0.5 - 3.0)
- **Eyebrow Gain**: Fine-tune eyebrow raise sensitivity (1.0 - 10.0)
- **Smoothing Factor**: Reduce jitter with adjustable smoothing (0.0 - 0.95)
- **Wink Hold Duration**: Set how long a wink must be held before triggering (0.0 - 1.0s)

#### Profile Management
- Create and save multiple configuration profiles
- Switch between profiles for different use cases
- Delete and manage profiles easily
- Persistent storage of all settings

#### Trigger Direction Control
For each expression, choose whether to trigger when the value goes:
- **Above** a threshold (e.g., mouth opens more than 30%)
- **Below** a threshold (e.g., eye closes below 20%)

This provides flexibility in how actions are triggered based on your preferred interaction style.

### 🎨 User Interface

#### Menu Bar Integration
- Lives in your menu bar for easy access
- Minimal system footprint
- Quick access to all controls

#### Real-Time Dashboard
- **Live Camera Preview**: See your face with overlaid facial landmarks
- **Expression Meters**: Real-time bars showing current expression values
- **Visual Feedback**: Active expressions highlighted in green
- **Threshold Markers**: Visual indicators showing trigger thresholds
- **Last Action Display**: Shows the most recently triggered action

#### Tabbed Interface
- **Expressions Tab**: Configure individual facial expression actions and thresholds
- **Combos Tab**: Create and manage gesture combinations

## 🔧 Technical Architecture

### Core Technologies

- **Swift**: Primary programming language
- **SwiftUI**: Modern, declarative UI framework
- **AppKit**: Application lifecycle and menu bar integration
- **Vision Framework**: Facial landmark detection using `VNFaceObservation` and `VNFaceLandmarks2D`
- **CoreGraphics**: Programmatic mouse and keyboard control via `CGEvent`
- **AVFoundation**: Camera capture and video processing
- **Combine**: Reactive data flow between components

### Project Structure

```
FaceDrive/
├── FaceDriveApp.swift          # Main app entry point
├── AppDelegate.swift           # Application lifecycle & menu bar
├── ContentView.swift           # Main SwiftUI view container
├── DashboardView.swift         # Control panel UI
├── FaceTracking/
│   ├── CameraManager.swift     # AVCaptureSession management
│   ├── FaceDetector.swift      # Vision framework integration
│   ├── ExpressionDetector.swift # Expression calculation algorithms
│   ├── CameraPreview.swift     # SwiftUI camera view
│   └── FaceLandmarksOverlay.swift # Landmark visualization
└── Input/
    ├── InputController.swift   # CGEvent-based input control
    ├── ActionMapper.swift      # Expression → Action mapping logic
    └── FaceModels.swift        # Data models and configurations
```

### Key Components

#### CameraManager
- Manages `AVCaptureSession` for camera access
- Provides real-time video frames via Combine publishers
- Handles camera permissions and session lifecycle

#### FaceDetector
- Utilizes Vision framework's `VNDetectFaceLandmarksRequest`
- Processes video frames to extract 76 facial landmark points
- Publishes facial landmark data to subscribers

#### ExpressionDetector
- Calculates expression values from facial landmarks
- Implements normalization and calibration algorithms
- Applies smoothing to reduce jitter
- Computes metrics for:
  - Eye openness (vertical height between eyelids)
  - Mouth height and width (inner/outer lip dimensions)
  - Eyebrow position relative to eyes
  - Mouth lateral movement relative to nose

#### ActionMapper
- Maintains expression state and configuration
- Implements trigger logic with threshold comparison
- Handles gesture combination detection
- Manages profile persistence with `UserDefaults`
- Applies smoothing using exponential moving average

#### InputController
- Creates `CGEvent` instances for mouse and keyboard actions
- Uses `.combinedSessionState` event source for compatibility
- Implements accessibility permission checking
- Tags events with unique identifier to distinguish synthetic events

## 🚀 Getting Started

### Requirements

- **macOS 12.0** or later
- **Xcode 14.0** or later (for building from source)
- **Mac with built-in or external camera**
- Swift 5.7+

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/FaceDrive.git
   cd FaceDrive
   ```

2. **Open in Xcode**
   ```bash
   open FaceDrive.xcodeproj
   ```

3. **Build and Run**
   - Select the FaceDrive scheme
   - Click the Run button (⌘R) or Product → Run
   - The app will launch and appear in your menu bar

### First-Time Setup

1. **Grant Camera Permission**
   - On first launch, macOS will request camera access
   - Click "OK" to allow FaceDrive to use your camera

2. **Grant Accessibility Permission** ⚠️ **Critical Step**
   - FaceDrive requires Accessibility permissions to control your mouse and keyboard
   - Go to **System Settings** → **Privacy & Security** → **Accessibility**
   - Find "FaceDrive" in the list and enable it
   - You may need to restart the app after granting permission

3. **Automatic Calibration**
   - When you first open the dashboard, FaceDrive will calibrate to your neutral expression
   - Keep a neutral face during this brief calibration period
   - A calibration overlay will appear and disappear automatically

4. **Configure Your First Action**
   - Click the FaceDrive icon in the menu bar
   - Choose an expression (e.g., "Smile")
   - Select an action from the dropdown (e.g., "Left Click")
   - Adjust the sensitivity slider if needed
   - Try the expression to trigger the action!

## 📖 Usage Guide

### Basic Configuration

1. **Open the Dashboard**
   - Click the FaceDrive menu bar icon
   - The dashboard window will appear

2. **Configure an Expression**
   - Find the expression you want to use (e.g., "Mouth Open")
   - Select an action from the dropdown menu
   - Watch the real-time meter to see your current expression value
   - The red line shows the trigger threshold
   - Click "Set" to auto-set the threshold to your current expression value

3. **Adjust Sensitivity**
   - Use the "Sens:" slider to adjust the trigger threshold
   - Lower values = more sensitive (easier to trigger)
   - Higher values = less sensitive (harder to trigger)

4. **Change Trigger Direction**
   - Click the "< (Less)" or "> (More)" button
   - **"< (Less)"**: Triggers when value drops *below* threshold (e.g., for wink/eye close)
   - **"> (More)"**: Triggers when value rises *above* threshold (e.g., for mouth open)

### Calibration

Calibration is essential for accurate detection. It sets your neutral baseline.

**When to Calibrate:**
- After launching the app (done automatically)
- When switching users
- When lighting conditions change significantly
- When expression detection feels "off"

**How to Calibrate:**
1. Ensure you have a neutral expression (relaxed face)
2. Click the "Calibrate Face (Neutral)" button
3. Hold your neutral expression for 1-2 seconds
4. All expression meters should return to near-zero

### Global Sensitivity Adjustments

At the top of the dashboard, you'll find global gain controls:

- **Eye**: Increases/decreases eye detection sensitivity (inverted scale)
- **Mouth H**: Adjusts mouth opening/closing sensitivity
- **Mouth W**: Adjusts smile (mouth width) sensitivity
- **Eyebrow**: Adjusts eyebrow raise sensitivity
- **Smooth**: Controls smoothing factor (higher = more stable but less responsive)
- **Wink**: Sets how long you must hold a wink before it triggers

### Creating Gesture Combinations

Gesture combinations allow multiple expressions to be active simultaneously before triggering an action.

1. Switch to the "Combos" tab
2. Click "Add New Combination"
3. Select the first expression (e.g., "Eyebrow Raise")
4. Select the second expression (e.g., "Smile")
5. Choose the action to trigger
6. Click "Add Combination"

**Note:** Both expressions must be active (above/below their respective thresholds) for the combo to trigger.

### Profile Management

Profiles let you save different configurations for various use cases.

**Creating a Profile:**
1. Configure your expressions and settings
2. Type a name in the "Profile Name" field
3. Click "Save"

**Switching Profiles:**
- Use the profile dropdown to select a saved profile
- All settings will immediately switch to that profile

**Deleting a Profile:**
- Select the profile you want to delete
- Click the trash icon
- Confirm deletion

**Note:** You cannot delete your last remaining profile.

## 🎮 Example Use Cases

### Hands-Free Browsing
- **Smile** → Left Click (click links)
- **Mouth Open** → Scroll Down
- **Mouth Close** (Lips Pressed) → Scroll Up
- **Mouth Right** → Move Right
- **Mouth Left** → Move Left

### Gaming
- **Wink Left** → Left Click (fire)
- **Wink Right** → Right Click (aim)
- **Mouth Left** → Move Left
- **Mouth Right** → Move Right
- **Eyebrow Raise** → Jump (Space)

### Accessibility
- **Smile** → Enter
- **Pucker** → Escape
- **Eye Close** → Left Click
- **Eyebrow Raise + Smile** → Copy
- **Eyebrow Raise + Pucker** → Paste

### Document Editing
- **Mouth Open** → Arrow Down
- **Lips Pressed** → Arrow Up
- **Mouth Right** → Arrow Right
- **Mouth Left** → Arrow Left
- **Smile** → Space

## 🐛 Troubleshooting

### Actions aren't triggering

**Check Accessibility Permissions:**
1. Go to System Settings → Privacy & Security → Accessibility
2. Ensure FaceDrive is checked/enabled
3. If it's already enabled, try removing it and re-adding it
4. Restart FaceDrive

**Recalibrate:**
- Click "Calibrate Face (Neutral)" with a neutral expression

**Adjust Sensitivity:**
- Watch the real-time meters
- Lower the threshold if actions aren't triggering
- Raise the threshold if actions trigger too easily

### Camera not working

**Grant Camera Permission:**
1. Go to System Settings → Privacy & Security → Camera
2. Enable FaceDrive

**Check Camera Availability:**
- Ensure no other app is using the camera
- Try quitting and restarting FaceDrive

### Face detection is jumpy

**Increase Smoothing:**
- Increase the "Smooth" slider at the top of the dashboard
- Higher values reduce jitter but slightly delay response

**Improve Lighting:**
- Ensure your face is well-lit
- Avoid backlighting
- Position yourself facing a light source

### Expression values seem wrong

**Recalibrate:**
1. Make a truly neutral face
2. Click "Calibrate Face (Neutral)"
3. Hold the neutral expression until calibration completes

**Adjust Gain:**
- If expressions are too sensitive, lower the relevant gain slider
- If expressions aren't sensitive enough, raise the gain slider

### App crashes on launch

**Check macOS Version:**
- Ensure you're running macOS 12.0 or later

**Reset Settings:**
- Delete saved preferences:
  ```bash
  defaults delete com.yourcompany.FaceDrive
  ```
- Relaunch the app

## 🔒 Privacy & Security

- **Camera Data**: All camera processing happens **locally on your device**. No video or image data is ever transmitted or stored.
- **Facial Landmarks**: Computed in real-time using Apple's Vision framework. Raw landmark data is not saved.
- **Settings Storage**: Configuration and profiles are saved locally using `UserDefaults`.
- **Accessibility Access**: Required only to send mouse/keyboard events. FaceDrive does not monitor or log your activity.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Setup

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 🙏 Acknowledgments

- Built with Apple's Vision framework for facial landmark detection
- Uses Apple's Combine framework for reactive programming
- Inspired by the need for accessible, hands-free computer control

## 📧 Contact

For questions, suggestions, or issues, please:
- Open an issue on GitHub
- Or reach out via email: [your-email@example.com]

## 🗺️ Roadmap

Potential future features:
- [ ] Head tracking for mouse cursor control
- [ ] Custom gesture recording
- [ ] Multi-monitor support
- [ ] Export/import configuration profiles
- [ ] macOS accessibility API integration
- [ ] Touch Bar support
- [ ] Voice command integration
- [ ] Advanced ML model for custom gesture training

---

Made with ❤️ for accessibility and hands-free computing

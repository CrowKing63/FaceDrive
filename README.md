# MagicScroll

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS-lightgrey.svg" alt="Platform: macOS">
  <img src="https://img.shields.io/badge/swift-5.0+-orange.svg" alt="Swift 5.0+">
  <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT">
</p>

**MagicScroll** is a macOS application that enables hands-free scrolling using facial expressions. By leveraging Apple's Vision framework for real-time facial landmark detection, MagicScroll translates natural facial movements into scroll actions, providing an accessible and intuitive way to browse content on your Mac.

## ✨ Features

### 🎭 Expression Detection
MagicScroll detects two simple facial expressions for hands-free scrolling:

- **Mouth Open**: Scroll down action
- **Eye Close**: Scroll up action (with duration threshold to prevent blinks from triggering)

### 🎯 Core Features

#### Pause/Resume Control
- **Menu Bar Toggle**: Instantly pause and resume facial expression recognition
- **Visual Indicator**: Menu bar icon changes to a dashed face outline when paused
- **Quick Access**: Easily toggle between active and paused states from the menu

#### Calibration System
- **Automatic Startup Calibration**: Automatically calibrates to your neutral facial expression on launch (3-second calibration period)
- **Manual Calibration**: Recalibrate anytime via menu bar or dashboard button
- **Zeroing Baseline**: All expression values are normalized relative to your neutral face, ensuring consistent detection across users and sessions
- **Visual Feedback**: Menu bar icon shows calibration status with a dashed face outline

#### Sensitivity Controls
Fine-tune detection sensitivity with adjustable parameters:
- **Mouth Gain**: Control mouth open/close sensitivity (0.5 - 30.0)
- **Eye Gain**: Adjust eye openness/closure sensitivity (1.0 - 50.0)
- **Smoothing Factor**: Reduce jitter with adjustable smoothing (0.0 - 0.95)
- **Scroll Speed**: Adjust scrolling speed (1.0 - 100.0)
- **Duration Controls**: Set how long expressions must be held before triggering (prevents accidental triggers)

#### Persistent Settings
- All settings automatically saved to UserDefaults
- Configuration persists across app launches
- No manual save required

#### Trigger Direction Control
For each expression, choose whether to trigger when the value goes:
- **Above** a threshold (e.g., mouth opens more than 30%)
- **Below** a threshold (e.g., eye closes below 20%)

### 🎨 User Interface

#### Menu Bar Integration
- **Always Accessible**: Lives in your menu bar for instant access
- **Dynamic Icon States**: Visual feedback for different app states
  - 🟢 Green smiling face: Expression active
  - ⚪ White smiling face: Ready and idle
  - ⚫ Gray dashed face: Paused or calibrating
- **Quick Controls**: 
  - Pause/Resume toggle
  - Manual calibration
  - Dashboard access
- **Minimal Footprint**: Runs efficiently in the background

#### Real-Time Dashboard
- **Live Camera Preview**: See your face with overlaid facial landmarks
- **Expression Meters**: Real-time bars showing current expression values
- **Visual Feedback**: Active expressions highlighted in green
- **Threshold Markers**: Visual indicators showing trigger thresholds
- **Compact Design**: Simplified interface focused on essential controls
- **Calibration Button**: Quick access to manual calibration

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
MagicScroll/
├── MagicScrollApp.swift        # Main app entry point
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
   git clone https://github.com/yourusername/MagicScroll.git
   cd MagicScroll
   ```

2. **Open in Xcode**
   ```bash
   open MagicScroll.xcodeproj
   ```

3. **Build and Run**
   - Select the MagicScroll scheme
   - Click the Run button (⌘R) or Product → Run
   - The app will launch and appear in your menu bar

### First-Time Setup

1. **Grant Camera Permission**
   - On first launch, macOS will request camera access
   - Click "OK" to allow MagicScroll to use your camera

2. **Grant Accessibility Permission** ⚠️ **Critical Step**
   - MagicScroll requires Accessibility permissions to control scrolling
   - Go to **System Settings** → **Privacy & Security** → **Accessibility**
   - Find "MagicScroll" (or "FaceDrive") in the list and enable it
   - You may need to restart the app after granting permission

3. **Automatic Calibration**
   - On first launch, MagicScroll automatically calibrates to your neutral expression
   - Keep a relaxed, neutral face for 3 seconds
   - The menu bar icon will show a dashed face during calibration
   - Icon changes to a smiling face when ready

4. **Start Using**
   - Open your mouth to scroll down
   - Close your eyes (hold briefly) to scroll up
   - Open the dashboard to adjust sensitivity if needed
   - Use the pause feature when you need a break

## 📖 Usage Guide

### Quick Start

1. **Launch MagicScroll**
   - The app appears in your menu bar
   - Automatic calibration runs for 3 seconds (keep a neutral face)
   - Menu bar icon shows calibration status (dashed face → smiling face)

2. **Open the Dashboard**
   - Click the MagicScroll menu bar icon
   - Select "Open Dashboard"
   - The dashboard window appears with live camera preview

3. **Start Scrolling**
   - **Mouth Open**: Scroll down
   - **Eye Close** (hold for ~0.5s): Scroll up
   - Watch the expression meters for real-time feedback

### Pause/Resume

**Pausing Expression Recognition:**
1. Click the MagicScroll menu bar icon
2. Select "Pause"
3. The menu bar icon changes to a gray dashed face
4. All facial expression detection is suspended

**Resuming:**
1. Click the menu bar icon
2. Select "Resume"
3. The icon returns to normal (smiling face)
4. Expression detection resumes immediately

**Use Cases for Pause:**
- Taking a break without quitting the app
- Temporarily disabling scrolling during video calls
- Preventing accidental triggers while eating or talking

### Calibration

Calibration sets your neutral facial expression baseline for accurate detection.

**Automatic Calibration:**
- Runs automatically on app launch
- Takes 3 seconds
- Menu bar icon shows dashed face during calibration
- Keep a relaxed, neutral expression

**Manual Calibration:**
1. Click the menu bar icon
2. Select "Calibrate Face (Neutral)"
3. Keep a neutral expression for 3 seconds
4. Icon changes from dashed to smiling when complete

**When to Recalibrate:**
- Expression detection feels inaccurate
- Lighting conditions change significantly
- Switching users
- Camera position changes

### Adjusting Sensitivity

**Expression Thresholds:**
- Each expression has a sensitivity slider in the dashboard
- Lower threshold = easier to trigger
- Higher threshold = harder to trigger
- Watch the real-time meter to find the right value

**Trigger Direction:**
- **"< (Less)"**: Triggers when value drops *below* threshold (for eye close)
- **"> (More)"**: Triggers when value rises *above* threshold (for mouth open)

**Global Controls:**
- **Mouth Gain**: Overall mouth detection sensitivity
- **Eye Gain**: Overall eye detection sensitivity
- **Smoothing**: Reduces jitter (higher = smoother but less responsive)
- **Scroll Speed**: How fast scrolling occurs
- **Duration**: How long to hold expression before triggering

### Settings Persistence

All your settings are automatically saved:
- Configuration changes save automatically after 1 second
- Settings persist across app launches
- No manual save required
- Calibration values are preserved

## 🎮 Use Cases

### Hands-Free Web Browsing
Perfect for reading long articles, social media feeds, or documentation:
- **Mouth Open**: Scroll down through content
- **Eye Close**: Scroll back up
- **Pause**: Take a break or interact with keyboard/mouse normally

### Reading Documents
Navigate through PDFs, ebooks, or long documents:
- **Mouth Open**: Move to next page/section
- **Eye Close**: Return to previous content
- **Adjustable Speed**: Fine-tune scroll speed for comfortable reading

### Accessibility
Provides hands-free scrolling for users with limited mobility:
- **Simple Expressions**: Only two easy-to-perform expressions needed
- **Customizable Sensitivity**: Adjust to individual capabilities
- **Duration Controls**: Prevent accidental triggers
- **Pause Feature**: Easy control when assistance is needed

### Multitasking
Scroll while your hands are busy:
- Reading recipes while cooking
- Following tutorials while working
- Browsing content while eating
- Reviewing documents while taking notes

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

### Completed Features
- [x] Pause/Resume toggle with visual feedback
- [x] Automatic and manual calibration
- [x] Real-time expression visualization
- [x] Menu bar integration with dynamic icons
- [x] Automatic settings persistence

### Planned Features
- [ ] Additional expression options (head tilt, gaze direction)
- [ ] Keyboard shortcut for pause/resume
- [ ] Export/import configuration settings
- [ ] Multi-monitor scroll support
- [ ] Customizable scroll acceleration curves
- [ ] Statistics and usage tracking
- [ ] Dark mode optimizations
- [ ] Improved low-light performance

---

Made with ❤️ for accessibility and hands-free computing

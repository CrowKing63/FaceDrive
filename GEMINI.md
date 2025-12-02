# FaceDrive Gemini Assistant Context

This document provides context for the Gemini AI assistant to understand and assist with the FaceDrive project.

## Project Overview

FaceDrive is a macOS application that allows users to control their computer using facial expressions. It captures video from the camera, uses the Vision framework to detect facial landmarks, and translates expressions like winks, smiles, and eyebrow raises into mouse and keyboard actions.

The application is written in Swift using SwiftUI for the user interface and AppKit for the application lifecycle and menu bar integration. It is a menu bar application that runs in the background.

## Core Technologies

*   **Swift:** The primary programming language.
*   **SwiftUI:** Used for building the user interface, including the main content view and the dashboard.
*   **AppKit:** Used for managing the application lifecycle, menu bar integration, and window management.
*   **Vision Framework:** Used for detecting facial landmarks from the camera feed.
*   **CoreGraphics:** Used for programmatically controlling the mouse and keyboard.

## Project Structure

The project is organized into the following main components:

*   `FaceDriveApp.swift`: The main entry point of the application. It sets up the app delegate and the main scene.
*   `AppDelegate.swift`: Manages the application lifecycle, including setting up the menu bar item and handling application events.
*   `ContentView.swift`: The main SwiftUI view, which combines the camera preview and the dashboard.
*   `DashboardView.swift`: The main control panel, where users can configure sensitivity and actions for different facial expressions.
*   `FaceTracking/`: This directory contains the code related to face detection and tracking.
    *   `CameraManager.swift`: Manages the camera session.
    *   `FaceDetector.swift`: Uses the Vision framework to detect facial landmarks.
    *   `CameraPreview.swift`: A SwiftUI view that displays the camera feed.
    *   `FaceLandmarksOverlay.swift`: A SwiftUI view that overlays the detected facial landmarks on the camera feed.
*   `Input/`: This directory contains the code related to input control.
    *   `InputController.swift`: Uses CoreGraphics to programmatically control the mouse and keyboard.
    *   `ActionMapper.swift`: Maps facial expressions to specific actions.
    *   `FaceModels.swift`: Defines the data structures for facial expressions and actions.

## Building and Running

To build and run the project, open `FaceDrive.xcodeproj` in Xcode and click the "Run" button.

**Important:** The application requires Accessibility permissions to control the mouse and keyboard. If the application doesn't work, make sure to grant Accessibility permissions in System Settings > Privacy & Security > Accessibility.

## Development Conventions

The project follows standard Swift and SwiftUI conventions. The code is well-structured and uses modern Swift features like Combine for reactive programming.

The project uses a shared `AppServices` class to provide singleton instances of the `CameraManager`, `FaceDetector`, and `ActionMapper` to the SwiftUI views. This is a form of dependency injection that makes the code more modular and testable.

import Cocoa
import Combine
import CoreGraphics

class InputController: ObservableObject {
    private var source: CGEventSource?
    
    private let magicUserData: Int64 = 0xFACE
    
    init() {
        // Use combinedSessionState instead of hidSystemState
        // This allows synthetic events to work better with physical mouse movement
        self.source = CGEventSource(stateID: .combinedSessionState)
    }
    
    func checkAccessibility() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    func moveMouse(to point: CGPoint) {
        guard let event = CGEvent(mouseEventSource: source, mouseType: .mouseMoved, mouseCursorPosition: point, mouseButton: .left) else {
            return
        }
        event.setIntegerValueField(.eventSourceUserData, value: magicUserData)
        event.post(tap: .cghidEventTap)
    }
    
    func click(button: CGMouseButton, down: Bool) {
        let currentPos = CGEvent(source: nil)?.location ?? .zero
        let type: CGEventType
        
        switch button {
        case .left:
            type = down ? .leftMouseDown : .leftMouseUp
        case .right:
            type = down ? .rightMouseDown : .rightMouseUp
        default:
            type = down ? .otherMouseDown : .otherMouseUp
        }
        
        guard let event = CGEvent(mouseEventSource: source, mouseType: type, mouseCursorPosition: currentPos, mouseButton: button) else {
            return
        }
        event.setIntegerValueField(.eventSourceUserData, value: magicUserData)
        event.post(tap: .cghidEventTap)
    }
    
    func scroll(x: Int32, y: Int32) {
        guard let event = CGEvent(scrollWheelEvent2Source: source, units: .pixel, wheelCount: 2, wheel1: y, wheel2: x, wheel3: 0) else {
            return
        }
        event.setIntegerValueField(.eventSourceUserData, value: magicUserData)
        event.post(tap: .cghidEventTap)
    }
    
    func sendDragEvent(position: CGPoint, button: CGMouseButton) {
        let eventType: CGEventType
        switch button {
        case .left:
            eventType = .leftMouseDragged
        case .right:
            eventType = .rightMouseDragged
        default:
            eventType = .otherMouseDragged
        }
        
        guard let event = CGEvent(mouseEventSource: source, mouseType: eventType, mouseCursorPosition: position, mouseButton: button) else {
            return
        }
        event.setIntegerValueField(.eventSourceUserData, value: magicUserData)
        
        // Post to session event tap for better browser compatibility
        event.post(tap: .cgSessionEventTap)
    }
    
    // Helper to check if we have permission (Accessibility)
    // Note: This isn't a perfect check, but if we can't create an event, we likely lack permission.
    // A better check is AXIsProcessTrusted()
    func checkPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    func moveMouseRelative(dx: CGFloat, dy: CGFloat) {
        let currentPos = CGEvent(source: nil)?.location ?? .zero
        let newPos = CGPoint(x: currentPos.x + dx, y: currentPos.y + dy)
        
        guard let event = CGEvent(mouseEventSource: source, mouseType: .mouseMoved, mouseCursorPosition: newPos, mouseButton: .left) else {
            return
        }
        event.setIntegerValueField(.eventSourceUserData, value: magicUserData)
        event.post(tap: .cghidEventTap)
    }
    
    func pressKey(keyCode: CGKeyCode, modifiers: CGEventFlags = []) {
        guard let downEvent = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let upEvent = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else {
            return
        }
        
        downEvent.flags = modifiers
        upEvent.flags = modifiers
        
        downEvent.setIntegerValueField(.eventSourceUserData, value: magicUserData)
        upEvent.setIntegerValueField(.eventSourceUserData, value: magicUserData)
        
        downEvent.post(tap: .cghidEventTap)
        upEvent.post(tap: .cghidEventTap)
    }
}

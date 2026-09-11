import CoreGraphics
import Foundation

enum IdleProbe {
    static func seconds() -> Double {
        let types: [CGEventType] = [
            .mouseMoved,
            .leftMouseDown,
            .rightMouseDown,
            .keyDown,
            .scrollWheel,
        ]
        let values = types.map {
            CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: $0)
        }
        return values.min() ?? .greatestFiniteMagnitude
    }
}

import Foundation

#if DEBUG
enum AgentDebugNDJSON {
    static let path = "/Users/ericaremmele/Projects/undrmnd/.cursor/debug-49c459.log"
    static let sessionId = "49c459"

    static func log(location: String, message: String, hypothesisId: String, data: [String: Any] = [:]) {
        let payload: [String: Any] = [
            "sessionId": sessionId,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000),
            "location": location,
            "message": message,
            "hypothesisId": hypothesisId,
            "data": data
        ]
        guard JSONSerialization.isValidJSONObject(payload),
              let json = try? JSONSerialization.data(withJSONObject: payload),
              let line = String(data: json, encoding: .utf8) else { return }
        let url = URL(fileURLWithPath: path)
        let bytes = Data((line + "\n").utf8)
        if FileManager.default.fileExists(atPath: path) {
            guard let h = try? FileHandle(forWritingTo: url) else { return }
            defer { try? h.close() }
            try? h.seekToEnd()
            try? h.write(contentsOf: bytes)
        } else {
            try? bytes.write(to: url)
        }
    }
}
#endif

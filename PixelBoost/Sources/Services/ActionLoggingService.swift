import Foundation
import UIKit

/// Posts `ActionLogEntry` records to a deployed `upscaler-bridge` (see
/// server/README.md) — the general-purpose counterpart to
/// `UpscaleLoggingService` for actions that aren't a full upscale attempt.
/// Fire-and-forget by design, same reasoning as `UpscaleLoggingService`: a
/// logging failure must never surface to the user or block the action it's
/// describing.
enum ActionLoggingService {
    /// - Parameter detail: encoded as a JSON object string server-side;
    ///   values should be JSON-serializable (`String`, `Bool`, `Int`,
    ///   `Double`, or `nil`).
    static func log(_ action: String, detail: [String: Any?] = [:]) {
        guard ServerConfig.baseURL != nil else { return }
        Task.detached(priority: .background) {
            do {
                let entry = ActionLogEntry(
                    device_id: DeviceIdentity.current,
                    action: action,
                    detail: Self.encodeDetail(detail),
                    app_version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                    os_version: UIDevice.current.systemVersion,
                    device_model: UIDevice.current.model
                )
                var request = try APIClient.request(path: "log/action", method: "POST")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONEncoder().encode(entry)
                _ = try await APIClient.data(for: request)
            } catch {
                print("ActionLoggingService: failed to log action '\(action)' — \(error.localizedDescription)")
            }
        }
    }

    private static func encodeDetail(_ detail: [String: Any?]) -> String? {
        guard !detail.isEmpty else { return nil }
        // NSNull for nil values — JSONSerialization drops entries whose
        // value is Swift's `nil` outright rather than encoding `null`, and
        // "this key was absent" vs "this key was explicitly nil" is a real
        // distinction worth keeping in a debug log (e.g. a save's `reason`
        // being nil means overwrite fully succeeded, not "unknown").
        let normalized = detail.mapValues { $0 ?? NSNull() }
        guard JSONSerialization.isValidJSONObject(normalized),
              let data = try? JSONSerialization.data(withJSONObject: normalized) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}

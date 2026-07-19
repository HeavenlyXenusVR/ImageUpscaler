import Foundation

/// Posts `UpscaleLogEntry` records to a deployed `upscaler-bridge` (see
/// server/README.md). Failures never throw out to the caller — a logging
/// failure must never surface to the user or block the upscale flow it's
/// describing — but unlike a truly fire-and-forget call, this one is
/// `async` and returns the server-assigned id (`nil` on any failure) so
/// `UpscaleRunner` can link an auto-uploaded result image back to this
/// entry via `image_exports.history_id`.
enum UpscaleLoggingService {
    private struct LogResponse: Decodable { let id: String }

    @discardableResult
    static func log(_ entry: UpscaleLogEntry) async -> String? {
        guard ServerConfig.baseURL != nil else { return nil }
        do {
            var request = try APIClient.request(path: "log/upscale", method: "POST")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(entry)
            let data = try await APIClient.data(for: request)
            return try JSONDecoder().decode(LogResponse.self, from: data).id
        } catch {
            print("UpscaleLoggingService: failed to log upscale — \(error.localizedDescription)")
            return nil
        }
    }
}

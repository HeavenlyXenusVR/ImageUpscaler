import Foundation

/// Mirrors `ActionLogEntry` (the Pydantic model) in server/main.py field for
/// field — keep the two in sync. Covers anything that isn't a full upscale
/// attempt (`UpscaleLogEntry` already covers that) but is still worth a
/// server-side record of when debugging a report that can't be reproduced
/// locally — Save, Compare Models, Cutout, a Settings change, ...
struct ActionLogEntry: Encodable {
    let device_id: String
    let action: String
    /// Free-form JSON-encoded string, not a nested object — what's worth
    /// recording varies a lot by action, and a per-action Codable struct
    /// for each one isn't worth the ceremony for a debug log.
    let detail: String?
    let app_version: String?
    let os_version: String?
    let device_model: String?
}

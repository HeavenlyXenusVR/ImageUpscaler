import SwiftUI

struct SettingsView: View {
    @AppStorage(ServerConfig.baseURLDefaultsKey) private var serverURLString: String = ServerConfig.defaultBaseURLString
    @AppStorage(ServerConfig.apiKeyDefaultsKey) private var apiKeyString: String = ""
    @AppStorage(Haptics.enabledDefaultsKey) private var hapticsEnabled: Bool = true

    var body: some View {
        Form {
            Section {
                Toggle("Haptic Feedback", isOn: $hapticsEnabled)
            } header: {
                Text("Feedback")
            }

            Section {
                TextField("https://your-server.example.com", text: $serverURLString)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("API key (optional)", text: $apiKeyString)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("Upscaler-Bridge Server")
            } footer: {
                Text("Optional. If set, every upscale (success or failure) is logged here — source image size, technique/model used, tile config, timing. Leave the URL empty to disable logging entirely. Release builds from CI have a key baked in automatically; leave the API key field blank to use that default, or set one here to override it. See server/README.md in the repo for how to deploy one.")
            }

            Section {
                LabeledContent("Device ID", value: DeviceIdentity.current)
            } header: {
                Text("This Device")
            } footer: {
                Text("A random identifier generated once per install — there are no user accounts, so this is just how history entries are grouped per device.")
            }

            Section {
                LabeledContent("Version", value: appVersion)
                Link(destination: URL(string: "https://github.com/HeavenlyXenusVR/ImageUpscaler")!) {
                    Label("Source on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                }
            } header: {
                Text("About")
            } footer: {
                Text("Includes a Core ML conversion of Real-ESRGAN (© Xintao Wang, BSD-3-Clause). Full license text and conversion details: Models/THIRD_PARTY_NOTICES.md in the repo above.")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }
}

#Preview {
    NavigationStack { SettingsView() }
}

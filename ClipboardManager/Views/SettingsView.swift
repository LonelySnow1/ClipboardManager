import SwiftUI

struct SettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("maxHistoryCount") private var maxHistoryCount = 50

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at Login", isOn: $launchAtLogin)

                Stepper(value: $maxHistoryCount, in: 10...200, step: 10) {
                    Text("Max History: \(maxHistoryCount)")
                }
            }

            Section("Shortcut") {
                HStack {
                    Text("Show Panel")
                    Spacer()
                    Text("⌃V")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                }
            }

            Section("About") {
                Text("ClipboardManager v1.0")
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 350, height: 250)
    }
}

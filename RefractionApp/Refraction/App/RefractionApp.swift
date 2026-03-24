// RefractionApp.swift — Main entry point for the Refraction macOS app.
// Launches the Python analysis server on appear and stops it on disappear.
// Includes About dialog and crash alert handling.

import SwiftUI

@main
struct RefractionApp: App {

    @State private var appState = AppState()
    @State private var pythonServer = PythonServer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(pythonServer)
                .onAppear {
                    pythonServer.start()
                }
                .onDisappear {
                    pythonServer.stop()
                }
                .alert(
                    "Python Server Crashed",
                    isPresented: $pythonServer.showCrashAlert,
                    actions: {
                        Button("Restart Server") {
                            pythonServer.dismissCrashAlert()
                            pythonServer.stop()
                            pythonServer.start()
                        }
                        Button("Dismiss", role: .cancel) {
                            pythonServer.dismissCrashAlert()
                        }
                    },
                    message: {
                        Text(pythonServer.lastCrashMessage ?? "The analysis engine stopped unexpectedly. A crash log has been saved to ~/Library/Logs/Refraction/crash.log")
                    }
                )
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1200, height: 800)
        .commands {
            // Replace the default About menu item
            CommandGroup(replacing: .appInfo) {
                Button("About Refraction") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            .applicationName: "Refraction",
                            .applicationVersion: appVersion,
                            .version: buildVersion,
                            .credits: aboutCredits,
                        ]
                    )
                }
            }
        }
    }

    // MARK: - About Dialog

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
    }

    private var buildVersion: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private var aboutCredits: NSAttributedString {
        let text = """
        Scientific plotting and analysis for macOS.

        Built by Ashwin Pasupathy and Claude (Anthropic).
        """
        return NSAttributedString(
            string: text,
            attributes: [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor.secondaryLabelColor,
            ]
        )
    }
}

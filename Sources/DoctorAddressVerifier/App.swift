import SwiftUI

@main
struct DoctorAddressVerifierApp: App {
    var body: some Scene {
        MenuBarExtra("Doctor Address Verifier", systemImage: "stethoscope") {
            ContentView()
                .frame(minWidth: 500, minHeight: 400)
        }
        .menuBarExtraStyle(.window)
    }
}

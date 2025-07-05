// ContentView - Replace this with actual code
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var photoLibraryManager: PhotoLibraryManager
    @State private var showOnboarding = true
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if showOnboarding && photoLibraryManager.authorizationStatus != .authorized {
                OnboardingView(showOnboarding: $showOnboarding)
            } else {
                MainTabView(selectedTab: $selectedTab)
            }
        }
        .onAppear {
            if photoLibraryManager.authorizationStatus == .notDetermined {
                Task {
                    await photoLibraryManager.requestAuthorization()
                }
            }
        }
        .onChange(of: photoLibraryManager.authorizationStatus) { status in
            if status == .authorized {
                showOnboarding = false
            }
        }
    }
}
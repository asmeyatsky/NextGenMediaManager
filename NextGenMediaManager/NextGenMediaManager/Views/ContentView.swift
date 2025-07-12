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
                    .task {
                        if photoLibraryManager.mediaItems.isEmpty {
                            await photoLibraryManager.loadMediaItems()
                        }
                    }
            }
        }
        .task {
            if photoLibraryManager.authorizationStatus == .notDetermined {
                await photoLibraryManager.requestAuthorization()
            }
        }
        .onChange(of: photoLibraryManager.authorizationStatus) { _, newStatus in
            if newStatus == .authorized {
                showOnboarding = false
                Task {
                    await photoLibraryManager.loadMediaItems()
                }
            }
        }
    }
}
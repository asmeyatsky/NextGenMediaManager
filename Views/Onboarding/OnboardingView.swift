// OnboardingView - Replace this with actual code
import SwiftUI
import Photos

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @EnvironmentObject var photoLibraryManager: PhotoLibraryManager
    @State private var currentPage = 0
    
    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                // Welcome Screen
                VStack(spacing: 24) {
                    Image(systemName: "photo.stack.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Welcome to Next-Gen Media Manager")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Your intelligent photo companion")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .tag(0)
                
                // Features Screen
                VStack(spacing: 32) {
                    Text("Smart Features")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    FeatureRow(icon: "magnifyingglass.circle.fill", 
                               title: "AI-Powered Search",
                               description: "Find photos using natural language")
                    
                    FeatureRow(icon: "sparkles", 
                               title: "Smart Collections",
                               description: "Automatically organized memories")
                    
                    FeatureRow(icon: "text.viewfinder", 
                               title: "Text Recognition",
                               description: "Search text within your photos")
                }
                .padding(.horizontal)
                .tag(1)
                
                // Permission Screen
                VStack(spacing: 32) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    Text("Your Privacy Matters")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("We need access to your photos to analyze them. All processing happens on your device.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        Task {
                            await photoLibraryManager.requestAuthorization()
                            if photoLibraryManager.authorizationStatus == .authorized {
                                showOnboarding = false
                                await photoLibraryManager.loadMediaItems()
                            }
                        }
                    }) {
                        Label("Grant Access", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                }
                .tag(2)
            }
            .tabViewStyle(PageTabViewStyle())
            
            // Page Indicator
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 20)
        }
    }
}
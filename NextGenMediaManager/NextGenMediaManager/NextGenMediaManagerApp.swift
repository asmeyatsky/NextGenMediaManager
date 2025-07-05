//
//  NextGenMediaManagerApp.swift
//  NextGenMediaManager
//
//  Created by Allan Smeyatsky on 05/07/2025.
//

// In your NextGenMediaManagerApp.swift file (or similar)

// In your NextGenMediaManagerApp.swift file

import SwiftUI

@main
struct NextGenMediaManagerApp: App {
    // Existing:
    @StateObject var photoLibraryManager = PhotoLibraryManager()

    // NEW: Create an instance of your SearchManager
    @StateObject var searchManager = SearchManager() // Make sure SearchManager conforms to ObservableObject!

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(photoLibraryManager)
                // NEW: Inject the SearchManager into the environment
                .environmentObject(searchManager) // Add this line
        }
    }
}

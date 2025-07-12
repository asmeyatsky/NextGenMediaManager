// SearchView - Replace this with actual code

import SwiftUI

struct SearchView: View {
    @EnvironmentObject var searchManager: SearchManager
    @EnvironmentObject var photoLibraryManager: PhotoLibraryManager
    @State private var isVoiceSearchActive = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search photos...", text: $searchManager.searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onSubmit {
                            Task {
                                await searchManager.performSearch(query: searchManager.searchText, in: photoLibraryManager.mediaItems)
                            }
                        }
                    
                    Button(action: { isVoiceSearchActive.toggle() }) {
                        Image(systemName: "mic.fill")
                            .foregroundColor(isVoiceSearchActive ? .red : .blue)
                    }
                }
                .padding()
                
                // Search Results
                if searchManager.isSearching {
                    ProgressView("Searching...")
                        .frame(maxHeight: .infinity)
                } else if !searchManager.searchResults.isEmpty {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 100), spacing: 2)
                        ], spacing: 2) {
                            ForEach(searchManager.searchResults) { item in
                                MediaThumbnailView(mediaItem: item)
                            }
                        }
                    }
                } else if !searchManager.searchText.isEmpty {
                    Text("No results found")
                        .foregroundColor(.secondary)
                        .frame(maxHeight: .infinity)
                } else {
                    // Search suggestions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Try searching for:")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(["Beach photos", "Family gatherings", "Text in photos", "Sunset pictures"], id: \.self) { suggestion in
                            Button(action: {
                                searchManager.searchText = suggestion
                                Task {
                                    await searchManager.performSearch(query: suggestion, in: photoLibraryManager.mediaItems)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                    Text(suggestion)
                                    Spacer()
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer()
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Search")
            .onChange(of: searchManager.searchText) { _, newValue in
                // Debounce search to avoid too many requests
                Task {
                    try? await Task.sleep(nanoseconds: 300_000_000) // 300ms delay
                    if searchManager.searchText == newValue {
                        if !newValue.isEmpty && newValue.count > 2 {
                            await searchManager.performSearch(query: newValue, in: photoLibraryManager.mediaItems)
                        } else if newValue.isEmpty {
                            await MainActor.run {
                                searchManager.searchResults = []
                            }
                        }
                    }
                }
            }
        }
    }
}
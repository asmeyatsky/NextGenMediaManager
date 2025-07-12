import SwiftUI
import Photos
import PhotosUI

struct TimelineView: View {
    @EnvironmentObject var photoLibraryManager: PhotoLibraryManager
    @State private var selectedTimeRange = TimeRange.all
    @State private var showingPhotosPicker = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                if photoLibraryManager.isProcessing {
                    ProcessingView(progress: photoLibraryManager.processingProgress)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 100), spacing: 2)
                    ], spacing: 2) {
                        ForEach(filteredMediaItems) { item in
                            MediaThumbnailView(mediaItem: item)
                        }
                    }
                }
            }
            .navigationTitle("Timeline")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button {
                            showingPhotosPicker = true
                        } label: {
                            Label("From Photo Library", systemImage: "photo.on.rectangle")
                        }
                        
                        Button {
                            photoLibraryManager.showingDocumentPicker = true
                        } label: {
                            Label("From Files", systemImage: "folder")
                        }
                    } label: {
                        Label("Add Photos", systemImage: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Button(range.rawValue) {
                                selectedTimeRange = range
                            }
                        }
                    } label: {
                        Label(selectedTimeRange.rawValue, systemImage: "calendar")
                    }
                }
            }
            .onChange(of: photoLibraryManager.selectedPhotoItems) { _, newItems in
                if !newItems.isEmpty {
                    Task {
                        await photoLibraryManager.loadSelectedPhotos()
                    }
                }
            }
            .photosPicker(
                isPresented: $showingPhotosPicker,
                selection: $photoLibraryManager.selectedPhotoItems,
                maxSelectionCount: nil,
                matching: .any(of: [.images, .videos])
            )
            .sheet(isPresented: $photoLibraryManager.showingDocumentPicker) {
                DocumentPicker(isPresented: $photoLibraryManager.showingDocumentPicker) { urls in
                    Task {
                        await photoLibraryManager.importFiles(urls: urls)
                    }
                }
            }
        }
    }
    
    var filteredMediaItems: [MediaItem] {
        let now = Date()
        let calendar = Calendar.current
        
        switch selectedTimeRange {
        case .all:
            return photoLibraryManager.mediaItems
        case .today:
            return photoLibraryManager.mediaItems.filter { item in
                let itemDate = item.asset?.creationDate ?? item.createdDate ?? Date.distantPast
                return calendar.isDate(itemDate, inSameDayAs: now)
            }
        case .week:
            return photoLibraryManager.mediaItems.filter { item in
                let itemDate = item.asset?.creationDate ?? item.createdDate ?? Date.distantPast
                let weekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? Date.distantPast
                return itemDate >= weekAgo
            }
        case .month:
            return photoLibraryManager.mediaItems.filter { item in
                let itemDate = item.asset?.creationDate ?? item.createdDate ?? Date.distantPast
                let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? Date.distantPast
                return itemDate >= monthAgo
            }
        case .year:
            return photoLibraryManager.mediaItems.filter { item in
                let itemDate = item.asset?.creationDate ?? item.createdDate ?? Date.distantPast
                let yearAgo = calendar.date(byAdding: .year, value: -1, to: now) ?? Date.distantPast
                return itemDate >= yearAgo
            }
        }
    }
}
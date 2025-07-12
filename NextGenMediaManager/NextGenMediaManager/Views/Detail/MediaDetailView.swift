import SwiftUI
import Photos

struct MediaDetailView: View {
    let mediaItem: MediaItem
    @EnvironmentObject var photoLibraryManager: PhotoLibraryManager
    @State private var fullSizeImage: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView([.horizontal, .vertical]) {
                VStack {
                    if isLoading {
                        ProgressView("Loading...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let image = fullSizeImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: max(geometry.size.width, 1), maxHeight: max(geometry.size.height, 1))
                            .clipped()
                    } else {
                        Text("Unable to load image")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                    // Media information
                    VStack(alignment: .leading, spacing: 12) {
                        if let asset = mediaItem.asset {
                            Text("Created: \(asset.creationDate?.formatted() ?? "Unknown")")
                            Text("Size: \(asset.pixelWidth) × \(asset.pixelHeight)")
                            Text("Type: \(asset.mediaType == .video ? "Video" : "Image")")
                            if let location = asset.location {
                                Text("Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                            }
                        } else if let fileURL = mediaItem.fileURL {
                            Text("File: \(fileURL.lastPathComponent)")
                            if let createdDate = mediaItem.createdDate {
                                Text("Created: \(createdDate.formatted())")
                            }
                            if let fileSize = mediaItem.fileSize {
                                Text("Size: \(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))")
                            }
                        }
                        
                        if !mediaItem.tags.isEmpty {
                            Text("Tags: \(mediaItem.tags.joined(separator: ", "))")
                        }
                        
                        if !mediaItem.people.isEmpty {
                            Text("People: \(mediaItem.people.joined(separator: ", "))")
                        }
                        
                        if !mediaItem.textContent.isEmpty {
                            Text("Text Content: \(mediaItem.textContent)")
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .navigationTitle(mediaItem.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadFullSizeImage()
        }
    }
    
    private func loadFullSizeImage() {
        Task {
            if let asset = mediaItem.asset {
                let image = await loadFullSizeImage(from: asset)
                await MainActor.run {
                    self.fullSizeImage = image ?? mediaItem.thumbnail
                    self.isLoading = false
                }
            } else if let fileURL = mediaItem.fileURL {
                let image = UIImage(contentsOfFile: fileURL.path)
                await MainActor.run {
                    self.fullSizeImage = image ?? mediaItem.thumbnail
                    self.isLoading = false
                }
            } else {
                await MainActor.run {
                    self.fullSizeImage = mediaItem.thumbnail
                    self.isLoading = false
                }
            }
        }
    }
    
    private func loadFullSizeImage(from asset: PHAsset) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            let requestOptions = PHImageRequestOptions()
            requestOptions.deliveryMode = .highQualityFormat
            requestOptions.isNetworkAccessAllowed = true
            requestOptions.isSynchronous = false
            
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: requestOptions
            ) { image, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    print("Full size image request error: \(error)")
                    continuation.resume(returning: nil)
                } else if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool,
                          !isDegraded {
                    continuation.resume(returning: image)
                } else if info?[PHImageResultIsDegradedKey] == nil {
                    continuation.resume(returning: image)
                }
            }
        }
    }
}
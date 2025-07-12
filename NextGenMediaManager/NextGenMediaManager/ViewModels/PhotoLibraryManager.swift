import SwiftUI
import Photos
import Combine
import PhotosUI
import UniformTypeIdentifiers
import AVFoundation

class PhotoLibraryManager: ObservableObject {
    @Published var mediaItems: [MediaItem] = []
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    @Published var selectedPhotoItems: [PhotosPickerItem] = []
    @Published var showingDocumentPicker = false
    
    private let imageManager = PHImageManager.default()
    private let thumbnailSize = CGSize(width: 300, height: 300)
    
    init() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    func requestAuthorization() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        await MainActor.run {
            self.authorizationStatus = status
        }
    }
    
    func loadSelectedPhotos() async {
        await MainActor.run {
            isProcessing = true
            processingProgress = 0.0
        }
        
        let items: [MediaItem] = await withCheckedContinuation { continuation in
            var newItems: [MediaItem] = []
            let itemsToProcess = selectedPhotoItems
            
            Task {
                for (index, item) in itemsToProcess.enumerated() {
                    if let asset = await loadAssetFromPhotoPickerItem(item) {
                        let mediaItem = MediaItem(asset: asset)
                        newItems.append(mediaItem)
                    }
                    
                    await MainActor.run {
                        self.processingProgress = Double(index + 1) / Double(itemsToProcess.count)
                    }
                }
                continuation.resume(returning: newItems)
            }
        }
        
        await MainActor.run {
            self.mediaItems.append(contentsOf: items)
            self.selectedPhotoItems = []
            self.isProcessing = false
        }
    }
    
    private func loadAssetFromPhotoPickerItem(_ item: PhotosPickerItem) async -> PHAsset? {
        guard let identifier = item.itemIdentifier else { return nil }
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        return fetchResult.firstObject
    }
    
    func importFiles(urls: [URL]) async {
        await MainActor.run {
            isProcessing = true
            processingProgress = 0.0
        }
        
        var importedItems: [MediaItem] = []
        
        for (index, url) in urls.enumerated() {
            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                continue
            }
            defer { url.stopAccessingSecurityScopedResource() }
            
            // Check if it's an image or video file
            if isMediaFile(url) {
                let thumbnail = await generateThumbnail(for: url)
                let mediaItem = MediaItem(fileURL: url, thumbnail: thumbnail)
                importedItems.append(mediaItem)
            }
            
            await MainActor.run {
                self.processingProgress = Double(index + 1) / Double(urls.count)
            }
        }
        
        await MainActor.run {
            self.mediaItems.append(contentsOf: importedItems)
            self.isProcessing = false
        }
    }
    
    private func isMediaFile(_ url: URL) -> Bool {
        let pathExtension = url.pathExtension.lowercased()
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "webp"]
        let videoExtensions = ["mp4", "mov", "avi", "mkv", "m4v", "wmv", "flv"]
        
        return imageExtensions.contains(pathExtension) || videoExtensions.contains(pathExtension)
    }
    
    private func generateThumbnail(for url: URL) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .background).async {
                var thumbnail: UIImage?
                
                let pathExtension = url.pathExtension.lowercased()
                let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "webp"]
                
                if imageExtensions.contains(pathExtension) {
                    // Generate image thumbnail
                    if let image = UIImage(contentsOfFile: url.path) {
                        thumbnail = self.resizeImage(image, to: self.thumbnailSize)
                    }
                } else {
                    // Generate video thumbnail
                    thumbnail = self.generateVideoThumbnail(for: url)
                }
                
                continuation.resume(returning: thumbnail)
            }
        }
    }
    
    private func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage? {
        // Validate size to prevent NaN issues
        let validSize = CGSize(
            width: size.width.isFinite && size.width > 0 ? size.width : 100,
            height: size.height.isFinite && size.height > 0 ? size.height : 100
        )
        
        UIGraphicsBeginImageContextWithOptions(validSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: validSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    private func generateVideoThumbnail(for url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let semaphore = DispatchSemaphore(value: 0)
        var resultImage: UIImage?
        
        imageGenerator.generateCGImageAsynchronously(for: .zero) { cgImage, _, _ in
            if let cgImage = cgImage {
                let thumbnail = UIImage(cgImage: cgImage)
                resultImage = self.resizeImage(thumbnail, to: self.thumbnailSize)
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        return resultImage
    }
    
    func loadMediaItems() async {
        if authorizationStatus != .authorized {
            await requestAuthorization()
        }
        
        guard authorizationStatus == .authorized else { 
            return 
        }
        
        await MainActor.run {
            isProcessing = true
            processingProgress = 0.0
        }
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.includeAssetSourceTypes = [.typeUserLibrary, .typeCloudShared]
        fetchOptions.fetchLimit = 100 // Limit initial load to prevent memory issues
        
        let assets = PHAsset.fetchAssets(with: fetchOptions)
        let totalCount = assets.count
        
        let items: [MediaItem] = await withCheckedContinuation { continuation in
            var mediaItems: [MediaItem] = []
            let dispatchGroup = DispatchGroup()
            
            assets.enumerateObjects { asset, index, _ in
                // Skip assets that don't have valid resources
                guard asset.mediaType == .image || asset.mediaType == .video else {
                    Task { @MainActor in
                        let progress = totalCount > 0 ? Double(index + 1) / Double(totalCount) : 0.0
                        self.processingProgress = progress.isFinite ? progress : 0.0
                    }
                    return
                }
                
                dispatchGroup.enter()
                
                var mediaItem = MediaItem(
                    asset: asset,
                    location: asset.location
                )
                
                let requestOptions = PHImageRequestOptions()
                requestOptions.deliveryMode = .opportunistic
                requestOptions.resizeMode = .fast
                requestOptions.isNetworkAccessAllowed = true
                requestOptions.isSynchronous = false
                
                self.imageManager.requestImage(
                    for: asset,
                    targetSize: self.thumbnailSize,
                    contentMode: .aspectFill,
                    options: requestOptions
                ) { image, info in
                    // Check for errors and degraded images
                    if let error = info?[PHImageErrorKey] as? Error {
                        print("Image request error for asset \(asset.localIdentifier): \(error)")
                        // Still add the item but without thumbnail
                        mediaItem.thumbnail = nil
                    } else if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool,
                              !isDegraded,
                              let image = image {
                        // Only use high quality images
                        mediaItem.thumbnail = image
                    }
                    
                    mediaItems.append(mediaItem)
                    
                    Task { @MainActor in
                        let progress = totalCount > 0 ? Double(index + 1) / Double(totalCount) : 0.0
                        self.processingProgress = progress.isFinite ? progress : 0.0
                    }
                    
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .global()) {
                mediaItems.sort { 
                    let date1 = $0.asset?.creationDate ?? $0.createdDate ?? Date.distantPast
                    let date2 = $1.asset?.creationDate ?? $1.createdDate ?? Date.distantPast
                    return date1 > date2
                }
                continuation.resume(returning: mediaItems)
            }
        }
        
        await MainActor.run {
            self.mediaItems = items
            self.isProcessing = false
            self.processingProgress = 1.0
        }
    }
    
    func loadThumbnail(for asset: PHAsset) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            let requestOptions = PHImageRequestOptions()
            requestOptions.deliveryMode = .opportunistic
            requestOptions.isNetworkAccessAllowed = true
            requestOptions.isSynchronous = false
            
            imageManager.requestImage(
                for: asset,
                targetSize: thumbnailSize,
                contentMode: .aspectFill,
                options: requestOptions
            ) { image, info in
                // Check for errors
                if let error = info?[PHImageErrorKey] as? Error {
                    print("Thumbnail request error for asset \(asset.localIdentifier): \(error)")
                    continuation.resume(returning: nil)
                } else if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool,
                          !isDegraded {
                    continuation.resume(returning: image)
                } else if info?[PHImageResultIsDegradedKey] == nil {
                    // No degradation info means it's the final result
                    continuation.resume(returning: image)
                }
                // Don't resume for degraded images - wait for better quality
            }
        }
    }
}
import Foundation
import Photos
import CoreLocation
import UIKit
import UniformTypeIdentifiers

struct MediaItem: Identifiable {
    let id = UUID()
    let asset: PHAsset?
    let fileURL: URL?
    var thumbnail: UIImage?
    var tags: Set<String> = []
    var people: [String] = []
    var location: CLLocation?
    var textContent: String = ""
    var dominantColors: [UIColor] = []
    var scene: String = ""
    var eventType: String = ""
    var fileName: String?
    var fileSize: Int64?
    var createdDate: Date?
    
    // iOS Photos framework initializer
    init(asset: PHAsset, location: CLLocation? = nil) {
        self.asset = asset
        self.fileURL = nil
        self.location = location ?? asset.location
        self.fileName = nil
        self.fileSize = nil
        self.createdDate = asset.creationDate
        
        // Add some default searchable content for demo purposes
        if asset.mediaType == .video {
            self.tags = ["video", "movie", "clip"]
            self.eventType = "Video"
        } else {
            self.tags = ["photo", "image", "picture"]
            self.eventType = "Photo"
        }
        
        // Add some demo content based on creation date for searchability
        if let date = asset.creationDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM"
            let month = formatter.string(from: date)
            self.tags.insert(month.lowercased())
            
            formatter.dateFormat = "yyyy"
            let year = formatter.string(from: date)
            self.tags.insert(year)
        }
    }
    
    // File URL initializer for local files
    init(fileURL: URL, thumbnail: UIImage? = nil) {
        self.asset = nil
        self.fileURL = fileURL
        self.thumbnail = thumbnail
        self.fileName = fileURL.lastPathComponent
        
        // Get file attributes
        if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path) {
            self.fileSize = attributes[.size] as? Int64
            self.createdDate = attributes[.creationDate] as? Date
        } else {
            self.fileSize = nil
            self.createdDate = nil
        }
        
        // Add searchable content based on file type
        let pathExtension = fileURL.pathExtension.lowercased()
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "webp"]
        let videoExtensions = ["mp4", "mov", "avi", "mkv", "m4v", "wmv", "flv"]
        
        if imageExtensions.contains(pathExtension) {
            self.tags = ["photo", "image", "picture", "file", pathExtension]
            self.eventType = "Imported Photo"
        } else if videoExtensions.contains(pathExtension) {
            self.tags = ["video", "movie", "clip", "file", pathExtension]
            self.eventType = "Imported Video"
        } else {
            self.tags = ["file", pathExtension]
            self.eventType = "Imported File"
        }
        
        // Add filename without extension as searchable content
        let nameWithoutExtension = fileURL.deletingPathExtension().lastPathComponent
        self.tags.insert(nameWithoutExtension.lowercased())
    }
    
    var isVideo: Bool {
        if let asset = asset {
            return asset.mediaType == .video
        } else if let fileURL = fileURL {
            let pathExtension = fileURL.pathExtension.lowercased()
            return ["mp4", "mov", "avi", "mkv", "m4v"].contains(pathExtension)
        }
        return false
    }
    
    var displayName: String {
        return fileName ?? "Photo \(id.uuidString.prefix(8))"
    }
}


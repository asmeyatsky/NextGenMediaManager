// SmartCollection Model - Replace this with actual code
import Foundation
import UIKit

struct SmartCollection: Identifiable {
    let id = UUID()
    let name: String
    let coverImage: UIImage?
    let mediaItems: [MediaItem]
    let aiGeneratedTheme: String
}
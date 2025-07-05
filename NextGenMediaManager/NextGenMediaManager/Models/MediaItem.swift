// MediaItem Model - Replace this with actual code
import Foundation
import Photos
import CoreLocation
import UIKit

struct MediaItem: Identifiable {
    let id = UUID()
    let asset: PHAsset
    var thumbnail: UIImage?
    var tags: Set<String> = []
    var people: [String] = []
    var location: CLLocation?
    var textContent: String = ""
    var dominantColors: [UIColor] = []
    var scene: String = ""
    var eventType: String = ""
}
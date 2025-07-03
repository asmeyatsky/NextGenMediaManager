// MediaThumbnailView - Replace this with actual code
import SwiftUI
import Photos

struct MediaThumbnailView: View {
    let mediaItem: MediaItem
    @State private var thumbnail: UIImage?
    
    var body: some View {
        ZStack {
            if let image = thumbnail {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.5)
                    )
            }
            
            // Overlay for video indicator
            if mediaItem.asset.mediaType == .video {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .shadow(radius: 2)
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        
        PHImageManager.default().requestImage(
            for: mediaItem.asset,
            targetSize: CGSize(width: 200, height: 200),
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            self.thumbnail = image
        }
    }
}

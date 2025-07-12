import SwiftUI
import Photos

struct MediaThumbnailView: View {
    let mediaItem: MediaItem
    @EnvironmentObject var photoLibraryManager: PhotoLibraryManager
    @State private var thumbnail: UIImage?
    
    var body: some View {
        NavigationLink(destination: MediaDetailView(mediaItem: mediaItem)) {
            ZStack {
            if let image = thumbnail ?? mediaItem.thumbnail {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipped()
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.5)
                    )
            }
            
            // Overlay for video indicator
            if mediaItem.isVideo {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                            .padding(8)
                    }
                }
            }
        }
        }
        .onAppear {
            if thumbnail == nil && mediaItem.thumbnail == nil {
                loadThumbnail()
            }
        }
    }
    
    private func loadThumbnail() {
        Task {
            if let asset = mediaItem.asset {
                let image = await photoLibraryManager.loadThumbnail(for: asset)
                await MainActor.run {
                    self.thumbnail = image
                }
            }
            // For file-based media items, thumbnail is already loaded during import
        }
    }
}

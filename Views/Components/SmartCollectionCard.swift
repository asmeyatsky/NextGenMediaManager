// SmartCollectionCard - Replace this with actual code
import SwiftUI

struct SmartCollectionCard: View {
    let collection: SmartCollection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Cover image
            if let coverImage = collection.coverImage {
                Image(uiImage: coverImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
                    .clipped()
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 120)
            }
            
            Text(collection.name)
                .font(.headline)
                .lineLimit(1)
            
            Text("\(collection.mediaItems.count) items")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
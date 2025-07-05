// ProcessingView - Replace this with actual code
import SwiftUI

struct ProcessingView: View {
    let progress: Double
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
                .padding(.horizontal, 40)
            
            Text("Processing your photos...")
                .font(.headline)
            
            Text("\(Int(progress * 100))% complete")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 100)
    }
}

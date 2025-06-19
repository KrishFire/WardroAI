import SwiftUI

struct AsyncImageView: View {
    let url: String?
    let width: CGFloat?
    let height: CGFloat?
    let cornerRadius: CGFloat
    
    init(url: String?, width: CGFloat? = nil, height: CGFloat? = nil, cornerRadius: CGFloat = 8) {
        self.url = url
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        AsyncImage(url: URL(string: url ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                        .font(.title2)
                )
        }
        .frame(width: width, height: height)
        .clipped()
        .cornerRadius(cornerRadius)
    }
}

#Preview {
    AsyncImageView(url: nil, width: 150, height: 150)
} 
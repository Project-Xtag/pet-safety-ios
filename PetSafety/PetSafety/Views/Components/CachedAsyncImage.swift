import SwiftUI

/// A drop-in replacement for AsyncImage that uses a shared URLCache
/// for persistent image caching (50MB memory / 100MB disk).
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var image: Image?

    private static var cache: URLCache {
        URLCache(memoryCapacity: 50 * 1024 * 1024, diskCapacity: 100 * 1024 * 1024)
    }

    private static var session: URLSession {
        let config = URLSessionConfiguration.default
        config.urlCache = cache
        config.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: config)
    }

    var body: some View {
        Group {
            if let image = image {
                content(image)
            } else {
                placeholder()
                    .task(id: url) {
                        await loadImage()
                    }
            }
        }
    }

    private func loadImage() async {
        guard let url = url else { return }
        do {
            let (data, _) = try await Self.session.data(from: url)
            if let uiImage = UIImage(data: data) {
                self.image = Image(uiImage: uiImage)
            }
        } catch {
            // Image load failed — placeholder stays visible
        }
    }
}

// Convenience initializer matching AsyncImage API
extension CachedAsyncImage where Placeholder == ProgressView<EmptyView, EmptyView> {
    init(url: URL?, @ViewBuilder content: @escaping (Image) -> Content) {
        self.url = url
        self.content = content
        self.placeholder = { ProgressView() }
    }
}

//
//  LinkPreviewCache.swift
//  Espaste
//

import AppKit
import Combine
import LinkPresentation

class LinkPreviewCache: ObservableObject {
    static let shared = LinkPreviewCache()

    @Published private(set) var images: [String: NSImage] = [:]
    private var inFlight: Set<String> = []

    private init() {}

    // Trigger a fetch for `urlString`; result lands in `images[domain]`.
    func fetch(for urlString: String) {
        guard let url = canonicalURL(urlString) else { return }
        let key = domain(from: url)
        guard images[key] == nil, !inFlight.contains(key) else { return }
        inFlight.insert(key)

        let provider = LPMetadataProvider()
        provider.timeout = 10
        provider.startFetchingMetadata(for: url) { [weak self] metadata, _ in
            guard let self else { return }
            guard let imageProvider = metadata?.imageProvider else {
                DispatchQueue.main.async { self.inFlight.remove(key) }
                return
            }
            imageProvider.loadObject(ofClass: NSImage.self) { object, _ in
                DispatchQueue.main.async {
                    self.inFlight.remove(key)
                    if let image = object as? NSImage {
                        self.images[key] = image
                    }
                }
            }
        }
    }

    func image(for urlString: String) -> NSImage? {
        guard let url = canonicalURL(urlString) else { return nil }
        return images[domain(from: url)]
    }

    // MARK: - Helpers

    static func mainDomain(from urlString: String) -> String? {
        guard let url = canonicalURL(urlString) else { return nil }
        return domain(from: url)
    }

    private static func canonicalURL(_ string: String) -> URL? {
        // Bare domains like "github.com" need a scheme for URLComponents to parse correctly.
        let s = string.contains("://") ? string : "https://\(string)"
        return URL(string: s)
    }

    private static func domain(from url: URL) -> String {
        var host = url.host ?? url.absoluteString
        if host.hasPrefix("www.") { host = String(host.dropFirst(4)) }
        return host
    }

    // Instance wrappers
    private func canonicalURL(_ string: String) -> URL? { Self.canonicalURL(string) }
    private func domain(from url: URL) -> String { Self.domain(from: url) }
}

//
//  LinkPreviewCache.swift
//  Espaste
//
//  Caches website previews. Following Apple's recommended approach, the whole
//  LPLinkMetadata (NSSecureCoding) is archived to disk with NSKeyedArchiver,
//  keyed by the full URL — so per-page content (YouTube videos, GitHub repos)
//  keeps its own preview instead of collapsing per domain.
//

import AppKit
import Combine
import CryptoKit
import LinkPresentation

class LinkPreviewCache: ObservableObject {
    static let shared = LinkPreviewCache()

    // Keyed by the full canonical URL string.
    @Published private(set) var images: [String: NSImage] = [:]
    private var inFlight: Set<String> = []
    private var missing: Set<String> = []   // tried, but no image available

    private let cacheDir: URL = documentsDirectory.appendingPathComponent("LinkPreviews")
    private let ioQueue = DispatchQueue(label: "com.espaste.linkpreview.io", attributes: .concurrent)

    private init() {
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    // Trigger a fetch for `urlString`; result lands in `images[url]`.
    // State (`images`/`inFlight`/`missing`) is only ever touched on the main thread;
    // disk and network work is offloaded.
    func fetch(for urlString: String) {
        guard let url = canonicalURL(urlString) else { return }
        let key = url.absoluteString
        guard images[key] == nil, !inFlight.contains(key), !missing.contains(key) else { return }
        inFlight.insert(key)

        // Disk first (archived metadata), then network.
        ioQueue.async { [weak self] in
            guard let self else { return }
            if let metadata = self.loadMetadata(key) {
                self.extractImage(from: metadata, key: key)
            } else {
                DispatchQueue.main.async { self.fetchFromNetwork(url: url, key: key) }
            }
        }
    }

    func image(for urlString: String) -> NSImage? {
        guard let url = canonicalURL(urlString) else { return nil }
        return images[url.absoluteString]
    }

    // Drops the cached preview (memory + disk) for a URL. Call on the main thread.
    func purge(for urlString: String) {
        guard let url = canonicalURL(urlString) else { return }
        let key = url.absoluteString
        images.removeValue(forKey: key)
        missing.remove(key)
        let file = fileURL(key)
        ioQueue.async(flags: .barrier) {
            try? FileManager.default.removeItem(at: file)
        }
    }

    // MARK: - Network

    private func fetchFromNetwork(url: URL, key: String) {
        let provider = LPMetadataProvider()
        provider.timeout = 10
        provider.startFetchingMetadata(for: url) { [weak self] metadata, _ in
            guard let self else { return }
            guard let metadata else {
                DispatchQueue.main.async {
                    self.inFlight.remove(key)
                    self.missing.insert(key)
                }
                return
            }
            self.saveMetadata(metadata, key: key)
            self.extractImage(from: metadata, key: key)
        }
    }

    private func extractImage(from metadata: LPLinkMetadata, key: String) {
        guard let imageProvider = metadata.imageProvider else {
            DispatchQueue.main.async {
                self.inFlight.remove(key)
                self.missing.insert(key)
            }
            return
        }
        imageProvider.loadObject(ofClass: NSImage.self) { [weak self] object, _ in
            guard let self else { return }
            DispatchQueue.main.async {
                self.inFlight.remove(key)
                if let image = object as? NSImage {
                    self.images[key] = image
                } else {
                    self.missing.insert(key)
                }
            }
        }
    }

    // MARK: - Disk (archived LPLinkMetadata)

    private func fileURL(_ key: String) -> URL {
        // SHA256 → stable, fixed-length, filesystem-safe name.
        let digest = SHA256.hash(data: Data(key.utf8))
        let name = digest.map { String(format: "%02x", $0) }.joined()
        return cacheDir.appendingPathComponent("\(name).lpmeta")
    }

    private func loadMetadata(_ key: String) -> LPLinkMetadata? {
        guard let data = try? Data(contentsOf: fileURL(key)) else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: LPLinkMetadata.self, from: data)
    }

    private func saveMetadata(_ metadata: LPLinkMetadata, key: String) {
        let url = fileURL(key)
        ioQueue.async(flags: .barrier) {
            guard let data = try? NSKeyedArchiver.archivedData(
                withRootObject: metadata,
                requiringSecureCoding: true
            ) else { return }
            try? data.write(to: url)
        }
    }

    // MARK: - URL helpers

    static func mainDomain(from urlString: String) -> String? {
        guard let url = canonicalURL(urlString) else { return nil }
        var host = url.host ?? url.absoluteString
        if host.hasPrefix("www.") { host = String(host.dropFirst(4)) }
        return host
    }

    private static func canonicalURL(_ string: String) -> URL? {
        // Bare domains like "github.com" need a scheme to parse correctly.
        let s = string.contains("://") ? string : "https://\(string)"
        return URL(string: s)
    }

    private func canonicalURL(_ string: String) -> URL? { Self.canonicalURL(string) }
}

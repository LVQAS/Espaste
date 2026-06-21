//
//  ClipboardItem.swift
//  Espaste
//

import Foundation

struct ClipboardItem: Identifiable, Codable {
    enum ContentType: String, Codable {
        case text
        case url
    }

    var id: UUID
    var text: String
    var timestamp: Date
    var appBundleID: String?
    var appName: String?
    var isFavorite: Bool
    var contentType: ContentType

    // Custom decoder so existing persisted items (no contentType key) default to .text
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(UUID.self,        forKey: .id)
        text        = try c.decode(String.self,      forKey: .text)
        timestamp   = try c.decode(Date.self,        forKey: .timestamp)
        appBundleID = try c.decodeIfPresent(String.self, forKey: .appBundleID)
        appName     = try c.decodeIfPresent(String.self, forKey: .appName)
        isFavorite  = try c.decode(Bool.self,        forKey: .isFavorite)
        contentType = try c.decodeIfPresent(ContentType.self, forKey: .contentType) ?? .text
    }

    init(id: UUID = UUID(), text: String, timestamp: Date,
         appBundleID: String?, appName: String?,
         isFavorite: Bool, contentType: ContentType) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.appBundleID = appBundleID
        self.appName = appName
        self.isFavorite = isFavorite
        self.contentType = contentType
    }
}

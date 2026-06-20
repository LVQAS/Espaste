//
//  ClipboardItem.swift
//  Espaste
//

import Foundation

struct ClipboardItem: Identifiable, Codable {
    var id: UUID
    var text: String
    var timestamp: Date
    var appBundleID: String?
    var appName: String?
    var isFavorite: Bool
}

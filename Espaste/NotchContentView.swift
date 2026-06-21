//
//  NotchContentView.swift
//  Espaste
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct NotchContentView: View {
    @StateObject var vm: NotchViewModel

    var body: some View {
        ZStack {
            switch vm.contentType {
            case .normal:
                ClipboardView(vm: vm)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            case .menu:
                NotchMenuView(vm: vm)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            case .settings:
                NotchSettingsView(vm: vm)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .animation(vm.animation, value: vm.contentType)
    }
}

// MARK: - ClipboardView

private struct ClipboardView: View {
    @StateObject var vm: NotchViewModel
    @ObservedObject private var store = ClipboardStore.shared
    @State private var searchText = ""
    @State private var selectedFilter: FilterType = .all
    @State private var selectedIDs: Set<UUID> = []

    enum FilterType { case favorites, apps, clipboard, all }

    private var isSelecting: Bool { !selectedIDs.isEmpty }

    var filteredItems: [ClipboardItem] {
        var result = store.items
        if selectedFilter == .favorites { result = result.filter { $0.isFavorite } }
        if !searchText.isEmpty {
            result = result.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
        }
        return result
    }

    private func toggleSelection(_ item: ClipboardItem) {
        if selectedIDs.contains(item.id) {
            selectedIDs.remove(item.id)
        } else {
            selectedIDs.insert(item.id)
        }
    }

    private func copySelected() {
        let items = filteredItems.filter { selectedIDs.contains($0.id) }
        store.copyToClipboard(items)
        selectedIDs.removeAll()
    }

    private func deleteSelected() {
        store.delete(ids: selectedIDs)
        selectedIDs.removeAll()
    }

    var body: some View {
        VStack(spacing: 0) {
            if isSelecting {
                selectionBar
            } else {
                searchBar
            }
            Divider().opacity(0.2)
            filterRow
            Divider().opacity(0.2)
            if filteredItems.isEmpty {
                emptyState
            } else {
                itemList
            }
        }
        .background(.black)
        .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius))
    }

    var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 13))
            TextField("Search", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
            }
            Button {
                vm.contentType = .menu
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
    }

    var selectionBar: some View {
        HStack(spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) { selectedIDs.removeAll() }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Text("\(selectedIDs.count) selected")
                .font(.system(size: 13, weight: .medium))

            Spacer()

            Button { copySelected() } label: {
                Image(systemName: "square.on.square")
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 26)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.easeInOut(duration: 0.15)) { deleteSelected() }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 26)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
    }

    var filterRow: some View {
        HStack(spacing: 6) {
            FilterChip(icon: "star.fill", isSelected: selectedFilter == .favorites) {
                selectedFilter = selectedFilter == .favorites ? .all : .favorites
            }
            FilterChip(icon: "square.grid.2x2", isSelected: selectedFilter == .apps) {
                selectedFilter = selectedFilter == .apps ? .all : .apps
            }
            FilterChip(icon: "doc.on.clipboard", isSelected: selectedFilter == .clipboard) {
                selectedFilter = selectedFilter == .clipboard ? .all : .clipboard
            }

            Button { selectedFilter = .all } label: {
                Text("All")
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(selectedFilter == .all ? Color.white : Color.white.opacity(0.1))
                    .foregroundStyle(selectedFilter == .all ? Color.black : Color.white)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
    }

    var itemList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 8) {
                ForEach(filteredItems) { item in
                    ClipboardItemCard(
                        item: item,
                        isSelecting: isSelecting,
                        isSelected: selectedIDs.contains(item.id),
                        onTap: { store.copyToClipboard(item) },
                        onToggleSelect: {
                            withAnimation(.easeInOut(duration: 0.15)) { toggleSelection(item) }
                        },
                        onFavorite: { store.toggleFavorite(item) },
                        onDelete: { store.delete(item) },
                        dragItems: {
                            if isSelecting, selectedIDs.contains(item.id) {
                                return filteredItems.filter { selectedIDs.contains($0.id) }
                            }
                            return [item]
                        }
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .frame(height: 132)
    }

    var emptyState: some View {
        VStack(spacing: 5) {
            Image(systemName: "doc.on.doc")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(.secondary)
            Text("Nothing here yet")
                .font(.system(size: 13, weight: .semibold))
            Text("Copy anything — it shows up here.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

// MARK: - ClipboardItemCard

private struct ClipboardItemCard: View {
    let item: ClipboardItem
    var isSelecting: Bool = false
    var isSelected: Bool = false
    let onTap: () -> Void
    var onToggleSelect: () -> Void = {}
    let onFavorite: () -> Void
    let onDelete: () -> Void
    var dragItems: () -> [ClipboardItem] = { [] }

    @State private var isHovered = false
    @State private var showCopied = false

    private var topRowVisible: Bool { isHovered || isSelecting || showCopied }

    private func handleTap() {
        onTap()
        showCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showCopied = false
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                if showCopied {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Copied")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Capsule())
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                } else {
                    SelectionButton(
                        isSelecting: isSelecting,
                        isSelected: isSelected,
                        action: onToggleSelect
                    )
                }
                Spacer()
                if !isSelecting && !showCopied {
                    CardActionButton(icon: "trash", tint: .red, action: onDelete)
                    CardActionButton(
                        icon: item.isFavorite ? "star.fill" : "star",
                        tint: .yellow,
                        isActive: item.isFavorite,
                        action: onFavorite
                    )
                }
            }
            .padding(.horizontal, 6)
            .padding(.top, 5)
            .padding(.bottom, 2)
            .opacity(topRowVisible ? 1 : 0)
            .animation(.easeInOut(duration: 0.15), value: showCopied)

            Divider().opacity(0.12)

            Text(item.text)
                .font(.system(size: 12))
                .foregroundStyle(.primary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
                .onTapGesture { isSelecting ? onToggleSelect() : handleTap() }

            Divider().opacity(0.12)

            HStack(spacing: 4) {
                appIcon
                if let name = item.appName {
                    Text(name)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                TimelineView(.periodic(from: .now, by: 60)) { _ in
                    Text(relativeLabel(item.timestamp))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .frame(width: 160, height: 112)
        .background(Color(red: 31/255, green: 31/255, blue: 31/255))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    isSelected
                        ? Color.white.opacity(0.6)
                        : Color.white.opacity(isHovered ? 0.4 : 0),
                    lineWidth: isSelected ? 1 : 0.5
                )
        )
        .scaleEffect(isHovered ? 1.04 : 1.0)
        .onHover { isHovered = $0 }
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
        .onDrag {
            let items = dragItems()
            return ClipboardDrag.itemProvider(for: items.isEmpty ? [item] : items)
        }
        .contextMenu {
            Button {
                onFavorite()
            } label: {
                Label(
                    item.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                    systemImage: item.isFavorite ? "star.slash" : "star"
                )
            }
            Button {
                ClipboardStore.shared.copyToClipboard(item)
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            Divider()
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func relativeLabel(_ date: Date) -> String {
        let s = Int(-date.timeIntervalSinceNow)
        guard s >= 60 else { return "now" }
        let m = s / 60
        guard m >= 60 else { return "\(m) min" }
        let h = m / 60
        guard h >= 24 else { return "\(h)h" }
        let d = h / 24
        guard d >= 7 else { return "\(d)d" }
        return "\(d / 7)w"
    }

    @ViewBuilder var appIcon: some View {
        if let bundleID = item.appBundleID,
           let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
        {
            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                .resizable()
                .frame(width: 14, height: 14)
                .clipShape(RoundedRectangle(cornerRadius: 3))
        }
    }
}

// MARK: - ClipboardDrag

/// Builds the drag payload for one or more clipboard items.
/// Offers plain text (for editors) and a .txt file promise (for Finder).
enum ClipboardDrag {
    static func itemProvider(for items: [ClipboardItem]) -> NSItemProvider {
        let text = items.map(\.text).joined(separator: "\n")
        let name = fileName(for: items)

        let provider = NSItemProvider()
        provider.suggestedName = name

        // Plain text — dropped into a text editor / field.
        provider.registerDataRepresentation(
            forTypeIdentifier: UTType.utf8PlainText.identifier,
            visibility: .all
        ) { completion in
            completion(text.data(using: .utf8), nil)
            return nil
        }

        // File promise — dropped into a Finder folder, writes a .txt file.
        provider.registerFileRepresentation(
            forTypeIdentifier: UTType.plainText.identifier,
            fileOptions: [],
            visibility: .all
        ) { completion in
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
            do {
                try text.write(to: url, atomically: true, encoding: .utf8)
                completion(url, false, nil)
            } catch {
                completion(nil, false, error)
            }
            return nil
        }
        return provider
    }

    static func fileName(for items: [ClipboardItem]) -> String {
        guard items.count == 1 else { return "Clipboard Items.txt" }
        let firstLine = items[0].text.components(separatedBy: .newlines).first ?? ""
        let safe = firstLine
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        let base = String(safe.prefix(40))
        return (base.isEmpty ? "Clipboard" : base) + ".txt"
    }
}

// MARK: - SelectionButton

private struct SelectionButton: View {
    let isSelecting: Bool
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    // Show a circle while selecting, or when hovering the button in normal mode.
    private var showsCircle: Bool { isSelecting || isHovered }

    var body: some View {
        Button(action: action) {
            ZStack {
                if showsCircle {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .blue)
                            .font(.system(size: 17))
                    } else {
                        Image(systemName: "circle")
                            .foregroundStyle(Color.white.opacity(0.55))
                            .font(.system(size: 17))
                    }
                } else {
                    Image(systemName: "text.alignleft")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.55))
                        .frame(width: 28, height: 24)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
            }
            .frame(width: 28, height: 24)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.12), value: showsCircle)
    }
}

// MARK: - CardActionButton

private struct CardActionButton: View {
    let icon: String
    var tint: Color = .white
    var isActive: Bool = false
    let action: () -> Void

    @State private var isHovered = false

    private var highlighted: Bool { isHovered || isActive }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(highlighted ? tint : Color.white.opacity(0.55))
                .frame(width: 28, height: 24)
                .background(highlighted ? tint.opacity(0.18) : Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.1), value: isHovered)
    }
}

// MARK: - FilterChip

private struct FilterChip: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .padding(7)
                .background(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.08))
                .clipShape(Circle())
                .foregroundStyle(isSelected ? Color.white : Color.secondary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NotchContentView(vm: .init())
        .padding()
        .frame(width: 600, height: 220, alignment: .center)
        .background(.black)
        .preferredColorScheme(.dark)
}

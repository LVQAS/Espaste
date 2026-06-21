//
//  NotchContentView.swift
//  Espaste
//

import AppKit
import SwiftUI

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

    enum FilterType { case favorites, apps, clipboard, all }

    var filteredItems: [ClipboardItem] {
        var result = store.items
        if selectedFilter == .favorites { result = result.filter { $0.isFavorite } }
        if !searchText.isEmpty {
            result = result.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
        }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
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
        .padding(.vertical, 10)
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
                    ClipboardItemCard(item: item) {
                        store.copyToClipboard(item)
                    } onFavorite: {
                        store.toggleFavorite(item)
                    } onDelete: {
                        store.delete(item)
                    }
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
    let onTap: () -> Void
    let onFavorite: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                CardActionButton(icon: "square.and.arrow.down.on.square", action: onTap)
                Spacer()
                CardActionButton(icon: "trash", tint: .red, action: onDelete)
                CardActionButton(
                    icon: item.isFavorite ? "star.fill" : "star",
                    tint: .yellow,
                    isActive: item.isFavorite,
                    action: onFavorite
                )
            }
            .padding(.horizontal, 6)
            .padding(.top, 5)
            .padding(.bottom, 2)
            .opacity(isHovered ? 1 : 0)

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
                .onTapGesture(perform: onTap)

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
                    item.isFavorite
                        ? Color.yellow.opacity(0.5)
                        : Color.white.opacity(isHovered ? 0.4 : 0),
                    lineWidth: 0.5
                )
        )
        .scaleEffect(isHovered ? 1.04 : 1.0)
        .onHover { isHovered = $0 }
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
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

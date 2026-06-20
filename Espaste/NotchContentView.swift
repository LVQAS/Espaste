//
//  NotchContentView.swift
//  Espaste
//

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

private struct ClipboardView: View {
    @StateObject var vm: NotchViewModel
    @State private var searchText = ""
    @State private var selectedFilter: FilterType = .all

    enum FilterType { case favorites, apps, clipboard, all }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider().opacity(0.2)
            filterRow
            Divider().opacity(0.2)
            emptyState
        }
        .background(.black)
        .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius))
    }

    var searchBar: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Espaste")
                    .font(.system(.headline, design: .rounded))
                Spacer()
                Button { } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 13))
                TextField("Search", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    var filterRow: some View {
        HStack(spacing: 6) {
            FilterChip(icon: "star.fill",         isSelected: selectedFilter == .favorites) { selectedFilter = .favorites }
            FilterChip(icon: "square.grid.2x2",   isSelected: selectedFilter == .apps)      { selectedFilter = .apps }
            FilterChip(icon: "doc.on.clipboard",  isSelected: selectedFilter == .clipboard) { selectedFilter = .clipboard }

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

            Button {} label: {
                Image(systemName: "plus")
                    .font(.system(size: 13))
                    .padding(6)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
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

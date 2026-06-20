//
//  NotchHeaderView.swift
//  Espaste
//

import SwiftUI

struct NotchHeaderView: View {
    @StateObject var vm: NotchViewModel

    var body: some View {
        HStack {
            Text(
                vm.contentType == .settings
                    ? "Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown") (Build: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"))"
                    : "Espaste"
            )
            .contentTransition(.numericText())
            Spacer()
            Image(systemName: "ellipsis")
        }
        .animation(vm.animation, value: vm.contentType)
        .font(.system(.headline, design: .rounded))
    }
}

#Preview {
    NotchHeaderView(vm: .init())
}

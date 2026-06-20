//
//  NotchSettingsView.swift
//  Espaste
//

import LaunchAtLogin
import SwiftUI

struct NotchSettingsView: View {
    @StateObject var vm: NotchViewModel

    var body: some View {
        VStack(spacing: vm.spacing) {
            HStack {
                Picker("Language: ", selection: $vm.selectedLanguage) {
                    ForEach(Language.allCases) { language in
                        Text(language.localized).tag(language)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: vm.selectedLanguage == .simplifiedChinese || vm.selectedLanguage == .traditionalChinese ? 220 : 160)

                Spacer()
                LaunchAtLogin.Toggle {
                    Text(NSLocalizedString("Launch at Login", comment: ""))
                }

                Spacer()
                Toggle("Haptic Feedback ", isOn: $vm.hapticFeedback)

                Spacer()
            }
        }
        .padding()
        .transition(.scale(scale: 0.8).combined(with: .opacity))
    }
}

#Preview {
    NotchSettingsView(vm: .init())
        .padding()
        .frame(width: 600, height: 150, alignment: .center)
        .background(.black)
        .preferredColorScheme(.dark)
}

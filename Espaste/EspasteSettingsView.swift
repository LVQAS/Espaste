//
//  EspasteSettingsView.swift
//  Espaste
//

import LaunchAtLogin
import SwiftUI

struct EspasteSettingsView: View {
    @ObservedObject var vm: NotchViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Form {
                Section("General") {
                    LaunchAtLogin.Toggle("Launch at Login")
                    Toggle("Haptic Feedback", isOn: $vm.hapticFeedback)
                }

                Section("Language") {
                    Picker("Language", selection: $vm.selectedLanguage) {
                        ForEach(Language.allCases) { language in
                            Text(language.localized).tag(language)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 500, height: 340)
    }
}

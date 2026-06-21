//
//  EspasteSettingsView.swift
//  Espaste
//

import LaunchAtLogin
import SwiftUI

struct EspasteSettingsView: View {
    @ObservedObject var vm: NotchViewModel
    @Namespace private var glassNamespace

    var body: some View {
        ZStack {
            // Background the glass refracts against — matches Espaste's dark aesthetic.
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.10, blue: 0.18),
                    Color(red: 0.05, green: 0.05, blue: 0.10),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                GlassEffectContainer(spacing: 16) {
                    VStack(spacing: 16) {
                        // MARK: General
                        VStack(spacing: 0) {
                            row(icon: "power", title: "Launch at Login") {
                                LaunchAtLogin.Toggle("")
                                    .labelsHidden()
                            }
                            Divider()
                                .opacity(0.12)
                                .padding(.leading, 56)
                            row(icon: "waveform", title: "Haptic Feedback") {
                                Toggle("", isOn: $vm.hapticFeedback)
                                    .labelsHidden()
                            }
                        }
                        .glassEffect(.regular, in: .rect(cornerRadius: 14))
                        .glassEffectID("general", in: glassNamespace)

                        // MARK: Language
                        row(icon: "globe", title: "Language") {
                            Picker("", selection: $vm.selectedLanguage) {
                                ForEach(Language.allCases) { language in
                                    Text(language.localized).tag(language)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                        }
                        .glassEffect(.regular, in: .rect(cornerRadius: 14))
                        .glassEffectID("language", in: glassNamespace)
                    }
                }
                .padding(24)
            }
        }
        .frame(width: 480, height: 300)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func row<C: View>(
        icon: String,
        title: String,
        @ViewBuilder control: () -> C
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 28, height: 28)
                .background(.white.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 7))

            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.9))

            Spacer()

            control()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }
}

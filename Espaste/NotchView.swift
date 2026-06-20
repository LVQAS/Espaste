//
//  NotchView.swift
//  Espaste
//

import Combine
import SwiftUI
import UniformTypeIdentifiers

struct NotchView: View {
    @StateObject var vm: NotchViewModel

    @State var dropTargeting: Bool = false

    var notchWidth: CGFloat {
        switch vm.status {
        case .closed, .popping: return max(0, vm.deviceNotchRect.width - 4)
        case .opened: return vm.notchOpenedSize.width
        }
    }

    // nil = intrinsic (content determines height when opened)
    var notchHeight: CGFloat? {
        switch vm.status {
        case .closed: return max(0, vm.deviceNotchRect.height - 4)
        case .popping: return vm.deviceNotchRect.height + 4
        case .opened: return nil
        }
    }

    var topCornerRadius: CGFloat {
        switch vm.status {
        case .closed, .popping: return 6
        case .opened: return 19
        }
    }

    var bottomCornerRadius: CGFloat {
        switch vm.status {
        case .closed, .popping: return 14
        case .opened: return 24
        }
    }

    var currentNotchShape: NotchShape {
        NotchShape(topCornerRadius: topCornerRadius, bottomCornerRadius: bottomCornerRadius)
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: vm.spacing) {
                NotchContentView(vm: vm)
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, vm.spacing)
            .padding(.horizontal, 28)
            .frame(width: notchWidth, height: notchHeight, alignment: .top)
            .background(.black)
            .clipShape(currentNotchShape)
            // Measure actual rendered height and keep notchOpenedSize in sync
            // so that the mouse-tracking rect (notchOpenedRect) stays accurate.
            .background(GeometryReader { geo in
                Color.clear
                    .onAppear { updateOpenedSize(geo.size) }
                    .onChange(of: geo.size) { _, size in updateOpenedSize(size) }
            })
            .overlay(alignment: .top) {
                // Fills the sub-pixel gap at the screen top edge between the two concave ear curves
                Rectangle()
                    .fill(.black)
                    .frame(height: 1)
                    .padding(.horizontal, topCornerRadius)
            }
            .shadow(color: .black.opacity(vm.status == .opened ? 0.8 : 0), radius: 16)
            .opacity(vm.status == .closed ? 0 : 1)
        }
        .background(dragDetector)
        .animation(vm.animation, value: vm.status)
        .preferredColorScheme(.dark)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func updateOpenedSize(_ size: CGSize) {
        guard vm.status == .opened, size.height > vm.deviceNotchRect.height else { return }
        vm.notchOpenedSize = CGSize(width: vm.notchOpenedSize.width, height: size.height)
    }

    var dragDetectorSize: CGSize {
        switch vm.status {
        case .closed, .popping:
            return CGSize(
                width: vm.notchOpenedSize.width,
                height: max(vm.deviceNotchRect.height, 44)
            )
        case .opened:
            return vm.notchOpenedSize
        }
    }

    @ViewBuilder
    var dragDetector: some View {
        RoundedRectangle(cornerRadius: bottomCornerRadius)
            .foregroundStyle(Color.black.opacity(0.001))
            .contentShape(Rectangle())
            .frame(width: dragDetectorSize.width + vm.dropDetectorRange, height: dragDetectorSize.height + vm.dropDetectorRange)
            .onDrop(of: [.data], isTargeted: $dropTargeting) { _ in true }
            .onChange(of: dropTargeting) { _, isTargeted in
                if isTargeted, vm.status == .closed {
                    vm.notchOpen(.drag)
                    vm.hapticSender.send()
                } else if !isTargeted {
                    let mouseLocation: NSPoint = NSEvent.mouseLocation
                    if !vm.notchOpenedRect.insetBy(dx: vm.inset, dy: vm.inset).contains(mouseLocation) {
                        vm.notchClose()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

# Espaste

Free, open-source macOS notch tool — clipboard manager. Built as an alternative to the paid, closed-source [Supaste](https://www.supaste.com/).

## Project goal

- Reproduce Supaste's core features as a free macOS notch app
- Open source, SF Symbols for icons (same as Supaste)
- Target: MacBooks with physical notch; falls back gracefully on notchless screens

---

## Architecture

### Entry point & lifecycle

| File | Role |
|---|---|
| `main.swift` | Single-instance guard via PID file; executable-delete watcher; calls `NSApplicationMain` |
| `AppDelegate.swift` | `.accessory` activation policy; rebuilds window on screen parameter change; 1 s timer for PID check + key window |
| `NotchWindowController.swift` | Creates `NotchWindow` sized to top 200 pt of screen; sets up `NotchViewModel`; positions window |
| `NotchWindow.swift` | Borderless, transparent `NSWindow` at `.statusBar + 8` level; no shadow; joins all spaces |
| `NotchViewController.swift` | `NSHostingController<NotchView>` bridge |

### ViewModel

| File | Role |
|---|---|
| `NotchViewModel.swift` | State machine (`closed / opened / popping`), sizes, animation constant, haptic sender |
| `NotchViewModel+Events.swift` | Global/local `NSEvent` monitors via `EventMonitors.shared`; hover-open, hover-close, option key |

**Open/close logic (Events)**
- Mouse enters `deviceNotchRect` → `notchOpen(.click)`
- Mouse leaves `notchOpenedRect` → `notchClose()`
- Click outside opened rect → `notchClose()`

**Key VM properties**
```swift
let animation: Animation = .spring(response: 0.4, dampingFraction: 0.82)
@Published var notchOpenedSize: CGSize = .init(width: 720, height: 260)  // height updated dynamically
let dropDetectorRange: CGFloat = 32
enum Status { case closed, opened, popping }
```

### Views

| File | Role |
|---|---|
| `NotchShape.swift` | Custom `Shape` with `animatableData: AnimatablePair<CGFloat, CGFloat>` for smooth path morphing between closed and opened corner radii. Based on DynamicNotchKit (MIT). |
| `NotchView.swift` | Root SwiftUI view; drives `NotchShape` animation; dynamic height (nil when opened = intrinsic content size); GeometryReader feeds back actual size to `vm.notchOpenedSize` |
| `NotchContentView.swift` | Switches between `ClipboardView / NotchMenuView / NotchSettingsView` based on `vm.contentType` |
| `NotchHeaderView.swift` | App title + ellipsis row — **currently unused** (merged into `ClipboardView.searchBar`) |

### Animation approach (Boring Notch style)

`NotchShape` implements `Animatable` via `animatableData`. Corner radii:

| State | topCornerRadius | bottomCornerRadius |
|---|---|---|
| closed / popping | 6 | 14 |
| opened | 19 | 24 |

The shape's path itself interpolates — no frame-masking tricks. Combined with `frame(width:height:)` animated by the same `.spring`, the notch morphs in a single continuous movement.

### Dynamic height

`notchHeight` in `NotchView` returns `nil` when status is `.opened`, so SwiftUI measures the content's intrinsic height. A `GeometryReader` background captures the actual rendered height and writes it back to `vm.notchOpenedSize.height` to keep the mouse-tracking rect (`notchOpenedRect`) accurate.

### ClipboardView layout (current placeholder state)

```
┌─────────────────────────────────────────┐
│ Espaste                             [⋯] │  ← searchBar top row
│ 🔍 Search…                              │  ← searchBar bottom row
├─────────────────────────────────────────┤
│ ★  ⊞  📋  [ All ]  +                   │  ← filterRow
├─────────────────────────────────────────┤
│                                         │
│          🗒  Nothing here yet           │  ← emptyState
│       Copy anything — it shows up here  │
│                                         │
└─────────────────────────────────────────┘
```

---

## SPM packages

| Package | Use |
|---|---|
| `ColorfulX` | Animated gradient backgrounds |
| `LaunchAtLogin-Modern` | Login item registration |
| `Pow` | SwiftUI transition effects |
| `swift-collections` | `OrderedDictionary` etc. |

---

## Utilities

| File | Role |
|---|---|
| `EventMonitor.swift` | Wraps `NSEvent.addGlobalMonitorForEvents` + local monitor |
| `EventMonitors.shared` | Singleton; exposes `.mouseDown`, `.mouseLocation`, `.optionKeyPress` as Combine publishers |
| `PublishedPersist.swift` | Property wrapper: `@Published` + file-based persistence |
| `Language.swift` | Language enum + `apply()` |
| `Ext+NSScreen.swift` | `.buildin`, `.notchSize` helpers |
| `Ext+NSAlert.swift` | `NSAlert.popError(_:)` helper |

---

## Dev scripts

| Script | What it does |
|---|---|
| `run.sh` | Kills Espaste + Supaste + debugserver → builds → registers → launches |
| `stop.sh` | Kills Espaste → launches Supaste |

---

## Padding / sizing constants

| Value | Where | Purpose |
|---|---|---|
| `vm.spacing = 16` | `NotchViewModel` | VStack spacing & vertical padding |
| `28` | `NotchView` | Horizontal padding (outer) |
| `12` | `ClipboardView` | Horizontal padding (inner, search/filter rows) |
| `720` | `vm.notchOpenedSize.width` | Opened notch width |
| `200` | `NotchWindowController` | Window height covering top of screen |

---

## What's not implemented yet

- Actual clipboard monitoring (`NSPasteboard` polling)
- Clipboard item list (replacing the empty state)
- Favorites, app-source filtering
- Settings view content
- Menu view content
- Persistence of clipboard history

lib/views/
├── photo_booth_screen/
│   ├── photo_booth.dart              ← ⭐ UI utama booth
│   ├── photo_booth.hotkey_monitor.dart
│   └── photo_booth.menu.dart         ← menu
│
├── onboarding_screen/
│   └── onboarding_screen.dart        ← ⭐ halaman awal/setup
│
├── settings_overlay/
│   ├── settings_overlay.dart
│   ├── settings_overlay_view.dart    ← ⭐ UI settings
│   └── settings_overlay_view_model.dart
│
├── components/
│   └── qr_code.dart                  ← QR
│
└── base/
    ├── photo_booth_dialog_page.dart
    ├── full_screen_dialog.dart
    └── screen_base.dart


    Run FRC PATH="$PWD/.fvm/flutter_sdk/bin:$PATH" flutter_rust_bridge_codegen generate
# Font Files

This directory should contain the following PingFang SC font files:

- `PingFang-SC-Regular.ttf` (Weight: 400)
- `PingFang-SC-Medium.ttf` (Weight: 500)
- `PingFang-SC-Semibold.ttf` (Weight: 600)

Note: PingFang SC fonts are not included in this repository due to licensing restrictions. You'll need to obtain these fonts separately and place them in this directory.

## Alternative Fonts

If you don't have access to PingFang SC fonts, you can use alternative fonts by modifying the `pubspec.yaml` file to use one of these options:

1. System fonts (recommended for development):
```yaml
fonts:
  - family: PingFang SC
    fonts:
      - asset: system
```

2. Noto Sans SC (Google Fonts):
```yaml
dependencies:
  google_fonts: ^5.1.0
```

Then use:
```dart
import 'package:google_fonts/google_fonts.dart';

// In your theme:
textTheme: GoogleFonts.notoSansScTextTheme(),

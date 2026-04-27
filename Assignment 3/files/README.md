# Health-Scale - Flutter

A faithful Flutter conversion of the **Health-Scale** Expo / React Native BMI calculator app. Pure Flutter / Dart - no React Native, no Expo, no JS layer. All logic, theming, animations, and UX have been re-implemented natively in Flutter.

## Features

- **Calculator tab**
  - Gender picker with animated chip selection
  - Height / Weight / Age cards with horizontal **ruler pickers** (haptic snap)
  - Tap any value to type it in directly
  - Unit switching: cm / m / ft+in, kg / lbs / st
  - Animated loading spinner (3.4 s) -> result reveal
  - Animated **arc gauge** with category color, segment hints, and tip dot
  - Stat tiles: ideal weight range, est. daily calories (Mifflin-St Jeor x 1.55), BMI score, category
  - Daily health tip (rotates by date)
- **History tab**
  - Average / best / total stats
  - Bar trend chart of last 10 entries with dashed grid lines
  - Full record list (newest first) with category-colored badges
  - Clear-all confirmation dialog
- **Profile tab**
  - Editable name + gender
  - Theme picker: Light / Dark / Auto (follows system)
  - BMI category reference + formula card
- **Persistence** with `shared_preferences` (mirrors the original `AsyncStorage` schema)
- **Theming** - full light + dark palettes from the source app

## Project structure

```text
lib/
|-- constants/
|   `-- colors.dart          # AppPalette light + dark
|-- models/
|   |-- bmi_record.dart
|   `-- user_profile.dart
|-- providers/
|   |-- theme_provider.dart  # Light/Dark/Auto + system brightness
|   `-- bmi_provider.dart    # State + persistence (50-record cap)
|-- utils/
|   |-- bmi_utils.dart       # BMI math, category, message, ideal weight, BMR
|   `-- conversions.dart     # cm/m/ft-in, kg/lbs/st
|-- widgets/
|   |-- unit_toggle.dart
|   |-- gender_selector.dart
|   |-- ruler_picker.dart
|   |-- metric_card.dart
|   |-- bmi_spinner.dart
|   |-- bmi_result_display.dart   # Custom-painted arc gauge
|   |-- bmi_history_chart.dart
|   |-- dashed_panel.dart
|   `-- health_tip.dart
|-- screens/
|   |-- main_tabs.dart       # Bottom tab shell
|   |-- home_screen.dart     # Calculator (input -> loading -> result)
|   |-- history_screen.dart
|   `-- profile_screen.dart
`-- main.dart
```

## Getting started

```bash
cd "nabeel 2"
flutter pub get
flutter run
```

Requires Flutter SDK >= 3.0.

## Dependencies

- `provider` - state management
- `shared_preferences` - local persistence (replaces `AsyncStorage`)
- `google_fonts` - Inter font family
- `feather_icons` - matches the icon set used in the source app

## Notes on parity with the source

- Defaults: **height 170 cm, weight 70 kg, age 25, male, metric units**
- BMI thresholds: `<18.5` Underweight (#3B82F6), `<25` Normal (#10B981), `<30` Overweight (#F59E0B), else Obese (#EF4444)

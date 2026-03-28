# 📋 Flodo Task Manager

A polished, production-grade Flutter Task Management app built for the Flodo AI take-home assignment.

---

## ✅ Track & Stretch Goal

- **Track B — Mobile Specialist** (Flutter + Hive local database)
- **Stretch Goal — Debounced Autocomplete Search with Text Highlighting**

---

## 🚀 Setup Instructions

### Prerequisites

| Tool | Version |
|------|---------|
| Flutter | ≥ 3.10.0 |
| Dart | ≥ 3.0.0 |
| Android Studio / Xcode | Latest stable |

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/<your-username>/flodo_task_app.git
cd flodo_task_app

# 2. Install dependencies
flutter pub get

# 3. Run on a connected device / emulator
flutter run

# (Optional) Build release APK
flutter build apk --release
```

> **Note:** Hive adapters are pre-generated. If you make model changes, regenerate with:
> ```bash
> dart run build_runner build --delete-conflicting-outputs
> ```

---

## 🏗️ Architecture

```
lib/
├── main.dart              # App entry, Hive init, Provider setup
├── models/
│   ├── task.dart          # Task data model + HiveType annotations
│   ├── task.g.dart        # Generated Hive adapter
│   ├── draft.dart         # Draft persistence model
│   └── draft.g.dart       # Generated Hive adapter
├── providers/
│   └── task_provider.dart # State management (ChangeNotifier)
├── screens/
│   ├── home_screen.dart   # Main task list, search, filters
│   └── task_form_screen.dart # Create/Edit task form
├── widgets/
│   ├── task_card.dart     # Swipeable task card with blocked state
│   ├── highlighted_text.dart # Debounced search highlight widget
│   ├── stats_overview.dart # Header stats bar
│   └── empty_state.dart   # Empty list illustration
├── theme/
│   └── app_theme.dart     # Full dark theme, colors, typography
└── utils/
    └── date_utils.dart    # Date formatting helpers
```

---

## ✨ Features

### Core (Required)

| Feature | Details |
|---------|---------|
| **Task Model** | Title, Description, Due Date, Status (To-Do / In Progress / Done), Blocked By |
| **Main List View** | All tasks; blocked tasks visually dimmed with a 🔒 badge |
| **Create / Edit** | Full-screen form with validation and live draft saving |
| **Delete** | Swipe-to-delete with confirmation dialog, cascades blocker refs |
| **CRUD** | Full create, read, update, delete via Hive |
| **Drafts** | Form state persisted to Hive on every keystroke; restores on re-open |
| **Search** | Debounced 300ms text search on task titles |
| **Filter** | Chip-based filter: All / To-Do / In Progress / Done |

### Blocking Logic

- A task with **"Blocked By"** set to another task appears greyed out with a 🔒 "Blocked" chip until the dependency is marked **Done**.
- When a task is deleted, its ID is automatically removed from any tasks that were blocked by it.

### 2-Second Save Simulation

- `Future.delayed(const Duration(seconds: 2))` simulates API latency.
- A full-screen semi-transparent overlay with a spinner prevents double-taps.
- Save button is disabled (`onPressed: null`) during the save operation.
- UI remains fully interactive (scrollable, navigable) — only the save action is locked.

### Drag-and-Drop Reorder (Bonus UX)

- Tasks can be long-pressed and dragged to reorder.
- Custom sort order is persisted to Hive and survives app restarts.

---

## 🔍 Stretch Goal: Debounced Search + Text Highlight

### How it works

1. **Debounce**: `TaskProvider.onSearchChanged()` uses a `Timer(300ms)` that resets on every keystroke. The filter only re-runs after the user pauses typing for 300ms — preventing excessive rebuilds.

2. **Highlight**: `HighlightedText` widget (`lib/widgets/highlighted_text.dart`) uses `Text.rich()` with `TextSpan` children. It scans the task title string for the query substring (case-insensitive), wraps matches with a contrasting color + background highlight, and leaves non-matching segments unstyled.

```dart
// Simplified highlight logic
final idx = lower.indexOf(lowerQuery, start);
spans.add(TextSpan(
  text: text.substring(idx, idx + query.length),
  style: baseStyle.copyWith(
    color: AppTheme.primaryColor,
    backgroundColor: AppTheme.primaryColor.withOpacity(0.18),
    fontWeight: FontWeight.w700,
  ),
));
```

---

## 🎨 UI/UX Highlights (Track B emphasis)

- **Dark theme** with deep navy/purple palette (`#0F0F1A` background, `#6C63FF` primary)
- **Google Fonts Inter** for clean, modern typography
- **`flutter_animate`** for entry animations on cards (fade + slide, staggered by index)
- **`flutter_slidable`** for swipe-to-action (status change + delete)
- **Stats overview** bar showing live counts per status
- **Overdue tasks** flagged with amber warning icon
- **Smooth page transitions** using custom `PageRouteBuilder` with slide animation
- **Status selector** on form uses tap-to-select tile grid instead of a dropdown

---

## 🤖 AI Usage Report

This project was developed with AI assistance (Claude). Below is a transparent account:

### Most Helpful Prompts

1. **"Write a Flutter `ChangeNotifier` with Hive for task CRUD, including draft persistence, debounced search, and a 2-second simulated save delay that prevents double taps"**  
   → Generated ~90% of `task_provider.dart` in one shot, including the `Timer`-based debounce and the `isSaving` guard pattern.

2. **"Create a `HighlightedText` Flutter widget that takes a `text` string and a `query` string, splits the text around case-insensitive matches, and renders matched segments with a colored background using `Text.rich()`"**  
   → Produced the complete `highlighted_text.dart` widget cleanly.

3. **"Write a Hive TypeAdapter for a Task class with these 8 fields..."**  
   → Saved time on the boilerplate `.g.dart` file.

### AI Hallucination / Fix

**Issue:** The AI initially used `Hive.box<Task>('tasks')` without `await` in the provider's `init()` method — but `openBox` is async. It also tried to call `.put()` on a `HiveObject` subclass using the object itself as the key, which is wrong; Hive uses `.put(key, value)` for box-level puts, or `object.save()` for already-in-box objects.

**Fix:** Changed all update operations to: `delete old object → put updated copy` pattern. This is idiomatic for Hive when you're working with `copyWith` immutable-style updates and avoids stale object issues.

---

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| `hive` + `hive_flutter` | Local persistence (key-value store) |
| `provider` | State management |
| `uuid` | Unique task IDs |
| `intl` | Date formatting |
| `flutter_animate` | Stagger animations |
| `google_fonts` | Inter typeface |
| `flutter_slidable` | Swipe-to-action on cards |

---

## 📹 Demo Video

link will be here soon

---

## 📄 License

MIT — for assignment purposes only.
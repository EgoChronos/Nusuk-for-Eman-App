# Nusuk for Eman (نُسك لإيمان)

## Project Overview
**Nusuk for Eman (نُسك لإيمان)** is a premium Flutter application dedicated as *Sadaqah Jariyah* (ongoing charity) for the soul of **Eman Mohammed Tayee**. It is designed to provides a serene and spiritual experience, offering tools including a Quran reader, background audio player, dhikr tracker, and a notification-driven "Floating Content" system.

## Brand & Identity
- **App Name**: Nusuk for Eman (نُسك لإيمان).
- **Typography**: 
  - **Aref Ruqaa**: Used for the dedication and memorial text to provide a traditional calligraphic feel.
  - **Amiri**: Used for Quranic text for maximum readability and classical aesthetics.
- **English Title**: Globally fixed to "Nusuk for Eman" for consistency across all locales.
- **Memorial Styling**: Leverages `RichText` and premium typefaces to provide a respectful dedication that aligns natively with the user's locale (Arabic/English).

## Architecture & Tech Stack
- **Framework**: Flutter (Impeller enabled for high-performance rendering).
- **State Management**: Riverpod (Provider-based architecture).
- **Storage**: 
  - **Hive (Local)**: High-performance local storage for preferences and activity counters.
  - **Supabase (Cloud)**: Used for global statistics and remote configuration.
- **Background Engine**:
  - **Audio**: `audio_service` + `just_audio` for reliable background playback.
  - **Floating Overlays**: `flutter_overlay_window` for interactive alerts.
  - **Scheduling**: `android_alarm_manager_plus` (utilizing background isolates).
  - **Notifications**: `flutter_local_notifications` for standard system alerting.

## Project Structure
The project follows a modular architecture organized by domain and layer:

### `lib/core/`
The backbone of the application, containing shared infrastructure:
- **`services/`**: Core logic for notifications, audio, and version management.
- **`providers.dart`**: Global Riverpod provider definitions.
- **`theme/`**: App branding, colors, and typography tokens.
- **`constants/`**: Globally fixed assets like `app_strings.dart`.
- **`widgets/`**: Shared UI components (dialogs, custom buttons).

### `lib/data/`
Responsible for data management and external integrations:
- **`models/`**: Dart classes for notifications, Quran data, etc.
- **`sources/`**: Direct data handlers (Supabase, Hive, Local JSON).
- **`repositories/`**: Abstraction layer for fetching data from multiple sources.
- **`notification_data.dart`**: Static repository of Adhkar and Hadith content.

### `lib/features/`
Feature-based UI and business logic:
- **`quran/`**: The main Quran reader and surah list.
- **`audio/`**: Media player interface.
- **`floating_content/`**: Logic for the overlay window (`overlay_screen.dart`).
- **`splash/`**: The emotional entry point and auto-navigation logic.
- **`settings/`**: Notification controls and optimization guidance.

### `lib/app.dart` & `lib/main.dart`
- **`main.dart`**: Entry point for initializing local storage and launching the app.
- **`app.dart`**: The `MainScreen` container with Bottom Navigation and global routing.

### `plugins/`
Contains local native plugins like `foreground_launcher` to handle specific background behaviors.

## Notification & Overlay System
The system utilizes a "True Floating" architecture with redundant fallbacks to ensure reliability across all Android distributions.

### 1. The Floating Overlay Engine (`NotificationService`)
- **Dual-Layer Alerting**:
  - **Floating Window**: Displays interactive religious content (Ayahs, Hadiths, etc.) over other apps.
  - **Standard Fallback**: A standard notification is fired before attempting the overlay. This ensures the user is alerted even if the OS suppresses the drawing of the floating window (e.g., Xiaomi "Pop-up" permissions).
- **Background Isolate (`showOverlayCallback`)**:
  - Runs in a separate thread via `AndroidAlarmManager`.
  - Handles content generation via `NotificationContentGenerator`.
  - Includes a **Self-Rescheduling** mechanism that sets the next instance precisely at trigger time, ensuring the schedule persists even if the main app is closed.

### 2. Automatic Precision
- **Poll-Based Permission Check**: Includes a 10-second polling loop to detect permission settlement (crucial for devices that report system alert permission status with a delay).
- **Lifecycle Awareness**: Uses `WidgetsBindingObserver` to automatically re-sync schedules and transition mode as soon as the user returns from system settings.

### 3. Content Scheduling
- **Frequency Slots**:
  - **Low**: 2-3 slots/day.
  - **Medium (Default)**: 6 slots/day (7 AM, 10 AM, 1 PM, 4 PM, 7 PM, 10 PM).
  - **High**: 8-12 slots/day.
- **Fixed Reminders**: Morning (6 AM), Evening (5:30 PM), Sleep (10 PM), and Friday Surah Kahf (1:30 PM).
- **Duaa for Eman**: Integrated into the floating system with dedicated night (9 PM) and morning (8 AM) triggers.

## Android Optimization Guidelines
To maintain reliability across distributions (MIUI, OneUI, ColorOS, etc.), users are guided in Settings to:
1. **Display Over Other Apps**: Mandatory for the interactive floating window.
2. **Battery Optimization**: App must be set to "No Restrictions" or "Unrestricted" to prevent the OS from killing the background alarm engine.

## Global Impact & Stats Sync
- **Mechanism**: Tapping "Mark as Read" or "Duaa Now" on an overlay or notification increments local Hive counters and queues them for Supabase sync.
- **Sync Logic**: Automatically flushes pending increments on app startup and when connectivity returns. Uses the `increment_global_stats` RPC for atomic server-side updates to prevent race conditions.

## Technical Maintenance
- **RPC Calls**: Always use the defined RPC for Supabase total updates; never update tables directly.
- **Manifest**: Ensure `OverlayService` and `AlarmService` are declared for any new build flavor.
- **Source of Truth**: `quran.json` (located in `data/`) is the source of truth for the Quran reader.
- **Background Reliability**: Monitor the "Self-Reschedule" logs in `NotificationService` if users report drifting times.

## Background Notification Reliability (Technical Deep-Dive)

The "Nusuk for Eman" notification system is engineered for **bulletproof reliability**, especially on background-restrictive Android distributions (Xiaomi/MIUI, Samsung OneUI, etc.).

### 1. The "Priority First" Strategy
To ensure notifications pierce through "Do Not Disturb" and wake dark screens:
- **Importance & Priority**: Both are set to `max`. This transforms a standard notification into a "Heads-up" alert that can wake the screen.
- **Visibility**: Set to `public` to ensure content appears on the lock screen without requiring a de-masking gesture.
- **Alarm Clock Mode**: We use `alarmClock: true` in `android_alarm_manager_plus`. This bypasses standard "Doze Mode" windows by telling the OS the app is a literal alarm clock.

### 2. Multi-Layer Redundancy
We don't rely solely on one mechanism:
1. **System Notification (Floor)**: Scheduled via `zonedSchedule()` with daily repeat. This fires automatically via Android's notification scheduling, independent of the app process and serves as the persistent anchor for the schedule.
2. **Floating Overlay (Ceiling)**: Triggered via `AndroidAlarmManager.oneShotAt()` to draw a premium, interactive window over other apps.
*Decision*: We schedule **BOTH** in parallel. The standard notification ensures the user sees something in the tray (alerting them) even if they miss the overlay or have it blocked. They are complementary UI types and coexist.

### 3. Background Persistence Logic
- **Self-Rescheduling**: The scheduling logic does not live only in the main app. Every time the background isolate triggers, it calculates the *next* slot and reschedules itself via `AlarmManager`. This prevents "missing" schedules if the main app is force-closed.
- **Isolate Re-Initialization**: The background isolate ensures timezones and local storage (`Hive`) are re-initialized in that specific process to avoid null-pointer crashes.

### 4. Native Xiaomi (MIUI) Optimizations
Xiaomi's MIUI adds a layer of "Hidden Permissions" that standard Flutter plugins can't detect. We implemented a custom `MethodChannel` to handle:
- **Background Pop-ups (`OpCode 10021`)**: We check this native flag to see if "Display pop-up windows while running in the background" is actually active.
- **Auto-Start & Lock Screen**: Our `PermissionSetupScreen` provides direct links to these "Other Permissions" settings pages which are otherwise buried 5 levels deep in system menus.

### 5. Critical Maintenance Rules (Do Not Change)
If you refactor this system, **DO NOT** change these without rigorous testing:
- **`AndroidAlarmManager.periodic`**: Must remain periodic or self-rescheduling to survive device reboots.
- **Resource IDs**: Android requires `id: 0` for certain foreground behaviors; keep ID ranges consistent in `NotificationService`.
- **Xiaomi Channel Name**: The MethodChannel name `com.noorforiman.noor_for_iman/permissions` must match exactly in both Dart and `MainActivity.kt`.

## Roadmap & Maintenance
- **Debugging**: If diagnostic tools are needed in production, re-enable the `testDiagnostics()` calls in `notification_settings_screen.dart` and `NotificationService`.
- **UI Evolution**: Current diagnostics are hidden for a clean production experience.

---
*Dedication: This documentation serves to preserve the reliability of the work dedicated to the soul of Eman Mohammed Tayee.*

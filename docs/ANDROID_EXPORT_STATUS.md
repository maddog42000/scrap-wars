# Android Export Status — SCRAP WARS

**Status: Not exported; no APK is included.** This is an explicit environment limitation, not a completed Android deliverable.

The project was tested with Godot `4.7.2.stable.official.ed1daf0bf` on the Linux sandbox. The Android build tools `adb`, `sdkmanager`, `avdmanager`, and `gradle` were not present in PATH; Android export templates were not found under the user Godot data directory; no Android device was attached for installation or runtime validation. Consequently, Android APK export, install, launch, landscape behavior, touch input, suspend/resume, offline reopen, performance and device-specific 2D physics are **Not tested**.

The project configuration uses GL Compatibility and sets `display/window/handheld/orientation=0`, which Godot 4.7.2 identifies as `DisplayServer.SCREEN_LANDSCAPE`. That confirms only the source enum setting, not actual handset behavior.

To continue outside this environment, open the included project in Godot 4.7.2, install a matching Android export template and supported JDK/Android SDK, configure Godot’s Android editor paths/signing as needed, create a debug APK, then install and run it on physical landscape Android devices. Record the export version and actual device model/OS/results before claiming Android acceptance. The APK exported elsewhere would not be part of this ZIP unless separately added and re-tested from the same project revision.

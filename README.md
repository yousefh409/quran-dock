# QuranDock

A macOS menu bar app for listening to Quran recitations. Browse reciters, select surahs, and listen without leaving your current workflow.

![macOS 13.0+](https://img.shields.io/badge/macOS-13.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Menu Bar Player** - Lives entirely in your menu bar with a frosted-glass popover. No Dock icon, no extra windows.
- **Reciter Browser** - Browse a wide selection of Quran reciters with photos, favorite them, and switch between multiple recording styles (mosafs) per reciter.
- **Surah Browser** - All 114 surahs with Arabic names (Amiri Quran font), English names, and verse counts.
- **Full Playback Controls** - Play, pause, seek, skip, repeat, and adjust speed from 0.5x to 2.0x.
- **Custom Audio** - Import your own audio files (drag-and-drop or file picker) or paste a YouTube URL to download recitations directly.
- **Offline Caching** - API responses cached for 7 days. Surah data is bundled so the app works offline from first launch.
- **Launch at Login** - Start automatically when you log in.

## Tech Stack

- **SwiftUI** + **AppKit** (macOS 13.0+)
- **AVFoundation** for audio playback
- **Combine** for reactive data flow
- **MVVM** architecture with async/await concurrency
- Zero third-party dependencies
- [MP3Quran.net API](https://mp3quran.net) for reciters and audio
- [Quran.com API](https://api.quran.com) for surah data

## Getting Started

1. Clone the repo
   ```bash
   git clone https://github.com/yousefh409/quran-dock.git
   ```
2. Open `QuranDock.xcodeproj` in Xcode 15+
3. Build and run (requires macOS 13.0+)

## License

MIT

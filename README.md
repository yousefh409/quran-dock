# QuranDock

A macOS menu bar app for listening to Qur'an recitations. Browse reciters, select surahs, and listen — all from your menu bar.

## Features

- **Menu Bar Player** — Lives in your menu bar with a clean popover interface
- **Multiple Reciters** — Browse and favorite from a wide selection of Qur'an reciters
- **Full Playback Controls** — Play, pause, seek, skip, repeat, and adjust speed (0.5x–2.0x)
- **Surah Browser** — All 114 surahs with Arabic names, English translations, and verse counts
- **Launch at Login** — Optionally start automatically when you log in
- **Offline Caching** — API responses are cached for 7 days

## Tech Stack

- **SwiftUI** + **AppKit** (macOS 13.0+)
- **AVFoundation** for audio playback
- **Combine** for reactive data flow
- **MVVM** architecture
- [Quran.com API](https://api.quran.com) for surah data
- [MP3Quran.net API](https://mp3quran.net) for reciters and audio

## Getting Started

1. Clone the repo
   ```bash
   git clone https://github.com/yousefh409/quran-dock.git
   ```
2. Open `QuranDock.xcodeproj` in Xcode
3. Build and run (requires macOS 13.0+)

## License

MIT

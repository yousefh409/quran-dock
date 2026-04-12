import SwiftUI
import UniformTypeIdentifiers

struct CustomAudioView: View {
    @EnvironmentObject var viewModel: PlayerViewModel
    @State private var youtubeURL = ""
    @State private var isDropTargeted = false

    // Metadata form state
    @State private var metaTitle = ""
    @State private var metaReciter = ""
    @State private var metaQiraah: Qiraah?
    @State private var metaSurahId: Int?
    @State private var useSurahPicker = false

    private let audioTypes: [UTType] = [.mp3, .mpeg4Audio, .wav, .aiff, .audio]

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.pendingImport != nil {
                metadataForm
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 10)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                importSection
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 10)
            }

            if viewModel.customTracks.isEmpty && viewModel.pendingImport == nil {
                emptyState
            } else {
                trackList
            }
        }
        .frame(maxHeight: AppConstants.expandedListHeight)
        .animation(.smooth(duration: 0.25), value: viewModel.pendingImport != nil)
        .onChange(of: viewModel.pendingImport != nil) { hasPending in
            if hasPending, let pending = viewModel.pendingImport {
                metaTitle = pending.defaultTitle
                metaReciter = ""
                metaQiraah = nil
                metaSurahId = nil
                useSurahPicker = false
            }
        }
    }

    // MARK: - Metadata Form

    private var metadataForm: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(AppConstants.accentColor)
                Text("Track Details")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
            }

            // Title: text field or surah picker
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("Name")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        useSurahPicker.toggle()
                        if !useSurahPicker { metaSurahId = nil }
                    } label: {
                        Text(useSurahPicker ? "Type custom" : "Pick surah")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(AppConstants.accentColor)
                    }
                    .buttonStyle(.plain)
                }

                if useSurahPicker {
                    surahPickerField
                } else {
                    TextField("Track name", text: $metaTitle)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.primary.opacity(0.04))
                        )
                }
            }

            // Reciter name
            VStack(alignment: .leading, spacing: 4) {
                Text("Reciter")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)

                TextField(viewModel.pendingImport?.source.label ?? "Reciter name", text: $metaReciter)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.primary.opacity(0.04))
                    )
            }

            // Qira'ah picker
            VStack(alignment: .leading, spacing: 4) {
                Text("Qira'ah")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)

                Menu {
                    Button("None") { metaQiraah = nil }
                    Divider()
                    ForEach(Qiraah.allCases) { q in
                        Button {
                            metaQiraah = q
                        } label: {
                            HStack {
                                Text(q.rawValue)
                                if metaQiraah == q {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(metaQiraah?.rawValue ?? "None")
                            .font(.system(size: 11))
                            .foregroundStyle(metaQiraah != nil ? Color.primary : Color.secondary.opacity(0.6))
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary.opacity(0.5))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.primary.opacity(0.04))
                    )
                }
                .menuStyle(.borderlessButton)
            }

            // Save / Cancel
            HStack(spacing: 8) {
                Button {
                    viewModel.cancelPendingImport()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.primary.opacity(0.04))
                        )
                }
                .buttonStyle(.plain)

                Button {
                    saveTrack()
                } label: {
                    Text("Save")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(AppConstants.accentColor)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 2)
        }
    }

    // MARK: - Surah Picker

    private var surahPickerField: some View {
        Menu {
            ForEach(Surah.all) { surah in
                Button {
                    metaSurahId = surah.id
                    metaTitle = surah.nameSimple
                } label: {
                    HStack {
                        Text("\(surah.id). \(surah.nameSimple)")
                        Spacer()
                        Text(surah.nameArabic)
                        if metaSurahId == surah.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                if let id = metaSurahId, let surah = Surah.all.first(where: { $0.id == id }) {
                    Text("\(surah.nameSimple)  \(surah.nameArabic)")
                        .font(.system(size: 11))
                        .foregroundStyle(.primary)
                } else {
                    Text("Select a surah...")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary.opacity(0.6))
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary.opacity(0.5))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
            )
        }
        .menuStyle(.borderlessButton)
    }

    // MARK: - Import Section

    private var importSection: some View {
        VStack(spacing: 8) {
            dropZone
            youtubeInput
        }
    }

    private var dropZone: some View {
        Button {
            openFilePicker()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(isDropTargeted ? AppConstants.accentColor : .secondary.opacity(0.5))

                Text("Drop audio file or click to browse")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        isDropTargeted ? AppConstants.accentColor : Color.primary.opacity(0.1),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isDropTargeted ? AppConstants.accentColor.opacity(0.05) : Color.clear)
                    )
            )
        }
        .buttonStyle(.plain)
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers)
        }
    }

    private var youtubeInput: some View {
        HStack(spacing: 6) {
            Image(systemName: "play.rectangle.fill")
                .font(.system(size: 11))
                .foregroundStyle(.secondary.opacity(0.5))

            TextField("YouTube URL", text: $youtubeURL)
                .textFieldStyle(.plain)
                .font(.system(size: 11))
                .onSubmit { addFromYouTube() }

            if viewModel.isDownloadingYouTube {
                ProgressView()
                    .scaleEffect(0.5)
                    .frame(width: 16, height: 16)
            } else {
                Button {
                    addFromYouTube()
                } label: {
                    Text("Add")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(youtubeURL.isEmpty ? Color.secondary.opacity(0.3) : AppConstants.accentColor)
                        )
                }
                .buttonStyle(.plain)
                .disabled(youtubeURL.isEmpty)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
        .overlay {
            if let error = viewModel.youtubeError {
                VStack {
                    Spacer()
                    Text(error)
                        .font(.system(size: 9))
                        .foregroundStyle(.red.opacity(0.8))
                        .lineLimit(1)
                        .offset(y: 14)
                }
            }
        }
    }

    // MARK: - Track List

    private var trackList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.customTracks) { track in
                    trackRow(track)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }

    private func trackRow(_ track: CustomTrack) -> some View {
        let isPlaying = viewModel.currentCustomTrack?.id == track.id

        return Button {
            viewModel.playCustomTrack(track)
        } label: {
            HStack(spacing: 10) {
                // Source icon
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isPlaying ? AppConstants.accentColor.opacity(0.15) : Color.primary.opacity(0.04))
                        .frame(width: 32, height: 32)

                    if isPlaying && viewModel.audioPlayer.isPlaying {
                        playingIndicator
                    } else {
                        Image(systemName: track.source.iconName)
                            .font(.system(size: 12))
                            .foregroundStyle(isPlaying ? AppConstants.accentColor : .secondary)
                    }
                }

                // Track info
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.displayTitle)
                        .font(.system(size: 12, weight: isPlaying ? .semibold : .regular))
                        .foregroundStyle(isPlaying ? AppConstants.accentColor : .primary)
                        .lineLimit(1)

                    Text(track.displaySubtitle)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary.opacity(0.7))
                        .lineLimit(1)
                }

                Spacer()

                // Delete button
                Button {
                    withAnimation(.smooth(duration: 0.2)) {
                        viewModel.removeCustomTrack(track)
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isPlaying ? AppConstants.accentColor.opacity(0.06) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 6) {
            Spacer()
            Image(systemName: "music.note")
                .font(.system(size: 20))
                .foregroundStyle(.secondary.opacity(0.3))
            Text("No custom audio yet")
                .font(.system(size: 11))
                .foregroundStyle(.secondary.opacity(0.5))
            Text("Drop a file or paste a YouTube link above")
                .font(.system(size: 9))
                .foregroundStyle(.secondary.opacity(0.3))
            Spacer()
        }
        .frame(height: 100)
    }

    // MARK: - Playing Indicator

    private var playingIndicator: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(AppConstants.accentColor)
                    .frame(width: 2.5, height: 8)
                    .animation(
                        .easeInOut(duration: 0.4)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.15),
                        value: true
                    )
            }
        }
    }

    // MARK: - Actions

    private func saveTrack() {
        let title = metaTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let reciter = metaReciter.trimmingCharacters(in: .whitespacesAndNewlines)
        viewModel.savePendingTrack(
            title: title.isEmpty ? (viewModel.pendingImport?.defaultTitle ?? "Untitled") : title,
            reciterName: reciter.isEmpty ? nil : reciter,
            surahId: useSurahPicker ? metaSurahId : nil,
            qiraah: metaQiraah
        )
    }

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = audioTypes
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Select an audio file to import"

        if panel.runModal() == .OK, let url = panel.url {
            viewModel.addCustomTrackFromFile(url: url)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }

            let ext = url.pathExtension.lowercased()
            let audioExtensions = ["mp3", "m4a", "wav", "aac", "flac", "aiff", "ogg", "wma"]
            guard audioExtensions.contains(ext) else { return }

            Task { @MainActor in
                viewModel.addCustomTrackFromFile(url: url)
            }
        }
        return true
    }

    private func addFromYouTube() {
        let url = youtubeURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !url.isEmpty else { return }
        viewModel.addCustomTrackFromYouTube(urlString: url)
        youtubeURL = ""
    }
}

import SwiftUI
import AppKit

// MARK: - Native macOS Vibrancy View

/// Wraps NSVisualEffectView for real desktop-bleed-through vibrancy.
/// When using `.behindWindow` blending, automatically configures the
/// hosting window for transparency so the desktop actually shows through.
struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    var state: NSVisualEffectView.State
    var cornerRadius: CGFloat

    init(
        material: NSVisualEffectView.Material = .hudWindow,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        state: NSVisualEffectView.State = .active,
        cornerRadius: CGFloat = 0
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
        self.cornerRadius = cornerRadius
    }

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = _VibrancyEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        view.configureWindowVibrancy = (blendingMode == .behindWindow)
        view.wantsLayer = true
        view.layer?.cornerRadius = cornerRadius
        view.layer?.cornerCurve = .continuous
        if cornerRadius > 0 {
            view.layer?.masksToBounds = true
        }
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
        nsView.layer?.cornerRadius = cornerRadius
    }
}

// MARK: - Window-Configuring NSVisualEffectView

/// NSVisualEffectView subclass that configures its hosting window for
/// proper behind-window vibrancy when the view is added to the window.
private class _VibrancyEffectView: NSVisualEffectView {
    var configureWindowVibrancy = false

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard configureWindowVibrancy, let window = window else { return }

        // Make the window transparent so .behindWindow blending
        // actually shows the desktop content behind the window.
        window.isOpaque = false
        window.backgroundColor = .clear

        // Clear any opaque layer background on the content view
        // that could block the vibrancy effect.
        if let contentView = window.contentView {
            contentView.wantsLayer = true
            contentView.layer?.backgroundColor = .clear
        }
    }
}

// MARK: - Glass Background Modifier

/// Frosted glass panel: real vibrancy + tint overlay + highlight border.
struct GlassBackground: ViewModifier {
    var cornerRadius: CGFloat = 10
    var tint: Color = .white
    var tintOpacity: Double = 0.06
    var borderOpacity: Double = 0.12
    var material: Bool = true
    var innerGlass: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    if material {
                        if innerGlass {
                            // Within-window vibrancy for nested glass panels
                            VisualEffectBlur(
                                material: .popover,
                                blendingMode: .withinWindow,
                                state: .active,
                                cornerRadius: cornerRadius
                            )
                        } else {
                            VisualEffectBlur(
                                material: .hudWindow,
                                blendingMode: .withinWindow,
                                state: .active,
                                cornerRadius: cornerRadius
                            )
                        }
                    }

                    // Tint overlay
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(tint.opacity(tintOpacity))

                    // Border with top highlight (glass edge refraction)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(borderOpacity * 1.8),
                                    Color.white.opacity(borderOpacity * 0.4)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                }
            )
    }
}

extension View {
    func glassBackground(
        cornerRadius: CGFloat = 10,
        tint: Color = .white,
        tintOpacity: Double = 0.06,
        borderOpacity: Double = 0.12,
        material: Bool = true,
        innerGlass: Bool = false
    ) -> some View {
        modifier(GlassBackground(
            cornerRadius: cornerRadius,
            tint: tint,
            tintOpacity: tintOpacity,
            borderOpacity: borderOpacity,
            material: material,
            innerGlass: innerGlass
        ))
    }
}

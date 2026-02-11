import SwiftUI

/// Main background view that switches between different animation styles
struct BackgroundView: View {
    let state: BackgroundGameState
    @ObservedObject private var settings = GameSettings.shared

    var body: some View {
        ZStack {
            // Background based on selected style
            switch settings.backgroundStyle {
            case .livingGrid:
                LivingGridBackground(state: state)
            case .circuitTraces:
                CircuitTracesBackground(state: state)
            }

            // Scanline overlay with vignette
            ScanlineOverlay(includeVignette: true)
        }
        .animation(.easeInOut(duration: 0.5), value: settings.backgroundStyle)
    }
}

#Preview {
    BackgroundView(state: .menu)
}

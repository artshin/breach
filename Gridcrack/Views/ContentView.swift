import AppLogService
import SwiftUI

struct ContentView: View {
    @State private var backgroundState = BackgroundStateManager()
    @State private var transitionManager = TransitionManager()

    var body: some View {
        ZStack {
            BackgroundView(state: backgroundState.state)
                .ignoresSafeArea()

            NavigationStack {
                HomeView()
            }

            TransitionOverlay()
        }
        .environment(backgroundState)
        .environment(transitionManager)
        .onAppear {
            transitionManager.installTouchTracker()
            SoundManager.shared.switchAmbient(to: .menu)
            Logger.shared.info("App UI ready", tags: ["navigation"])
        }
        .onChange(of: backgroundState.state) { _, newState in
            switch newState {
            case .menu, .settings:
                SoundManager.shared.switchAmbient(to: .menu)
            case .game, .win, .loss:
                SoundManager.shared.switchAmbient(to: .game)
            }
        }
    }
}

#Preview {
    ContentView()
}

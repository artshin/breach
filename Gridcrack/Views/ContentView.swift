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
            SoundManager.shared.startAmbientLoop()
        }
    }
}

#Preview {
    ContentView()
}

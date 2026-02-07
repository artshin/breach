import SwiftUI

struct ContentView: View {
    @StateObject private var backgroundState = BackgroundStateManager()
    @StateObject private var transitionManager = TransitionManager()

    var body: some View {
        ZStack {
            BackgroundView(state: backgroundState.state)
                .ignoresSafeArea()

            NavigationStack {
                HomeView()
            }

            TransitionOverlay()
        }
        .environmentObject(backgroundState)
        .environmentObject(transitionManager)
    }
}

#Preview {
    ContentView()
}

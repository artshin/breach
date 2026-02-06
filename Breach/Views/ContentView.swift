import SwiftUI

struct ContentView: View {
    @StateObject private var backgroundState = BackgroundStateManager()

    var body: some View {
        ZStack {
            BackgroundView(state: backgroundState.state)
                .ignoresSafeArea()

            NavigationStack {
                HomeView()
            }
        }
        .environmentObject(backgroundState)
    }
}

#Preview {
    ContentView()
}

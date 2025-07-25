import SwiftUI

struct LaunchView: View {
    @State private var isLaunching = true
    @State private var showMainContent = false
    
    var body: some View {
        ZStack {
            if showMainContent {
                MainTabView()
                    .opacity(isLaunching ? 0 : 1)
                    .offset(y: isLaunching ? 50 : 0)
                    .animation(.easeOut(duration: 0.5), value: isLaunching)
            }
            
            if isLaunching {
                LaunchAnimationView {
                    handleLottieAnimationComplete()
                }
                .background(Color(.systemBackground))
                .ignoresSafeArea()
            }
        }
    }
    
    private func handleLottieAnimationComplete() {
        DispatchQueue.main.async {
            showMainContent = true
            
            withAnimation(.easeInOut(duration: 0.5)) {
                isLaunching = false
            }
        }
    }
}

#Preview {
    LaunchView()
} 

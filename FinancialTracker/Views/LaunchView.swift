import SwiftUI

struct LaunchView: View {
    @State private var isLaunching = true
    @State private var showMainContent = false
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0.0
    @State private var logoRotation: Double = 0.0
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0.0
    @State private var backgroundOpacity: Double = 1.0
    var body: some View {
        ZStack {
            if showMainContent {
                MainTabView()
                    .opacity(isLaunching ? 0 : 1)
                    .offset(y: isLaunching ? 50 : 0)
                    .animation(.easeOut(duration: 0.5), value: isLaunching)
            }
            
            if isLaunching {
                launchScreen
            }
        }
        .onAppear {
            startLaunchAnimation()
        }
    }
    
    private var launchScreen: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .opacity(backgroundOpacity)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 80, weight: .light))
                    .foregroundStyle(.accent)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .rotationEffect(.degrees(logoRotation))
                
                Text("FinancialTracker")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)
            }
        }
    }
    

    
    private func startLaunchAnimation() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0)) {
            logoScale = 1.0
            logoOpacity = 1.0
            logoRotation = 360
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                titleOffset = 0
                titleOpacity = 1.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            showMainContent = true
            
            withAnimation(.easeInOut(duration: 0.5)) {
                titleOpacity = 0.0
                titleOffset = -30
                backgroundOpacity = 0.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isLaunching = false
            }
        }
    }
}

#Preview {
    LaunchView()
} 
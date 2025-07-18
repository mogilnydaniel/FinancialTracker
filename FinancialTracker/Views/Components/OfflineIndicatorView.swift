import SwiftUI

struct OfflineIndicatorView: View {
    let isOffline: Bool
    
    var body: some View {
        if isOffline {
            HStack {
                Image(systemName: "wifi.slash")
                    .foregroundColor(.white)
                    .font(.caption)
                
                Text("Offline mode")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.white)
                    .font(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.red)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: isOffline)
        }
    }
}

struct OfflineIndicatorModifier: ViewModifier {
    @StateObject private var networkDetector = NetworkConnectionDetector.shared
    
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            content
            
            OfflineIndicatorView(isOffline: !networkDetector.isConnected)
        }
    }
}

extension View {
    func withOfflineIndicator() -> some View {
        modifier(OfflineIndicatorModifier())
    }
}

#Preview {
    VStack {
        Text("Main Content")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.1))
        
        OfflineIndicatorView(isOffline: true)
    }
} 
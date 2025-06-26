import SwiftUI

struct SpoilerView<Content: View>: View {
    @Binding var revealed: Bool
    let content: () -> Content
    
    var body: some View {
        content()
            .opacity(revealed ? 1 : 0)
            .overlay(
                SpoilerEmitterView(active: !revealed)
                    .opacity(revealed ? 0 : 1)
            )
            .animation(.easeInOut(duration: 0.25), value: revealed)
    }
} 
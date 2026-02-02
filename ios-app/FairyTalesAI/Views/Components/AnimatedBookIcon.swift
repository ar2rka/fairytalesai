import SwiftUI

struct AnimatedBookIcon: View {
    var body: some View {
        Image(systemName: "book.fill")
            .font(.system(size: 60))
            .frame(width: 80, height: 80) // Fixed frame to prevent layout shifts
    }
}

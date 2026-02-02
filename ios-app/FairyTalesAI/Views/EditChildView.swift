import SwiftUI

struct EditChildView: View {
    let child: Child
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        AddChildView(child: child)
    }
}

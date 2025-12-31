import Foundation
import SwiftUI

class ChildrenStore: ObservableObject {
    @Published var children: [Child] = []
    private let storageKey = "saved_children"
    
    var hasProfiles: Bool {
        !children.isEmpty
    }
    
    init() {
        loadChildren()
    }
    
    func addChild(_ child: Child) {
        children.append(child)
        saveChildren()
    }
    
    func updateChild(_ child: Child) {
        if let index = children.firstIndex(where: { $0.id == child.id }) {
            children[index] = child
            saveChildren()
        }
    }
    
    func deleteChild(_ child: Child) {
        children.removeAll { $0.id == child.id }
        saveChildren()
    }
    
    private func saveChildren() {
        if let encoded = try? JSONEncoder().encode(children) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadChildren() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Child].self, from: data) {
            children = decoded
        }
    }
}






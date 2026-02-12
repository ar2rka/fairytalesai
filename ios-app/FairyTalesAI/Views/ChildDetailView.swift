import SwiftUI

struct ChildDetailView: View {
    let child: Child
    @EnvironmentObject var childrenStore: ChildrenStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var showingEdit = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ZStack {
            AppTheme.backgroundColor(for: colorScheme).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        ChildAvatarView(child: child, size: 100)
                        
                        Text(child.name)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                        
                        Text(child.ageCategory.shortName + " (" + child.ageCategory.displayName + ")")
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                    }
                    .padding()
                    
                    // Interests
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Interests")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(child.interests, id: \.self) { interest in
                                if let interestObj = Interest.allInterests.first(where: { $0.name == interest }) {
                                    HeroInterestChip(name: interestObj.name, emoji: interestObj.emoji, isSelected: true, action: {})
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.top)
            }
        }
        .navigationTitle("Child Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Delete") {
                    showingDeleteAlert = true
                }
                .foregroundColor(.red)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEdit = true
                }
                .foregroundColor(AppTheme.primaryPurple)
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddChildView(child: child)
                .onDisappear {
                    Task {
                        await childrenStore.loadChildren()
                    }
                }
        }
        .alert("Delete Child", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await childrenStore.deleteChild(child)
                        dismiss()
                    } catch {
                        print("Error deleting child: \(error)")
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete \(child.name)? This action cannot be undone.")
        }
    }
}

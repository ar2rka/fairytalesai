import SwiftUI

struct ChildPickerView: View {
    @EnvironmentObject var childrenStore: ChildrenStore
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.darkPurple.ignoresSafeArea()
                
                if childrenStore.children.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 50))
                            .foregroundColor(AppTheme.textSecondary)
                        
                        Text("No children added yet")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Text("Add a child profile in Settings")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                } else {
                    List {
                        ForEach(childrenStore.children) { child in
                            HStack(spacing: 16) {
                                ChildAvatarView(child: child, size: 50)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(child.name)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(AppTheme.textPrimary)
                                    
                                    Text(child.ageCategory.displayName)
                                        .font(.system(size: 14))
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                dismiss()
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Select Child")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.primaryPurple)
                }
            }
        }
    }
}

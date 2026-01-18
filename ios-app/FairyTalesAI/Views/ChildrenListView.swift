import SwiftUI

struct ChildrenListView: View {
    @EnvironmentObject var childrenStore: ChildrenStore
    @Environment(\.colorScheme) var colorScheme
    @State private var showingAddChild = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundColor(for: colorScheme).ignoresSafeArea()
                
                if childrenStore.isLoading && childrenStore.children.isEmpty {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryPurple))
                } else if childrenStore.children.isEmpty {
                    VStack(spacing: 24) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 60))
                            .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                        
                        Text("No children added yet")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                        
                        Text("Add your first child to start creating personalized stories")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: { showingAddChild = true }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("Add a new child")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.primaryPurple)
                            .cornerRadius(AppTheme.cornerRadius)
                        }
                        .padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            Text("MY STORYTELLERS")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppTheme.primaryPurple)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                                .padding(.top)
                            
                            ForEach(childrenStore.children) { child in
                                NavigationLink(destination: ChildDetailView(child: child)) {
                                    ChildRowView(child: child)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            Button(action: { showingAddChild = true }) {
                                HStack {
                                    Image(systemName: "plus")
                                    Text("Add a new child")
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.primaryPurple)
                                .cornerRadius(AppTheme.cornerRadius)
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Profiles")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                    }
                }
            }
            .sheet(isPresented: $showingAddChild) {
                AddChildView()
                    .onDisappear {
                        Task {
                            await childrenStore.loadChildren()
                        }
                    }
            }
            .refreshable {
                await childrenStore.loadChildren()
            }
            .task {
                // Умная загрузка: использует кеш если он свежий
                await childrenStore.loadChildrenIfNeeded()
            }
        }
    }
}

struct ChildRowView: View {
    let child: Child
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppTheme.primaryPurple, AppTheme.accentPurple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .overlay(
                    Text(child.name.prefix(1).uppercased())
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(child.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                
                Text(child.ageCategory.shortName + " (" + child.ageCategory.displayName + ")")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary(for: colorScheme))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
        }
        .padding()
        .background(AppTheme.cardBackground(for: colorScheme))
        .cornerRadius(AppTheme.cornerRadius)
        .padding(.horizontal)
    }
}

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
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.primaryPurple, AppTheme.accentPurple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text(child.name.prefix(1).uppercased())
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        
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
                                    InterestChip(interest: interestObj, isSelected: true)
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



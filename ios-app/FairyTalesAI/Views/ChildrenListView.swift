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


import SwiftUI

struct GenerateStoryView: View {
    @EnvironmentObject var childrenStore: ChildrenStore
    @EnvironmentObject var storiesStore: StoriesStore
    
    @State private var selectedChildId: UUID? = nil
    @State private var storyLength: Double = 10
    @State private var selectedTheme: StoryTheme? = nil
    @State private var plot: String = ""
    @State private var showingStoryResult = false
    @State private var generatedStory: Story? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.darkPurple.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Who is listening?
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Who is listening?")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                            
                            if childrenStore.children.isEmpty {
                                NavigationLink(destination: AddChildView()) {
                                    HStack {
                                        Image(systemName: "plus")
                                        Text("Add a child first")
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppTheme.primaryPurple)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(AppTheme.cardBackground)
                                    .cornerRadius(16)
                                }
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(childrenStore.children) { child in
                                            ChildSelectionButton(
                                                child: child,
                                                isSelected: selectedChildId == child.id
                                            ) {
                                                selectedChildId = selectedChildId == child.id ? nil : child.id
                                            }
                                        }
                                        
                                        NavigationLink(destination: AddChildView()) {
                                            DashedButton(text: "NEW")
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Story Length
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Story Length")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                                
                                Spacer()
                                
                                Text("\(Int(storyLength)) min")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppTheme.primaryPurple)
                            }
                            
                            VStack(spacing: 8) {
                                Slider(value: $storyLength, in: 3...30, step: 1)
                                    .tint(AppTheme.primaryPurple)
                                
                                HStack {
                                    Text("Short (3m)")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.textSecondary)
                                    
                                    Spacer()
                                    
                                    Text("Epic (30m)")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Pick a Theme
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Pick a Theme")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(StoryTheme.allThemes) { theme in
                                    ThemeSelectionButton(
                                        theme: theme,
                                        isSelected: selectedTheme?.id == theme.id
                                    ) {
                                        selectedTheme = selectedTheme?.id == theme.id ? nil : theme
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Add a Spark (Optional)
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Add a Spark")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                                
                                Text("OPTIONAL")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(AppTheme.primaryPurple)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(AppTheme.primaryPurple.opacity(0.2))
                                    .cornerRadius(8)
                            }
                            
                            ZStack(alignment: .topLeading) {
                                if plot.isEmpty {
                                    Text("e.g. They find a tiny dragon who loves chocolate chip cookies and hates flying...")
                                        .foregroundColor(AppTheme.textSecondary)
                                        .padding()
                                }
                                
                                TextEditor(text: $plot)
                                    .foregroundColor(AppTheme.textPrimary)
                                    .scrollContentBackground(.hidden)
                                    .padding(8)
                                    .frame(minHeight: 100)
                                    .background(AppTheme.cardBackground)
                                    .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Weave the Tale Button
                        Button(action: generateStory) {
                            HStack {
                                Image(systemName: "sparkles")
                                Image(systemName: "sparkles")
                                Text("Weave the Tale")
                                    .font(.system(size: 18, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                canGenerate ?
                                AppTheme.primaryPurple : AppTheme.primaryPurple.opacity(0.5)
                            )
                            .cornerRadius(16)
                        }
                        .disabled(!canGenerate || storiesStore.isGenerating)
                        .padding(.horizontal)
                        .padding(.bottom, 100)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Create a Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {}) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(AppTheme.textPrimary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "wand.and.stars")
                            .foregroundColor(AppTheme.textPrimary)
                    }
                }
            }
            .sheet(isPresented: $showingStoryResult) {
                if let story = generatedStory {
                    StoryResultView(story: story)
                }
            }
        }
    }
    
    private var canGenerate: Bool {
        selectedChildId != nil && selectedTheme != nil
    }
    
    private func generateStory() {
        guard let theme = selectedTheme else { return }
        
        Task {
            await storiesStore.generateStory(
                childId: selectedChildId,
                length: Int(storyLength),
                theme: theme.name,
                plot: plot.isEmpty ? nil : plot,
                children: childrenStore.children
            )
            
            await MainActor.run {
                if let latestStory = storiesStore.stories.first {
                    generatedStory = latestStory
                    showingStoryResult = true
                }
            }
        }
    }
}

struct ChildSelectionButton: View {
    let child: Child
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(child.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .white : AppTheme.textPrimary)
                
                Text("Age \(child.ageCategory.rawValue)")
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : AppTheme.textSecondary)
            }
            .padding()
            .frame(width: 100)
            .background(isSelected ? AppTheme.primaryPurple : AppTheme.cardBackground)
            .cornerRadius(16)
            .overlay(
                Group {
                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                                    .padding(8)
                            }
                            Spacer()
                        }
                    }
                }
            )
        }
    }
}

struct DashedButton: View {
    let text: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .semibold))
            Text(text)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(AppTheme.primaryPurple)
        .padding()
        .frame(width: 100)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                .foregroundColor(AppTheme.primaryPurple)
        )
    }
}

struct ThemeSelectionButton: View {
    let theme: StoryTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(theme.emoji)
                    .font(.system(size: 40))
                
                VStack(spacing: 4) {
                    Text(theme.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isSelected ? .white : AppTheme.textPrimary)
                    
                    Text(theme.description)
                        .font(.system(size: 12))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : AppTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? AppTheme.primaryPurple : AppTheme.cardBackground)
            .cornerRadius(16)
            .overlay(
                Group {
                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                                    .padding(8)
                            }
                            Spacer()
                        }
                    }
                }
            )
        }
    }
}

struct StoryResultView: View {
    let story: Story
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var storiesStore: StoriesStore
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.darkPurple.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text(story.title)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Text(story.content)
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.textPrimary)
                            .lineSpacing(8)
                    }
                    .padding()
                }
            }
            .navigationTitle("Your Story")
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


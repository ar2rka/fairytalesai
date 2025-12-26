import SwiftUI

struct AddChildView: View {
    @EnvironmentObject var childrenStore: ChildrenStore
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var selectedAgeCategory: AgeCategory = .preschool
    @State private var selectedInterests: Set<String> = []
    @State private var showingAgePicker = false
    
    let child: Child?
    
    init(child: Child? = nil) {
        self.child = child
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.darkPurple.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Child's Name
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Child's Name")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)
                            
                            HStack {
                                TextField("e.g. Oliver", text: $name)
                                    .textFieldStyle(CustomTextFieldStyle())
                                
                                Image(systemName: "pencil")
                                    .foregroundColor(AppTheme.primaryPurple)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Age Group
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Age Group")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)
                            
                            Button(action: { showingAgePicker = true }) {
                                HStack {
                                    Text(selectedAgeCategory.displayName)
                                        .foregroundColor(selectedAgeCategory.displayName == "Select age range" ? AppTheme.textSecondary : AppTheme.textPrimary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(AppTheme.primaryPurple)
                                }
                                .padding()
                                .background(AppTheme.cardBackground)
                                .cornerRadius(AppTheme.cornerRadius)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Interests
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Interests")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppTheme.textPrimary)
                                
                                Spacer()
                                
                                Text("Pick at least 3")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(Interest.allInterests) { interest in
                                    InterestChip(
                                        interest: interest,
                                        isSelected: selectedInterests.contains(interest.name)
                                    ) {
                                        if selectedInterests.contains(interest.name) {
                                            selectedInterests.remove(interest.name)
                                        } else {
                                            selectedInterests.insert(interest.name)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Create Profile Button
                        Button(action: saveChild) {
                            HStack {
                                Text("Create Profile")
                                    .font(.system(size: 16, weight: .semibold))
                                Image(systemName: "arrow.right")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                selectedInterests.count >= 3 && !name.isEmpty ?
                                AppTheme.primaryPurple : AppTheme.primaryPurple.opacity(0.5)
                            )
                            .cornerRadius(AppTheme.cornerRadius)
                        }
                        .disabled(selectedInterests.count < 3 || name.isEmpty)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle(child == nil ? "Add Profile" : "Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.textPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChild()
                    }
                    .foregroundColor(AppTheme.primaryPurple)
                    .disabled(selectedInterests.count < 3 || name.isEmpty)
                }
            }
            .sheet(isPresented: $showingAgePicker) {
                AgePickerView(selectedAge: $selectedAgeCategory)
            }
            .onAppear {
                if let child = child {
                    name = child.name
                    selectedAgeCategory = child.ageCategory
                    selectedInterests = Set(child.interests)
                }
            }
        }
    }
    
    private func saveChild() {
        guard selectedInterests.count >= 3 && !name.isEmpty else { return }
        
        let interestsArray = Array(selectedInterests)
        
        if let existingChild = child {
            let updatedChild = Child(
                id: existingChild.id,
                name: name,
                ageCategory: selectedAgeCategory,
                interests: interestsArray,
                createdAt: existingChild.createdAt
            )
            childrenStore.updateChild(updatedChild)
        } else {
            let newChild = Child(
                name: name,
                ageCategory: selectedAgeCategory,
                interests: interestsArray
            )
            childrenStore.addChild(newChild)
        }
        
        dismiss()
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .foregroundColor(AppTheme.textPrimary)
    }
}

struct InterestChip: View {
    let interest: Interest
    let isSelected: Bool
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { action?() }) {
            VStack(spacing: 8) {
                Text(interest.emoji)
                    .font(.system(size: 32))
                
                Text(interest.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : AppTheme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? AppTheme.primaryPurple : AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? AppTheme.primaryPurple : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AgePickerView: View {
    @Binding var selectedAge: AgeCategory
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.darkPurple.ignoresSafeArea()
                
                List {
                    ForEach(AgeCategory.allCases, id: \.self) { age in
                        Button(action: {
                            selectedAge = age
                            dismiss()
                        }) {
                            HStack {
                                Text(age.displayName)
                                    .foregroundColor(AppTheme.textPrimary)
                                
                                Spacer()
                                
                                if selectedAge == age {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AppTheme.primaryPurple)
                                }
                            }
                        }
                        .listRowBackground(AppTheme.cardBackground)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Select Age Range")
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



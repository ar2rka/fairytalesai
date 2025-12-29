import SwiftUI

struct AddChildView: View {
    @EnvironmentObject var childrenStore: ChildrenStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var name: String = ""
    @State private var selectedGender: String = "boy"
    @State private var selectedAgeCategory: AgeCategory = .threeFive
    @State private var selectedInterests: Set<String> = []
    @State private var showingAgePicker = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let child: Child?
    
    init(child: Child? = nil) {
        self.child = child
    }
    
    private let genders = ["boy", "girl", "other"]
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundColor(for: colorScheme).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Child's Name
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Child's Name")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                            
                            HStack {
                                TextField("e.g. Oliver", text: $name)
                                    .textFieldStyle(CustomTextFieldStyle())
                                
                                Image(systemName: "pencil")
                                    .foregroundColor(AppTheme.primaryPurple)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Gender
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Gender")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                            
                            HStack(spacing: 12) {
                                ForEach(genders, id: \.self) { gender in
                                    Button(action: {
                                        selectedGender = gender
                                    }) {
                                        Text(gender.capitalized)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(selectedGender == gender ? .white : AppTheme.textPrimary(for: colorScheme))
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(selectedGender == gender ? AppTheme.primaryPurple : AppTheme.cardBackground(for: colorScheme))
                                            .cornerRadius(AppTheme.cornerRadius)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Age Group
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Age Group")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                            
                            Button(action: { showingAgePicker = true }) {
                                HStack {
                                    Text(selectedAgeCategory.displayName)
                                        .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(AppTheme.primaryPurple)
                                }
                                .padding()
                                .background(AppTheme.cardBackground(for: colorScheme))
                                .cornerRadius(AppTheme.cornerRadius)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Interests
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Interests")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                                
                                Spacer()
                                
                                Text("Pick at least 3")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.textSecondary(for: colorScheme))
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
                        
                        // Error Message
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }
                        
                        // Create Profile Button
                        Button(action: {
                            Task {
                                await saveChild()
                            }
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(child == nil ? "Create Profile" : "Update Profile")
                                        .font(.system(size: 16, weight: .semibold))
                                    Image(systemName: "arrow.right")
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                (selectedInterests.count >= 3 && !name.isEmpty && !isLoading) ?
                                AppTheme.primaryPurple : AppTheme.primaryPurple.opacity(0.5)
                            )
                            .cornerRadius(AppTheme.cornerRadius)
                        }
                        .disabled(selectedInterests.count < 3 || name.isEmpty || isLoading)
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
                    .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveChild()
                        }
                    }
                    .foregroundColor(AppTheme.primaryPurple)
                    .disabled(selectedInterests.count < 3 || name.isEmpty || isLoading)
                }
            }
            .sheet(isPresented: $showingAgePicker) {
                AgePickerView(selectedAge: $selectedAgeCategory)
            }
            .onAppear {
                if let child = child {
                    name = child.name
                    selectedGender = child.gender
                    selectedAgeCategory = child.ageCategory
                    selectedInterests = Set(child.interests)
                }
            }
        }
    }
    
    private func saveChild() async {
        guard selectedInterests.count >= 3 && !name.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        let interestsArray = Array(selectedInterests)
        
        do {
            if let existingChild = child {
                // Обновление существующего ребёнка в Supabase
                let updatedChild = Child(
                    id: existingChild.id,
                    name: name,
                    gender: selectedGender,
                    ageCategory: selectedAgeCategory,
                    interests: interestsArray,
                    userId: existingChild.userId,
                    createdAt: existingChild.createdAt,
                    updatedAt: Date()
                )
                try await childrenStore.updateChild(updatedChild)
                print("✅ Ребёнок успешно обновлён в Supabase: \(updatedChild.name)")
            } else {
                // Создание нового ребёнка в Supabase
                let newChild = Child(
                    name: name,
                    gender: selectedGender,
                    ageCategory: selectedAgeCategory,
                    interests: interestsArray
                )
                let createdChild = try await childrenStore.addChild(newChild)
                print("✅ Ребёнок успешно создан в Supabase: \(createdChild.name) (ID: \(createdChild.id))")
            }
            
            // Закрываем экран только после успешного сохранения
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Ошибка при сохранении ребёнка в Supabase: \(error.localizedDescription)")
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(AppTheme.cardBackground(for: colorScheme))
            .cornerRadius(AppTheme.cornerRadius)
            .foregroundColor(AppTheme.textPrimary(for: colorScheme))
    }
}

struct InterestChip: View {
    let interest: Interest
    let isSelected: Bool
    var action: (() -> Void)? = nil
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: { action?() }) {
            VStack(spacing: 8) {
                Text(interest.emoji)
                    .font(.system(size: 32))
                
                Text(interest.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : AppTheme.textPrimary(for: colorScheme))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? AppTheme.primaryPurple : AppTheme.cardBackground(for: colorScheme))
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
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundColor(for: colorScheme).ignoresSafeArea()
                
                List {
                    ForEach(AgeCategory.allCases, id: \.self) { age in
                        Button(action: {
                            selectedAge = age
                            dismiss()
                        }) {
                            HStack {
                                Text(age.displayName)
                                    .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                                
                                Spacer()
                                
                                if selectedAge == age {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AppTheme.primaryPurple)
                                }
                            }
                        }
                        .listRowBackground(AppTheme.cardBackground(for: colorScheme))
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



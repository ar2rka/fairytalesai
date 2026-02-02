import Foundation
import SwiftUI

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @AppStorage("selectedLanguage") var selectedLanguage: String = "English" {
        didSet {
            objectWillChange.send()
        }
    }
    
    var currentLanguage: String {
        selectedLanguage
    }
    
    var isRussian: Bool {
        selectedLanguage == "Russian"
    }
    
    // MARK: - Localized Strings
    
    // Tab Bar
    var tabHome: String { localized("Home", "Главная") }
    var tabLibrary: String { localized("Library", "Библиотека") }
    var tabCreate: String { localized("Create", "Создать") }
    var tabProfile: String { localized("Profile", "Профиль") }
    
    // Home View
    var homeWelcome: String { localized("Welcome", "Добро пожаловать") }
    var homeCreateMagicalStories: String { localized("Create Magical Stories", "Создавайте волшебные истории") }
    var homeFreeStories: String { localized("Free Stories", "Бесплатные истории") }
    var homeWhoIsListening: String { localized("Who is listening?", "Кто слушает?") }
    var homeManage: String { localized("Manage", "Управление") }
    var homeWhoIsOurHero: String { localized("Who is our hero today?", "Кто наш герой сегодня?") }
    var homeAddProfile: String { localized("Add Profile", "Добавить профиль") }
    var homeAddProfileDescription: String { localized("Add a profile to start the adventure.", "Добавьте профиль, чтобы начать приключение.") }
    var homeAdd: String { localized("Add", "Добавить") }
    var homeRecentMagic: String { localized("Recent Magic", "Недавняя магия") }
    var homeViewAll: String { localized("View All", "Смотреть все") }
    var homePopularThemes: String { localized("Popular Themes", "Популярные темы") }
    var homeSparkNewAdventure: String { localized("Spark a New Adventure", "Зажги новое приключение") }
    var homeCreateNewTale: String { localized("Create New Tale", "Создать новую сказку") }
    var homeEveryStoryNeedsHero: String { localized("Every story needs a hero. Add your child to start the magic!", "Каждой истории нужен герой. Добавьте вашего ребенка, чтобы начать магию!") }
    var homeAddChildProfile: String { localized("Add Child Profile", "Добавить профиль ребенка") }
    
    // Settings View
    var settingsAccount: String { localized("Account", "Аккаунт") }
    var settingsChildren: String { localized("CHILDREN", "ДЕТИ") }
    var settingsAppExperience: String { localized("APP EXPERIENCE", "ОПЫТ ПРИЛОЖЕНИЯ") }
    var settingsPushNotifications: String { localized("Push Notifications", "Push-уведомления") }
    var settingsSoundEffects: String { localized("Sound Effects", "Звуковые эффекты") }
    var settingsAppearance: String { localized("Appearance", "Внешний вид") }
    var settingsLanguage: String { localized("Language", "Язык") }
    var settingsMembership: String { localized("MEMBERSHIP", "ПОДПИСКА") }
    var settingsStorytellerPro: String { localized("Storyteller Pro", "Storyteller Pro") }
    var settingsActivePlan: String { localized("Active Plan", "Активный план") }
    var settingsManageSubscription: String { localized("Manage Subscription", "Управление подпиской") }
    var settingsSpreadTheMagic: String { localized("SPREAD THE MAGIC", "РАСПРОСТРАНИТЕ МАГИЮ") }
    var settingsInviteParentFriend: String { localized("Invite a Parent Friend", "Пригласить друга-родителя") }
    var settingsGiveMagicGetCredits: String { localized("Give magic, get credits", "Дарите магию, получайте кредиты") }
    var settingsSupportLegal: String { localized("SUPPORT & LEGAL", "ПОДДЕРЖКА И ПРАВО") }
    var settingsHelpCenter: String { localized("Help Center", "Центр помощи") }
    var settingsPrivacyPolicy: String { localized("Privacy Policy", "Политика конфиденциальности") }
    var settingsTermsOfService: String { localized("Terms of Service", "Условия использования") }
    var settingsLogOut: String { localized("Log Out", "Выйти") }
    var settingsLogOutAlert: String { localized("Sign out of account?", "Выйти из аккаунта?") }
    var settingsCancel: String { localized("Cancel", "Отмена") }
    var settingsLogOutConfirm: String { localized("Sign Out", "Выйти") }
    var settingsSaveMagicForever: String { localized("✨ Save the Magic Forever", "✨ Сохраните магию навсегда") }
    var settingsSyncProfiles: String { localized("Sync profiles and stories across all your devices.", "Синхронизируйте профили и истории на всех ваших устройствах.") }
    var settingsSignIn: String { localized("Sign In", "Войти") }
    var settingsCreateAccount: String { localized("Create Account", "Создать аккаунт") }
    var settingsAddNewChild: String { localized("Add a new child", "Добавить нового ребенка") }
    
    // Add Child View
    var addChildCreateHero: String { localized("Create Hero", "Создать героя") }
    var addChildNameOfHero: String { localized("Name of the Hero", "Имя героя") }
    var addChildEnterHeroName: String { localized("Enter hero's name", "Введите имя героя") }
    var addChildHeroType: String { localized("Hero Type", "Тип героя") }
    var addChildAgeGroup: String { localized("Age Group", "Возрастная группа") }
    var addChildMagicIngredients: String { localized("The Magic Ingredients", "Волшебные ингредиенты") }
    var addChildSelectInterests: String { localized("Select interests to personalize stories", "Выберите интересы для персонализации историй") }
    var addChildCancel: String { localized("Cancel", "Отмена") }
    var addChildSave: String { localized("Save", "Сохранить") }
    
    // Generate Story View
    var generateStoryCreateStory: String { localized("Create Story", "Создать историю") }
    var generateStoryWhoIsListening: String { localized("Who is listening?", "Кто слушает?") }
    var generateStoryLoadingChildren: String { localized("Loading children...", "Загрузка детей...") }
    var generateStoryAddChildFirst: String { localized("Add a child first", "Сначала добавьте ребенка") }
    var generateStoryNew: String { localized("NEW", "НОВЫЙ") }
    var generateStoryDuration: String { localized("Duration", "Длительность") }
    var generateStoryMin: String { localized("min", "мин") }
    var generateStoryPremium: String { localized("Premium", "Премиум") }
    var generateStoryFreeUpTo5: String { localized("Free: up to 5 min", "Бесплатно: до 5 мин") }
    var generateStoryPremiumUpTo30: String { localized("Premium: up to 30 min", "Премиум: до 30 мин") }
    var generateStoryChooseTheme: String { localized("Choose a Theme", "Выберите тему") }
    var generateStoryBriefPlot: String { localized("Brief Plot", "Краткий сюжет") }
    var generateStoryDescribeStory: String { localized("Describe the story you want to create...", "Опишите историю, которую хотите создать...") }
    var generateStoryGenerating: String { localized("Generating...", "Генерация...") }
    var generateStoryGenerateStory: String { localized("Generate Story", "Создать историю") }
    var generateStoryWhoIsHeroToday: String { localized("Who is the hero today?", "Кто герой сегодня?") }
    var generateStoryNeedProfile: String { localized("You need to add a child profile before we can craft a tale.", "Вам нужно добавить профиль ребенка, прежде чем мы сможем создать сказку.") }
    var generateStoryCreateProfile: String { localized("Create a Profile", "Создать профиль") }
    
    // Library View
    var libraryMyLibrary: String { localized("My Library", "Моя библиотека") }
    var libraryLoadingStories: String { localized("Loading stories...", "Загрузка историй...") }
    var libraryNoStoriesYet: String { localized("No stories yet", "Историй пока нет") }
    var libraryCreateFirstStory: String { localized("Create your first magical story", "Создайте свою первую волшебную историю") }
    var librarySearchStories: String { localized("Search stories, characters...", "Поиск историй, персонажей...") }
    var libraryAllStories: String { localized("All Stories", "Все истории") }
    var libraryBedtime: String { localized("Bedtime", "Перед сном") }
    var libraryAdventure: String { localized("Adventure", "Приключение") }
    var libraryFantasy: String { localized("Fantasy", "Фэнтези") }
    var libraryNoStoriesFound: String { localized("No stories found", "Истории не найдены") }
    var libraryLoadingMore: String { localized("Loading more stories...", "Загрузка дополнительных историй...") }
    var libraryFor: String { localized("For:", "Для:") }
    var libraryRead: String { localized("Read", "Читать") }
    var libraryDayAgo: String { localized("day ago", "день назад") }
    var libraryDaysAgo: String { localized("days ago", "дней назад") }
    var libraryWeekAgo: String { localized("week ago", "неделя назад") }
    var libraryWeeksAgo: String { localized("weeks ago", "недель назад") }
    var libraryMonthAgo: String { localized("month ago", "месяц назад") }
    var libraryMonthsAgo: String { localized("months ago", "месяцев назад") }
    var libraryLongAgo: String { localized("Long ago", "Давно") }
    var libraryMinRead: String { localized("min read", "мин чтения") }
    var libraryUnknown: String { localized("Unknown", "Неизвестно") }
    var libraryDeleteStory: String { localized("Delete", "Удалить") }
    var libraryDeleteStoryConfirm: String { localized("Delete this story?", "Удалить эту историю?") }
    
    // Story Reading View
    var storyReadingStory: String { localized("Story", "История") }
    var storyReadingListen: String { localized("Listen", "Слушать") }
    var storyReadingListenPremium: String { localized("Listen (Premium)", "Слушать (Премиум)") }
    
    // Age Categories
    var ageToddler: String { localized("Toddler", "Малыш") }
    var agePreschool: String { localized("Preschool", "Дошкольник") }
    var ageExplorer: String { localized("Explorer", "Исследователь") }
    var ageBigKid: String { localized("Big Kid", "Большой ребенок") }
    var ageYears: String { localized("years", "лет") }
    var ageToddlerRange: String { localized("1-2 years", "1-2 года") }
    var agePreschoolRange: String { localized("3-5 years", "3-5 лет") }
    var ageExplorerRange: String { localized("6-8 years", "6-8 лет") }
    var ageBigKidRange: String { localized("9+ years", "9+ лет") }
    
    // Story Styles
    var styleHero: String { localized("The Hero", "Герой") }
    var styleBoy: String { localized("Boy", "Мальчик") }
    var styleGirl: String { localized("Girl", "Девочка") }
    
    // Language Selection
    var languageSelectionTitle: String { localized("Language", "Язык") }
    var languageEnglish: String { localized("English", "Английский") }
    var languageRussian: String { localized("Russian", "Русский") }
    
    // Interests
    var interestDinosaurs: String { localized("Dinosaurs", "Динозавры") }
    var interestSpace: String { localized("Space", "Космос") }
    var interestUnicorns: String { localized("Unicorns", "Единороги") }
    var interestCastles: String { localized("Castles", "Замки") }
    var interestMystery: String { localized("Mystery", "Тайна") }
    var interestAnimals: String { localized("Animals", "Животные") }
    
    // Story Themes
    var themeSpace: String { localized("Space", "Космос") }
    var themeSpaceDesc: String { localized("Galaxies & Aliens", "Галактики и инопланетяне") }
    var themePirates: String { localized("Pirates", "Пираты") }
    var themePiratesDesc: String { localized("Treasure & Adventure", "Сокровища и приключения") }
    var themeDinosaurs: String { localized("Dinosaurs", "Динозавры") }
    var themeDinosaursDesc: String { localized("Prehistoric Adventures", "Доисторические приключения") }
    var themeMermaids: String { localized("Mermaids", "Русалки") }
    var themeMermaidsDesc: String { localized("Ocean Magic", "Океанская магия") }
    var themeAnimals: String { localized("Animals", "Животные") }
    var themeAnimalsDesc: String { localized("Forest Friends", "Лесные друзья") }
    var themeMystery: String { localized("Mystery", "Тайна") }
    var themeMysteryDesc: String { localized("Clues & Secrets", "Подсказки и секреты") }
    var themeMagicSchool: String { localized("Magic School", "Школа магии") }
    var themeMagicSchoolDesc: String { localized("Wizardry & Spells", "Колдовство и заклинания") }
    var themeRobots: String { localized("Robots", "Роботы") }
    var themeRobotsDesc: String { localized("Tech Adventures", "Технические приключения") }
    
    // Protagonist Style Selector
    var styleSelectorCaption: String { localized("The Hero style focuses on your child's name for a classic story feel.", "Стиль Герой фокусируется на имени вашего ребенка для классического ощущения истории.") }
    
    // Helper function
    private func localized(_ english: String, _ russian: String) -> String {
        return isRussian ? russian : english
    }
    
    // Helper to get localized theme name
    func localizedThemeName(_ themeName: String) -> String {
        switch themeName.lowercased() {
        case "space": return themeSpace
        case "pirates": return themePirates
        case "dinosaurs": return themeDinosaurs
        case "mermaids": return themeMermaids
        case "animals": return themeAnimals
        case "mystery": return themeMystery
        case "magic school": return themeMagicSchool
        case "robots": return themeRobots
        default: return themeName
        }
    }
}

// Extension for easy access
extension View {
    var localizer: LocalizationManager {
        LocalizationManager.shared
    }
}

import Foundation
import Supabase

struct SupabaseConfig {
    // TODO: Замените эти значения на ваши реальные данные из Supabase проекта
    // Получить можно в Dashboard: https://app.supabase.com/project/_/settings/api
    static let supabaseURL = "https://yefsocnfbcdyuajaanaz.supabase.co"
    static let supabaseKey = "sb_publishable_7zRmYEEijPp4ZegMMi55Rg_GNyLY-eM"
    
    // Проверка что конфигурация заполнена
    static var isConfigured: Bool {
        return supabaseURL != "YOUR_SUPABASE_URL" && supabaseKey != "YOUR_SUPABASE_ANON_KEY"
    }
    
    /// Единый экземпляр SupabaseClient, используемый всеми сервисами.
    static let client: SupabaseClient? = {
        guard isConfigured, let url = URL(string: supabaseURL) else { return nil }
        return SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseKey,
            options: SupabaseClientOptions(
                db: .init(schema: "tales"),
                auth: .init(emitLocalSessionAsInitialSession: true)
            )
        )
    }()
}


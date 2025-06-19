import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        let supabaseURL = URL(string: "https://mymolgiisjudhulylglq.supabase.co")!
        let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im15bW9sZ2lpc2p1ZGh1bHlsZ2xxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkwODYwNzEsImV4cCI6MjA2NDY2MjA3MX0.qXFdfR0OsDp8FZ8-KcSUxOD5LTLwN_CWdSh6Tc0NC9g"

        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseAnonKey
        )
    }
} 
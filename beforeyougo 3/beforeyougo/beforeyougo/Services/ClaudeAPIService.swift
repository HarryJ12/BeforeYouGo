import Foundation

// MARK: - Claude API Service
class ClaudeAPIService {
    static let shared = ClaudeAPIService()
    
    // ⚠️ REPLACE WITH YOUR API KEY
    private let apiKey = "YOUR_CLAUDE_API_KEY_HERE"
    private let model = "claude-sonnet-4-20250514"
    private let baseURL = "https://api.anthropic.com/v1/messages"
    
    private init() {}
    
    // MARK: - Generic Message Send
    func sendMessage(system: String, messages: [[String: String]], maxTokens: Int = 1024) async throws -> String {
        guard let url = URL(string: baseURL) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "system": system,
            "messages": messages
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw APIError.serverError(statusCode)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let content = json?["content"] as? [[String: Any]],
              let text = content.first?["text"] as? String else {
            throw APIError.parseError
        }
        
        return text
    }
    
    // MARK: - Journal Conversation
    func journalConversation(userMessage: String, conversationHistory: [[String: String]]) async throws -> String {
        let system = """
        You are a caring health companion AI in the BeforeYouGo app. You're conducting a nightly check-in with the user about their day and health.
        
        Your goals:
        1. Ask about how they're feeling physically and emotionally
        2. Note any symptoms, changes, or concerns
        3. Ask about activities, diet, sleep, and exercise
        4. Be warm, empathetic, and conversational
        5. After gathering enough info (3-4 exchanges), provide a brief summary of what you logged
        
        Keep responses concise (2-3 sentences). Don't be overly clinical. Be like a thoughtful friend who happens to understand health well.
        
        When you've gathered enough information, end your message with a JSON block like:
        ```json
        {"mood": "good/fair/poor", "symptoms": ["list"], "activities": ["list"], "summary": "brief summary"}
        ```
        """
        
        var messages = conversationHistory
        messages.append(["role": "user", "content": userMessage])
        
        return try await sendMessage(system: system, messages: messages)
    }
    
    // MARK: - Appointment Prep Generation
    func generateAppointmentPrep(
        appointment: Appointment,
        healthData: [String],
        journalEntries: [String],
        medications: [String],
        conditions: [String]
    ) async throws -> AppointmentPrep {
        let system = """
        You are a health preparation assistant. Generate appointment preparation materials based on the user's health data, journal entries, medications, and conditions.
        
        Respond ONLY with valid JSON (no markdown, no backticks) in this exact format:
        {
            "whatToMention": ["item1", "item2", "item3"],
            "questionsToAsk": ["question1", "question2", "question3"],
            "summary": "A brief paragraph summarizing key health points to discuss"
        }
        
        Make items specific, actionable, and based on the provided data. Include 4-6 items in each list.
        """
        
        let userMessage = """
        Appointment Details:
        - Doctor: \(appointment.doctorName)
        - Specialty: \(appointment.specialty)
        - Reason: \(appointment.reason)
        - Date: \(appointment.date.formatted(date: .long, time: .omitted))
        
        Recent Health Data:
        \(healthData.joined(separator: "\n"))
        
        Recent Journal Entries:
        \(journalEntries.joined(separator: "\n"))
        
        Current Medications:
        \(medications.isEmpty ? "None listed" : medications.joined(separator: ", "))
        
        Conditions:
        \(conditions.isEmpty ? "None listed" : conditions.joined(separator: ", "))
        
        Generate appointment preparation materials.
        """
        
        let response = try await sendMessage(
            system: system,
            messages: [["role": "user", "content": userMessage]],
            maxTokens: 1500
        )
        
        // Parse JSON response
        guard let data = response.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let whatToMention = json["whatToMention"] as? [String],
              let questionsToAsk = json["questionsToAsk"] as? [String],
              let summary = json["summary"] as? String else {
            // Fallback: return the raw text as summary
            return AppointmentPrep(
                whatToMention: ["Review recent symptoms", "Discuss medication effectiveness", "Ask about preventive screenings"],
                questionsToAsk: ["Are there any lifestyle changes you'd recommend?", "Should I schedule any follow-up tests?", "Are my current medications still appropriate?"],
                summary: response
            )
        }
        
        return AppointmentPrep(whatToMention: whatToMention, questionsToAsk: questionsToAsk, summary: summary)
    }
    
    // MARK: - Post-Visit Translation
    func translatePostVisitSummary(rawText: String) async throws -> PostVisitSummary {
        let system = """
        You are a medical document translator. Convert clinical/medical text from a doctor's visit into plain, easy-to-understand language.
        
        Respond ONLY with valid JSON (no markdown, no backticks) in this exact format:
        {
            "whatDoctorFound": "Plain language explanation of findings/diagnosis",
            "whatThisMeans": "What this means for the patient's health in everyday terms",
            "whatToDo": "Clear action items and next steps"
        }
        
        Use simple language. Avoid medical jargon. Be reassuring but honest.
        """
        
        let response = try await sendMessage(
            system: system,
            messages: [["role": "user", "content": "Please translate this visit summary into plain language:\n\n\(rawText)"]],
            maxTokens: 1500
        )
        
        guard let data = response.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let found = json["whatDoctorFound"] as? String,
              let means = json["whatThisMeans"] as? String,
              let todo = json["whatToDo"] as? String else {
            return PostVisitSummary(rawText: rawText, whatDoctorFound: response, whatThisMeans: "", whatToDo: "")
        }
        
        return PostVisitSummary(rawText: rawText, whatDoctorFound: found, whatThisMeans: means, whatToDo: todo)
    }
    
    // MARK: - Health Insight Generation
    func generateInsights(healthData: [String], journalEntries: [String]) async throws -> [AIInsight] {
        let system = """
        You are a health insights AI. Analyze the user's health data and journal entries to generate 3 brief, actionable insights.
        
        Respond ONLY with valid JSON (no markdown, no backticks) as an array:
        [
            {"title": "Short title", "body": "1-2 sentence insight", "icon": "SF Symbol name", "accent": "green/yellow/blue"},
            ...
        ]
        
        Use these SF Symbol names: heart.fill, figure.walk, moon.fill, leaf.fill, brain.head.profile, drop.fill
        """
        
        let userMessage = """
        Health Data (last 7 days):
        \(healthData.joined(separator: "\n"))
        
        Journal Entries:
        \(journalEntries.joined(separator: "\n"))
        """
        
        let response = try await sendMessage(
            system: system,
            messages: [["role": "user", "content": userMessage]],
            maxTokens: 800
        )
        
        guard let data = response.data(using: .utf8),
              let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] else {
            return [
                AIInsight(title: "Stay Active", body: "Your activity levels look good. Keep it up!", icon: "figure.walk", accentColor: "green"),
                AIInsight(title: "Sleep Patterns", body: "Try to maintain a consistent sleep schedule.", icon: "moon.fill", accentColor: "blue")
            ]
        }
        
        return jsonArray.compactMap { dict in
            guard let title = dict["title"], let body = dict["body"], let icon = dict["icon"], let accent = dict["accent"] else { return nil }
            return AIInsight(title: title, body: body, icon: icon, accentColor: accent)
        }
    }
    
    // MARK: - Errors
    enum APIError: LocalizedError {
        case invalidURL
        case serverError(Int)
        case parseError
        
        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid API URL"
            case .serverError(let code): return "Server error: \(code)"
            case .parseError: return "Failed to parse response"
            }
        }
    }
}

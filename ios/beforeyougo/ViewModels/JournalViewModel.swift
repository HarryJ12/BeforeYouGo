import Foundation
import Combine
@MainActor
class JournalViewModel: ObservableObject {
    @Published var entries: [JournalEntry] = []
    @Published var messages: [ChatMessage] = []
    @Published var currentInput = ""
    @Published var isLoading = false
    @Published var isChatActive = false
    @Published var showChat = false
    
    private let claude = ClaudeAPIService.shared
    private let backend = BackendAPIService.shared
    private var conversationHistory: [[String: String]] = []
    
    init() {
        loadMockEntries()
    }
    
    // MARK: - Start Check-In
    func startCheckIn() {
        messages = []
        conversationHistory = []
        isChatActive = true
        showChat = true
        
        // AI greeting
        let greeting = ChatMessage(role: .assistant, content: "Hey! How are you feeling today? Anything on your mind — physically or emotionally?")
        messages.append(greeting)
    }
    
    // MARK: - Send Message
    func sendMessage() async {
        let text = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)
        currentInput = ""
        isLoading = true
        
        do {
            let response = try await claude.journalConversation(
                userMessage: text,
                conversationHistory: conversationHistory
            )
            
            // Update conversation history
            conversationHistory.append(["role": "user", "content": text])
            conversationHistory.append(["role": "assistant", "content": response])
            
            let aiMessage = ChatMessage(role: .assistant, content: cleanResponse(response))
            messages.append(aiMessage)
            
            // Check if AI has extracted structured data
            if let jsonData = extractJSON(from: response) {
                let entry = JournalEntry(
                    mood: jsonData["mood"] as? String ?? "fair",
                    symptoms: jsonData["symptoms"] as? [String] ?? [],
                    activities: jsonData["activities"] as? [String] ?? [],
                    notes: text,
                    aiSummary: jsonData["summary"] as? String ?? ""
                )
                entries.insert(entry, at: 0)
                
                // Send to backend
                try? await backend.sendJournalEntry(entry)
            }
        } catch {
            let errorMsg = ChatMessage(role: .assistant, content: "I'm having trouble connecting right now. Could you try again in a moment?")
            messages.append(errorMsg)
        }
        
        isLoading = false
    }
    
    // MARK: - Quick Log
    func quickLog(mood: String, symptoms: [String]) {
        let entry = JournalEntry(
            mood: mood,
            symptoms: symptoms,
            notes: "Quick log",
            aiSummary: "User reported feeling \(mood). \(symptoms.isEmpty ? "No symptoms noted." : "Symptoms: \(symptoms.joined(separator: ", ")).")"
        )
        entries.insert(entry, at: 0)
        
        Task {
            try? await backend.sendJournalEntry(entry)
        }
    }
    
    // MARK: - Summaries for AI Prep
    func recentEntrySummaries(count: Int = 5) -> [String] {
        entries.prefix(count).map { entry in
            "\(entry.date.formatted(date: .abbreviated, time: .omitted)): Mood: \(entry.mood). \(entry.aiSummary)"
        }
    }
    
    // MARK: - Helpers
    private func cleanResponse(_ response: String) -> String {
        // Remove JSON block from display
        if let range = response.range(of: "```json") {
            return String(response[response.startIndex..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let range = response.range(of: "{\"mood\"") {
            return String(response[response.startIndex..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return response
    }
    
    private func extractJSON(from text: String) -> [String: Any]? {
        // Try to find JSON in response
        let patterns = [
            try? NSRegularExpression(pattern: "```json\\s*(.+?)\\s*```", options: .dotMatchesLineSeparators),
            try? NSRegularExpression(pattern: "(\\{\"mood\".*\\})", options: .dotMatchesLineSeparators)
        ]
        
        for pattern in patterns.compactMap({ $0 }) {
            if let match = pattern.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: text) {
                let jsonString = String(text[range])
                if let data = jsonString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    return json
                }
            }
        }
        return nil
    }
    
    private func loadMockEntries() {
        let calendar = Calendar.current
        entries = [
            JournalEntry(
                date: calendar.date(byAdding: .day, value: -1, to: Date())!,
                mood: "good",
                symptoms: [],
                activities: ["Swimming", "Study session"],
                notes: "Felt strong during swim training. Had a productive study session for linear algebra.",
                aiSummary: "Good day overall. Active with swim training and academic work. No health concerns noted."
            ),
            JournalEntry(
                date: calendar.date(byAdding: .day, value: -2, to: Date())!,
                mood: "fair",
                symptoms: ["Mild headache", "Fatigue"],
                activities: ["Running", "Research lab"],
                notes: "Woke up with a headache. Still pushed through a 5-mile run. Long day at the lab.",
                aiSummary: "Experienced headache and fatigue but maintained activity level. May want to monitor hydration and sleep quality."
            ),
            JournalEntry(
                date: calendar.date(byAdding: .day, value: -4, to: Date())!,
                mood: "great",
                symptoms: [],
                activities: ["Cycling", "Hackathon prep"],
                notes: "Great energy today. 30-mile bike ride and solid hackathon preparation.",
                aiSummary: "Excellent energy and mood. High activity day with cycling and productive coding session."
            )
        ]
    }
}

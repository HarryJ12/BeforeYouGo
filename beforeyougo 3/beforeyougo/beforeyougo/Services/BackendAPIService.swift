import Foundation

// MARK: - Backend API Service
class BackendAPIService {
    static let shared = BackendAPIService()
    
    // ⚠️ UPDATE WITH YOUR LARAVEL API BASE URL
    private let baseURL = "http://10.105.4.212:8000"
    
    private init() {}
    
    // MARK: - Generic Request
    private func request<T: Decodable>(
        path: String,
        method: String = "GET",
        body: [String: Any]? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw APIError.serverError(statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }
    
    // MARK: - Onboarding
    func submitOnboarding(name: String, dob: Date, location: String, path: String) async throws {
        let body: [String: Any] = [
            "name": name,
            "date_of_birth": ISO8601DateFormatter().string(from: dob),
            "location": location,
            "path": path
        ]
        let _: EmptyResponse = try await request(path: "/api/onboarding", method: "POST", body: body)
    }
    
    // MARK: - Health Data
    func sendHealthData(_ data: [String: Any]) async throws {
        let _: EmptyResponse = try await request(path: "/api/health-data", method: "POST", body: data)
    }
    
    // MARK: - Journal
    func sendJournalEntry(_ entry: JournalEntry) async throws {
        let body: [String: Any] = [
            "id": entry.id.uuidString,
            "date": ISO8601DateFormatter().string(from: entry.date),
            "mood": entry.mood,
            "symptoms": entry.symptoms,
            "activities": entry.activities,
            "notes": entry.notes,
            "ai_summary": entry.aiSummary
        ]
        let _: EmptyResponse = try await request(path: "/api/journal-entry", method: "POST", body: body)
    }
    
    // MARK: - Appointments
    func createAppointment(_ appointment: Appointment) async throws {
        let body: [String: Any] = [
            "id": appointment.id.uuidString,
            "doctor_name": appointment.doctorName,
            "specialty": appointment.specialty,
            "date": ISO8601DateFormatter().string(from: appointment.date),
            "time": appointment.time,
            "reason": appointment.reason,
            "location": appointment.location
        ]
        let _: EmptyResponse = try await request(path: "/api/appointments", method: "POST", body: body)
    }
    
    func getAppointmentPrep(id: UUID) async throws -> AppointmentPrep {
        return try await request(path: "/api/appointments/\(id.uuidString)/prep")
    }
    
    // MARK: - Post-Visit Upload
    func uploadVisitSummary(imageData: Data) async throws -> PostVisitSummary {
        // For OCR, we send base64 image data
        let body: [String: Any] = [
            "image": imageData.base64EncodedString()
        ]
        return try await request(path: "/api/upload-summary", method: "POST", body: body)
    }
    
    // MARK: - Providers
    func searchProviders(specialty: String, distance: Double, insuranceOnly: Bool) async throws -> [Provider] {
        let query = "?specialty=\(specialty.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&distance=\(distance)&insurance_only=\(insuranceOnly)"
        return try await request(path: "/api/providers/search\(query)")
    }
    
    // MARK: - Insurance
    func uploadInsuranceCard(frontData: Data, backData: Data?) async throws -> InsuranceInfo {
        var body: [String: Any] = [
            "front_image": frontData.base64EncodedString()
        ]
        if let backData = backData {
            body["back_image"] = backData.base64EncodedString()
        }
        return try await request(path: "/api/insurance-card", method: "POST", body: body)
    }
    
    // MARK: - Insights
    func fetchInsights() async throws -> [AIInsight] {
        // This endpoint may not exist yet — fall back to Claude API
        return []
    }
    
    // MARK: - Types
    struct EmptyResponse: Decodable {}
    
    enum APIError: LocalizedError {
        case invalidURL
        case serverError(Int)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid URL"
            case .serverError(let code): return "Server error: \(code)"
            }
        }
    }
}

import Foundation
import SwiftUI
import PhotosUI
import Combine

@MainActor
class AppointmentViewModel: ObservableObject {
    @Published var appointments: [Appointment] = []
    @Published var selectedAppointment: Appointment?
    @Published var isGeneratingPrep = false
    @Published var isProcessingOCR = false
    @Published var showAddSheet = false
    @Published var showPrepView = false
    @Published var showPostVisitSheet = false
    @Published var showCamera = false
    @Published var capturedImage: UIImage?
    @Published var errorMessage: String?
    
    // Add appointment form
    @Published var newDoctorName = ""
    @Published var newSpecialty = ""
    @Published var newDate = Date()
    @Published var newTime = "10:00 AM"
    @Published var newReason = ""
    @Published var newLocation = ""
    
    private let claude = ClaudeAPIService.shared
    private let backend = BackendAPIService.shared
    private let ocr = OCRService.shared
    
    init() {
        // Load mock data for demo
        loadMockData()
    }
    
    // MARK: - CRUD
    func addAppointment() {
        let appointment = Appointment(
            doctorName: newDoctorName,
            specialty: newSpecialty,
            date: newDate,
            time: newTime,
            reason: newReason,
            location: newLocation
        )
        appointments.append(appointment)
        appointments.sort { $0.date < $1.date }
        
        // Send to backend
        Task {
            try? await backend.createAppointment(appointment)
        }
        
        clearForm()
    }
    
    func deleteAppointment(_ appointment: Appointment) {
        appointments.removeAll { $0.id == appointment.id }
    }
    
    var upcomingAppointments: [Appointment] {
        appointments.filter { !$0.isCompleted && $0.date >= Calendar.current.startOfDay(for: Date()) }
    }
    
    var pastAppointments: [Appointment] {
        appointments.filter { $0.isCompleted || $0.date < Calendar.current.startOfDay(for: Date()) }
    }
    
    var nextAppointment: Appointment? {
        upcomingAppointments.first
    }
    
    // MARK: - Appointment Prep
    func generatePrep(for appointment: Appointment, healthManager: HealthKitManager, journalEntries: [JournalEntry], medications: [Medication], conditions: [String]) async {
        isGeneratingPrep = true
        errorMessage = nil
        
        do {
            let healthData = healthManager.healthSummaryForAI()
            let journalSummaries = journalEntries.prefix(5).map { entry in
                "\(entry.date.formatted(date: .abbreviated, time: .omitted)): Mood: \(entry.mood), Notes: \(entry.notes)"
            }
            let medNames = medications.map { "\($0.name) \($0.dosage) \($0.frequency)" }
            
            let prep = try await claude.generateAppointmentPrep(
                appointment: appointment,
                healthData: healthData,
                journalEntries: journalSummaries,
                medications: medNames,
                conditions: conditions
            )
            
            if let index = appointments.firstIndex(where: { $0.id == appointment.id }) {
                appointments[index].prep = prep
                selectedAppointment = appointments[index]
            }
        } catch {
            errorMessage = "Failed to generate prep: \(error.localizedDescription)"
            // Fallback prep
            if let index = appointments.firstIndex(where: { $0.id == appointment.id }) {
                appointments[index].prep = AppointmentPrep(
                    whatToMention: [
                        "Any new or changed symptoms since your last visit",
                        "How your current medications are working",
                        "Any changes in sleep, diet, or exercise",
                        "Stress levels and mental health"
                    ],
                    questionsToAsk: [
                        "Are there any preventive screenings I should schedule?",
                        "Should we adjust any of my current treatments?",
                        "What lifestyle changes would you recommend?",
                        "When should I schedule my next appointment?"
                    ],
                    summary: "Prepare to discuss your overall health status, any new concerns, and how your current care plan is working for you."
                )
                selectedAppointment = appointments[index]
            }
        }
        
        isGeneratingPrep = false
    }
    
    // MARK: - Post-Visit OCR + Translation
    func processPostVisitImage(_ image: UIImage, for appointment: Appointment) async {
        isProcessingOCR = true
        errorMessage = nil
        
        do {
            // Step 1: OCR the image
            let rawText = try await ocr.extractText(from: image)
            
            guard !rawText.isEmpty else {
                errorMessage = "Could not read text from the image. Please try again with a clearer photo."
                isProcessingOCR = false
                return
            }
            
            // Step 2: Send to Claude for translation
            let summary = try await claude.translatePostVisitSummary(rawText: rawText)
            
            if let index = appointments.firstIndex(where: { $0.id == appointment.id }) {
                appointments[index].postVisitSummary = summary
                appointments[index].isCompleted = true
                selectedAppointment = appointments[index]
            }
        } catch {
            errorMessage = "Failed to process visit summary: \(error.localizedDescription)"
        }
        
        isProcessingOCR = false
    }
    
    // MARK: - Export Prep as Text
    func exportPrepText(for appointment: Appointment) -> String {
        guard let prep = appointment.prep else { return "" }
        
        var text = "APPOINTMENT PREPARATION\n"
        text += "========================\n\n"
        text += "Doctor: \(appointment.doctorName)\n"
        text += "Date: \(appointment.date.formatted(date: .long, time: .omitted)) at \(appointment.time)\n"
        text += "Reason: \(appointment.reason)\n\n"
        
        text += "📋 WHAT TO MENTION\n"
        for item in prep.whatToMention {
            text += "• \(item)\n"
        }
        
        text += "\n❓ QUESTIONS TO ASK\n"
        for question in prep.questionsToAsk {
            text += "• \(question)\n"
        }
        
        text += "\n📝 SUMMARY\n"
        text += prep.summary
        
        return text
    }
    
    // MARK: - Helpers
    private func clearForm() {
        newDoctorName = ""
        newSpecialty = ""
        newDate = Date()
        newTime = "10:00 AM"
        newReason = ""
        newLocation = ""
    }
    
    private func loadMockData() {
        let calendar = Calendar.current
        appointments = [
            Appointment(
                doctorName: "Dr. Sarah Chen",
                specialty: "Primary Care",
                date: calendar.date(byAdding: .day, value: 4, to: Date())!,
                time: "10:30 AM",
                reason: "Annual physical + blood work review",
                location: "Lowell Community Health Center"
            ),
            Appointment(
                doctorName: "Dr. Michael Torres",
                specialty: "Sports Medicine",
                date: calendar.date(byAdding: .day, value: 12, to: Date())!,
                time: "2:00 PM",
                reason: "Knee check for triathlon training",
                location: "UMass Lowell Health Services"
            ),
            Appointment(
                doctorName: "Dr. Emily Walsh",
                specialty: "Dermatology",
                date: calendar.date(byAdding: .day, value: -14, to: Date())!,
                time: "9:00 AM",
                reason: "Skin check",
                location: "Chelmsford Dermatology",
                isCompleted: true,
                postVisitSummary: PostVisitSummary(
                    rawText: "Patient presented for routine skin examination. No suspicious lesions identified. Mild eczema noted on bilateral forearms. Recommend OTC hydrocortisone cream PRN.",
                    whatDoctorFound: "Your skin check looked great — no concerning spots. The doctor noticed some mild dry, irritated skin (eczema) on both forearms.",
                    whatThisMeans: "This is very common and nothing to worry about. The dry patches on your arms can be managed with simple over-the-counter treatment.",
                    whatToDo: "Pick up hydrocortisone cream (1%) from any pharmacy and apply it when the patches feel itchy or inflamed. Keep your skin moisturized, especially after showering."
                )
            )
        ]
    }
}

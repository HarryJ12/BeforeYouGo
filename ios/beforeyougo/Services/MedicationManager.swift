import Foundation
import SwiftUI
import Combine
import UserNotifications

@MainActor
class MedicationManager: ObservableObject {
    static let shared = MedicationManager()
    
    @Published var medications: [Medication] = [] {
        didSet { save() }
    }
    
    private let storageKey = "savedMedications"
    
    private init() {
        load()
    }
    
    // MARK: - Notification Permission
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    // MARK: - CRUD
    func addMedication(_ med: Medication) {
        medications.append(med)
        if med.isReminderEnabled {
            scheduleNotifications(for: med)
        }
    }
    
    func removeMedication(at offsets: IndexSet) {
        let idsToRemove = offsets.map { medications[$0].id }
        for id in idsToRemove {
            cancelNotifications(for: id)
        }
        medications.remove(atOffsets: offsets)
    }
    
    func updateMedication(_ med: Medication) {
        if let index = medications.firstIndex(where: { $0.id == med.id }) {
            cancelNotifications(for: med.id)
            medications[index] = med
            if med.isReminderEnabled {
                scheduleNotifications(for: med)
            }
        }
    }
    
    // MARK: - Next Medication
    var nextMedication: (medication: Medication, date: Date)? {
        let upcoming = medications
            .filter { $0.isReminderEnabled && !$0.reminderTimes.isEmpty }
            .compactMap { med -> (Medication, Date)? in
                guard let next = med.nextReminderDate else { return nil }
                return (med, next)
            }
            .sorted { $0.1 < $1.1 }
        
        return upcoming.first
    }
    
    // MARK: - Schedule Notifications
    func scheduleNotifications(for med: Medication) {
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        
        for (index, time) in med.reminderTimes.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Time for your medication"
            content.body = "\(med.name) \(med.dosage)"
            content.sound = .default
            content.badge = 1
            
            let components = calendar.dateComponents([.hour, .minute], from: time)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
            let identifier = "\(med.id.uuidString)-\(index)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            center.add(request) { error in
                if let error = error {
                    print("Failed to schedule notification: \(error)")
                }
            }
        }
    }
    
    func cancelNotifications(for medID: UUID) {
        let center = UNUserNotificationCenter.current()
        // Remove all notifications matching this medication's ID prefix
        center.getPendingNotificationRequests { requests in
            let ids = requests
                .filter { $0.identifier.hasPrefix(medID.uuidString) }
                .map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
    
    func rescheduleAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        for med in medications where med.isReminderEnabled {
            scheduleNotifications(for: med)
        }
    }
    
    // MARK: - Persistence (UserDefaults for MVP)
    private func save() {
        if let data = try? JSONEncoder().encode(medications) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode([Medication].self, from: data) else { return }
        medications = saved
    }
}

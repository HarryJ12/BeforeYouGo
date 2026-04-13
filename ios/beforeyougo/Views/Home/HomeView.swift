import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var healthVM: HealthViewModel
    @EnvironmentObject var appointmentVM: AppointmentViewModel
    @EnvironmentObject var journalVM: JournalViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Greeting
                    greetingSection
                    
                    // Health Snapshot
                    healthSnapshotCard
                    
                    // Quick Stats
                    quickStatsGrid
                    // Next Medication Reminder
                                        if let nextMed = MedicationManager.shared.nextMedication {
                                            HStack(spacing: 14) {
                                                Image(systemName: "pill.fill")
                                                    .font(.title2)
                                                    .foregroundColor(.white)
                                                    .frame(width: 44, height: 44)
                                                    .background(Color.byg_primary)
                                                    .cornerRadius(12)
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(nextMed.medication.name)
                                                        .font(.headline)
                                                        .foregroundColor(.byg_textPrimary)
                                                    Text("\(nextMed.medication.dosage) — \(nextMed.date.formatted(date: .omitted, time: .shortened))")
                                                        .font(.subheadline)
                                                        .foregroundColor(.byg_textSecondary)
                                                }
                                                
                                                Spacer()
                                                
                                                Text(timeUntil(nextMed.date))
                                                    .font(.caption.bold())
                                                    .foregroundColor(.byg_primary)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 4)
                                                    .background(Color.byg_primary.opacity(0.12))
                                                    .cornerRadius(8)
                                            }
                                            .bygCard()
                                        }
                    
                    // Next Appointment
                    if let next = appointmentVM.nextAppointment {
                        BYGSectionHeader(title: "Next Visit")
                        AppointmentCard(appointment: next, onPrepare: {
                            appointmentVM.selectedAppointment = next
                            appointmentVM.showPrepView = true
                        })
                    }
                    
                    // AI Insights
                    if !healthVM.insights.isEmpty {
                        BYGSectionHeader(title: "Insights")
                        ForEach(healthVM.insights) { insight in
                            InsightCard(insight: insight)
                        }
                    }
                }
                .padding()
            }
            .background(Color.byg_background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Image(systemName: "bell.badge")
                        .foregroundColor(.byg_primary)
                }
            }
        }
    }
    
    // MARK: - Greeting
    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greetingText)
                .font(.title2.bold())
                .foregroundColor(.byg_textPrimary)
            Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(.subheadline)
                .foregroundColor(.byg_textSecondary)
        }
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = appState.userName.isEmpty ? "there" : appState.userName
        switch hour {
        case 5..<12: return "Good morning, \(name)"
        case 12..<17: return "Good afternoon, \(name)"
        default: return "Good evening, \(name)"
        }
    }
    
    // MARK: - Health Snapshot
    private var healthSnapshotCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.shield.fill")
                .font(.title)
                .foregroundColor(.byg_success)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Everything looks good")
                    .font(.headline)
                    .foregroundColor(.byg_textPrimary)
                Text("All metrics are within normal range")
                    .font(.subheadline)
                    .foregroundColor(.byg_textSecondary)
            }
            
            Spacer()
        }
        .bygCard()
    }
    
    // MARK: - Quick Stats
    private var quickStatsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(healthVM.metrics.prefix(4)) { metric in
                MetricCard(metric: metric)
            }
        }
    }
    // MARK: - Time Until Helper
        private func timeUntil(_ date: Date) -> String {
            let diff = date.timeIntervalSince(Date())
            if diff < 0 { return "Now" }
            let hours = Int(diff) / 3600
            let minutes = (Int(diff) % 3600) / 60
            if hours > 0 { return "in \(hours)h \(minutes)m" }
            return "in \(minutes)m"
        }
}

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var healthVM = HealthViewModel()
    @StateObject private var appointmentVM = AppointmentViewModel()
    @StateObject private var journalVM = JournalViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .environmentObject(healthVM)
                .environmentObject(appointmentVM)
                .environmentObject(journalVM)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            UnifiedHealthTabView()
                .environmentObject(appState)
                .environmentObject(healthVM)
                .environmentObject(journalVM)
                .tabItem {
                    Image(systemName: "heart.text.square.fill")
                    Text("Health")
                }
                .tag(1)
            
            AppointmentsTabView()
                .environmentObject(appointmentVM)
                .environmentObject(journalVM)
                .environmentObject(healthVM)
                .tabItem {
                    Image(systemName: "calendar.badge.clock")
                    Text("Visits")
                }
                .tag(2)
            
            CareTabView()
                .tabItem {
                    Image(systemName: "stethoscope")
                    Text("Care")
                }
                .tag(3)
            
            ProfileTabView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(4)
        }
        .tint(.byg_primary)
        .task {
            await healthVM.refreshMetrics()
            await healthVM.fetchInsights(journalEntries: journalVM.recentEntrySummaries())
        }
    }
}

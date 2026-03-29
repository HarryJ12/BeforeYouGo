import SwiftUI

// MARK: - Unified Health Tab (Both Paths)
// Wearable users see: HealthKit metrics + Daily Check-In + Journal Timeline
// Non-wearable users see: Daily Check-In + Quick Log + Journal Timeline
// The check-in is available to EVERYONE

struct UnifiedHealthTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var healthVM: HealthViewModel
    @EnvironmentObject var journalVM: JournalViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // ── Daily Check-In (ALWAYS shown, both paths) ──
                    Button(action: { journalVM.startCheckIn() }) {
                        HStack(spacing: 14) {
                            Image(systemName: "bubble.left.and.text.bubble.right.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Start Daily Check-In")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Chat with AI about how you're feeling")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(16)
                        .background(
                            LinearGradient(
                                colors: [.byg_primary, .byg_primaryDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                    }
                    
                    // ── HealthKit Metrics (wearable users only) ──
                    if appState.userPath == .healthKit {
                        BYGSectionHeader(title: "Your Metrics")
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(healthVM.metrics) { metric in
                                NavigationLink(destination: MetricDetailView(metric: metric)) {
                                    MetricCard(metric: metric)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        // AI Insights from wearable data
                        if !healthVM.insights.isEmpty {
                            BYGSectionHeader(title: "AI Insights")
                            ForEach(healthVM.insights) { insight in
                                InsightCard(insight: insight)
                            }
                        }
                    }
                    
                    // ── Quick Log (ALWAYS shown) ──
                    QuickLogSection()
                        .environmentObject(journalVM)
                    
                    // ── Journal Timeline (ALWAYS shown) ──
                    if !journalVM.entries.isEmpty {
                        BYGSectionHeader(title: "Health Timeline")
                        ForEach(journalVM.entries) { entry in
                            JournalEntryCard(entry: entry)
                        }
                    }
                }
                .padding()
            }
            .background(Color.byg_background)
            .navigationTitle("Health")
            .refreshable {
                if appState.userPath == .healthKit {
                    await healthVM.refreshMetrics()
                }
            }
            .sheet(isPresented: $journalVM.showChat) {
                JournalChatView()
                    .environmentObject(journalVM)
            }
        }
    }
}

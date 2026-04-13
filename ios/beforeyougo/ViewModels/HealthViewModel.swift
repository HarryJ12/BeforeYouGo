import Foundation
import Combine

@MainActor
class HealthViewModel: ObservableObject {
    @Published var metrics: [HealthMetric] = []
    @Published var selectedMetric: HealthMetric?
    @Published var isLoading = false
    @Published var insights: [AIInsight] = []
    
    private let healthKit = HealthKitManager.shared
    private let claude = ClaudeAPIService.shared
    
    // MARK: - Build Metrics from HealthKit
    func refreshMetrics() async {
        isLoading = true
        await healthKit.fetchAllData()
        
        var newMetrics: [HealthMetric] = []
        
        if healthKit.heartRate > 0 {
            newMetrics.append(HealthMetric(
                type: .heartRate,
                value: healthKit.heartRate,
                unit: "bpm",
                trend: computeTrend(healthKit.heartRateHistory),
                status: heartRateStatus(healthKit.heartRate),
                history: healthKit.heartRateHistory
            ))
        }
        
        newMetrics.append(HealthMetric(
            type: .steps,
            value: healthKit.stepCount,
            unit: "steps",
            trend: .stable,
            status: stepStatus(healthKit.stepCount),
            history: healthKit.stepHistory
        ))
        
        if healthKit.sleepHours > 0 {
            newMetrics.append(HealthMetric(
                type: .sleep,
                value: healthKit.sleepHours,
                unit: "hrs",
                trend: computeTrend(healthKit.sleepHistory),
                status: sleepStatus(healthKit.sleepHours),
                history: healthKit.sleepHistory
            ))
        }
        
        if healthKit.weight > 0 {
            newMetrics.append(HealthMetric(
                type: .weight,
                value: healthKit.weight,
                unit: "lbs",
                trend: .stable,
                status: .normal,
                history: []
            ))
        }
        
        // If no HealthKit data, show placeholder metrics
        if newMetrics.isEmpty {
            newMetrics = mockMetrics()
        }
        
        metrics = newMetrics
        isLoading = false
    }
    
    // MARK: - Fetch Insights
    func fetchInsights(journalEntries: [String]) async {
        do {
            let healthData = healthKit.healthSummaryForAI()
            insights = try await claude.generateInsights(
                healthData: healthData.isEmpty ? ["Steps: 7,234", "Heart rate avg: 72 bpm", "Sleep: 7.2 hours"] : healthData,
                journalEntries: journalEntries
            )
        } catch {
            insights = [
                AIInsight(title: "Stay Hydrated", body: "Remember to drink water consistently throughout the day, especially during training.", icon: "drop.fill", accentColor: "blue"),
                AIInsight(title: "Recovery Day", body: "Your activity has been high this week. Consider a lighter day tomorrow.", icon: "leaf.fill", accentColor: "green")
            ]
        }
    }
    
    // MARK: - Status Helpers
    private func heartRateStatus(_ value: Double) -> HealthMetric.MetricStatus {
        if value < 50 || value > 100 { return .watch }
        if value < 40 || value > 120 { return .concerning }
        return .normal
    }
    
    private func stepStatus(_ value: Double) -> HealthMetric.MetricStatus {
        if value >= 8000 { return .normal }
        if value >= 4000 { return .watch }
        return .concerning
    }
    
    private func sleepStatus(_ hours: Double) -> HealthMetric.MetricStatus {
        if hours >= 7 { return .normal }
        if hours >= 5.5 { return .watch }
        return .concerning
    }
    
    private func computeTrend(_ history: [MetricDataPoint]) -> HealthMetric.Trend {
        guard history.count >= 2 else { return .stable }
        let recent = history.suffix(3).map(\.value)
        let older = history.prefix(3).map(\.value)
        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        let olderAvg = older.reduce(0, +) / Double(older.count)
        let diff = (recentAvg - olderAvg) / max(olderAvg, 1)
        if diff > 0.05 { return .up }
        if diff < -0.05 { return .down }
        return .stable
    }
    
    private func mockMetrics() -> [HealthMetric] {
        let calendar = Calendar.current
        let now = Date()
        
        func mockHistory(base: Double, variance: Double) -> [MetricDataPoint] {
            (0..<7).reversed().map { i in
                let date = calendar.date(byAdding: .day, value: -i, to: now)!
                return MetricDataPoint(date: date, value: base + Double.random(in: -variance...variance))
            }
        }
        
        return [
            HealthMetric(type: .heartRate, value: 72, unit: "bpm", trend: .stable, status: .normal, history: mockHistory(base: 72, variance: 8)),
            HealthMetric(type: .steps, value: 7234, unit: "steps", trend: .up, status: .normal, history: mockHistory(base: 7000, variance: 2000)),
            HealthMetric(type: .sleep, value: 7.2, unit: "hrs", trend: .down, status: .normal, history: mockHistory(base: 7, variance: 1.5)),
            HealthMetric(type: .weight, value: 165, unit: "lbs", trend: .stable, status: .normal, history: mockHistory(base: 165, variance: 1))
        ]
    }
}

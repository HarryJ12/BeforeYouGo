import Foundation
import HealthKit
import Combine


class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var stepCount: Double = 0
    @Published var heartRate: Double = 0
    @Published var sleepHours: Double = 0
    @Published var bloodPressureSystolic: Double = 0
    @Published var bloodPressureDiastolic: Double = 0
    @Published var weight: Double = 0
    
    @Published var stepHistory: [MetricDataPoint] = []
    @Published var heartRateHistory: [MetricDataPoint] = []
    @Published var sleepHistory: [MetricDataPoint] = []
    
    private init() {}
    
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    // MARK: - Authorization
    func requestAuthorization() async throws {
        guard isAvailable else { return }
        
        let readTypes: Set<HKObjectType> = [
            HKQuantityType(.stepCount),
            HKQuantityType(.heartRate),
            HKCategoryType(.sleepAnalysis),
            HKQuantityType(.bloodPressureSystolic),
            HKQuantityType(.bloodPressureDiastolic),
            HKQuantityType(.bodyMass)
        ]
        
        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
        
        await MainActor.run {
            self.isAuthorized = true
        }
    }
    
    // MARK: - Fetch All Data
    func fetchAllData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchSteps() }
            group.addTask { await self.fetchHeartRate() }
            group.addTask { await self.fetchSleep() }
            group.addTask { await self.fetchWeight() }
            group.addTask { await self.fetchStepHistory() }
            group.addTask { await self.fetchHeartRateHistory() }
            group.addTask { await self.fetchSleepHistory() }
        }
    }
    
    // MARK: - Steps
    private func fetchSteps() async {
        let type = HKQuantityType(.stepCount)
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
        
        let descriptor = HKStatisticsQueryDescriptor(
                predicate: HKSamplePredicate.quantitySample(type: type, predicate: predicate),         options: .cumulativeSum
        )
        
        do {
            let result = try await descriptor.result(for: healthStore)
            let value = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
            await MainActor.run { self.stepCount = value }
        } catch {
            print("Steps fetch error: \(error)")
        }
    }
    
    // MARK: - Heart Rate
    private func fetchHeartRate() async {
        let type = HKQuantityType(.heartRate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: HKUnit(from: "count/min")) ?? 0
                Task { @MainActor in
                    self.heartRate = value
                    continuation.resume()
                }
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - Sleep
    private func fetchSleep() async {
        let type = HKCategoryType(.sleepAnalysis)
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: now)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                var totalSleep: TimeInterval = 0
                for sample in (samples as? [HKCategorySample] ?? []) {
                    if sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                        totalSleep += sample.endDate.timeIntervalSince(sample.startDate)
                    }
                }
                Task { @MainActor in
                    self.sleepHours = totalSleep / 3600.0
                    continuation.resume()
                }
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - Weight
    private func fetchWeight() async {
        let type = HKQuantityType(.bodyMass)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: .pound()) ?? 0
                Task { @MainActor in
                    self.weight = value
                    continuation.resume()
                }
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - History (7 days)
    private func fetchStepHistory() async {
        let type = HKQuantityType(.stepCount)
        let calendar = Calendar.current
        let now = Date()
        
        var points: [MetricDataPoint] = []
        
        for dayOffset in (0..<7).reversed() {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
            let start = calendar.startOfDay(for: date)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            
            let descriptor = HKStatisticsQueryDescriptor(
                predicate: HKSamplePredicate.quantitySample(type: type, predicate: predicate),                options: .cumulativeSum
            )
            
            do {
                let result = try await descriptor.result(for: healthStore)
                let value = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                points.append(MetricDataPoint(date: start, value: value))
            } catch {
                points.append(MetricDataPoint(date: start, value: 0))
            }
        }
        
        await MainActor.run { self.stepHistory = points }
    }
    
    private func fetchHeartRateHistory() async {
        let type = HKQuantityType(.heartRate)
        let calendar = Calendar.current
        let now = Date()
        
        var points: [MetricDataPoint] = []
        
        for dayOffset in (0..<7).reversed() {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
            let start = calendar.startOfDay(for: date)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            
            let descriptor = HKStatisticsQueryDescriptor(
                predicate: HKSamplePredicate.quantitySample(type: type, predicate: predicate),                options: .discreteAverage
            )
            
            do {
                let result = try await descriptor.result(for: healthStore)
                let value = result?.averageQuantity()?.doubleValue(for: HKUnit(from: "count/min")) ?? 0
                points.append(MetricDataPoint(date: start, value: value))
            } catch {
                points.append(MetricDataPoint(date: start, value: 0))
            }
        }
        
        await MainActor.run { self.heartRateHistory = points }
    }
    
    private func fetchSleepHistory() async {
        let calendar = Calendar.current
        let now = Date()
        
        var points: [MetricDataPoint] = []
        
        for dayOffset in (0..<7).reversed() {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
            let start = calendar.startOfDay(for: date)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            
            let type = HKCategoryType(.sleepAnalysis)
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            
            let value: Double = await withCheckedContinuation { continuation in
                let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                    var total: TimeInterval = 0
                    for sample in (samples as? [HKCategorySample] ?? []) {
                        if sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                           sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                           sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                           sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                            total += sample.endDate.timeIntervalSince(sample.startDate)
                        }
                    }
                    continuation.resume(returning: total / 3600.0)
                }
                healthStore.execute(query)
            }
            
            points.append(MetricDataPoint(date: start, value: value))
        }
        
        await MainActor.run { self.sleepHistory = points }
    }
    
    // MARK: - Summary for AI
    func healthSummaryForAI() -> [String] {
        var summary: [String] = []
        if stepCount > 0 { summary.append("Steps today: \(Int(stepCount))") }
        if heartRate > 0 { summary.append("Heart rate: \(Int(heartRate)) bpm") }
        if sleepHours > 0 { summary.append("Sleep last night: \(String(format: "%.1f", sleepHours)) hours") }
        if weight > 0 { summary.append("Weight: \(String(format: "%.1f", weight)) lbs") }
        return summary
    }
}

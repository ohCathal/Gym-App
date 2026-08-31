import Foundation
import HealthKit

@Observable
final class HealthKitManager {
    private let store = HKHealthStore()

    var todaySteps: Double = 0
    var todayActiveCalories: Double = 0
    var isAuthorized = false
    var authError: String?

    var latestHeightCm: Double?
    var ageYears: Int?

    private var stepType: HKQuantityType { HKQuantityType(.stepCount) }
    private var energyType: HKQuantityType { HKQuantityType(.activeEnergyBurned) }
    private var weightType: HKQuantityType { HKQuantityType(.bodyMass) }
    private var heightType: HKQuantityType { HKQuantityType(.height) }

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            authError = "Health data isn't available on this device."
            return
        }
        var readTypes: Set<HKObjectType> = [stepType, energyType, weightType, heightType]
        if let dobType = HKObjectType.characteristicType(forIdentifier: .dateOfBirth) {
            readTypes.insert(dobType)
        }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            await fetchTodayData()
            await fetchProfileData()
        } catch {
            authError = "Couldn't get Health access: \(error.localizedDescription)"
        }
    }

    func fetchTodayData() async {
        async let steps = sumToday(for: stepType, unit: .count())
        async let calories = sumToday(for: energyType, unit: .kilocalorie())
        todaySteps = await steps
        todayActiveCalories = await calories
    }

    func fetchProfileData() async {
        async let height = latestSample(for: heightType, unit: .meterUnit(with: .centi))
        latestHeightCm = await height

        if let dob = try? store.dateOfBirthComponents(), let birthDate = Calendar.current.date(from: dob) {
            ageYears = Calendar.current.dateComponents([.year], from: birthDate, to: .now).year
        }
    }

    func fetchWeightSamples(daysBack: Int) async -> [(date: Date, kg: Double)] {
        let start = Calendar.current.date(byAdding: .day, value: -daysBack, to: .now) ?? .now
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)
        let sort = [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: weightType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: sort) { _, samples, _ in
                let points = (samples as? [HKQuantitySample])?.map { sample in
                    (date: sample.startDate, kg: sample.quantity.doubleValue(for: .gramUnit(with: .kilo)))
                } ?? []
                continuation.resume(returning: points)
            }
            store.execute(query)
        }
    }

    private func latestSample(for type: HKQuantityType, unit: HKUnit) async -> Double? {
        let sort = [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: sort) { _, samples, _ in
                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    private func sumToday(for type: HKQuantityType, unit: HKUnit) async -> Double {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: .now)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let value = result?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }
}

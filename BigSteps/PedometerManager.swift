import CoreMotion
import Combine
import Foundation

@MainActor
final class PedometerManager: ObservableObject {
    @Published private(set) var todaySteps = 0
    @Published private(set) var sessionSteps = 0
    @Published private(set) var isTracking = false
    @Published private(set) var statusMessage: String?

    private let todayPedometer = CMPedometer()
    private let sessionPedometer = CMPedometer()
    private var sessionStart = Date()

    func start() {
        guard CMPedometer.isStepCountingAvailable() else {
            statusMessage = "Step counting is not available on this device."
            return
        }

        sessionStart = Date()
        startTodayUpdates()
        startSessionUpdates()
        isTracking = true
    }

    func refresh() {
        guard CMPedometer.isStepCountingAvailable() else { return }
        queryToday()
        querySession()
    }

    func resetSession() {
        sessionPedometer.stopUpdates()
        sessionStart = Date()
        sessionSteps = 0
        startSessionUpdates()
    }

    private func startTodayUpdates() {
        todayPedometer.stopUpdates()
        let midnight = Calendar.current.startOfDay(for: Date())

        todayPedometer.startUpdates(from: midnight) { [weak self] data, error in
            Task { @MainActor in
                self?.handleToday(data: data, error: error)
            }
        }
    }

    private func startSessionUpdates() {
        sessionPedometer.startUpdates(from: sessionStart) { [weak self] data, error in
            Task { @MainActor in
                self?.handleSession(data: data, error: error)
            }
        }
    }

    private func queryToday() {
        let midnight = Calendar.current.startOfDay(for: Date())
        todayPedometer.queryPedometerData(from: midnight, to: Date()) { [weak self] data, error in
            Task { @MainActor in
                self?.handleToday(data: data, error: error)
            }
        }
    }

    private func querySession() {
        sessionPedometer.queryPedometerData(from: sessionStart, to: Date()) { [weak self] data, error in
            Task { @MainActor in
                self?.handleSession(data: data, error: error)
            }
        }
    }

    private func handleToday(data: CMPedometerData?, error: Error?) {
        if let data {
            todaySteps = data.numberOfSteps.intValue
            statusMessage = nil
        } else if let error {
            handle(error)
        }
    }

    private func handleSession(data: CMPedometerData?, error: Error?) {
        if let data {
            sessionSteps = data.numberOfSteps.intValue
            statusMessage = nil
        } else if let error {
            handle(error)
        }
    }

    private func handle(_ error: Error) {
        if CMPedometer.authorizationStatus() == .denied || CMPedometer.authorizationStatus() == .restricted {
            statusMessage = "Allow Motion & Fitness access in Settings to count your steps."
        } else {
            statusMessage = "Step data is temporarily unavailable."
        }
    }
}

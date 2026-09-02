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
    private var todayTween = TweenState()
    private var sessionTween = TweenState()

    private enum Counter {
        case today
        case session
    }

    private struct TweenState {
        var lastActualValue: Int?
        var lastActualDate: Date?
        var task: Task<Void, Never>?
    }

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
        sessionTween.task?.cancel()
        sessionTween = TweenState()
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
                self?.handleToday(data: data, error: error, shouldTween: false)
            }
        }
    }

    private func querySession() {
        sessionPedometer.queryPedometerData(from: sessionStart, to: Date()) { [weak self] data, error in
            Task { @MainActor in
                self?.handleSession(data: data, error: error, shouldTween: false)
            }
        }
    }

    private func handleToday(
        data: CMPedometerData?,
        error: Error?,
        shouldTween: Bool = true
    ) {
        if let data {
            apply(
                actualValue: data.numberOfSteps.intValue,
                at: data.endDate,
                to: .today,
                shouldTween: shouldTween
            )
            statusMessage = nil
        } else if let error {
            handle(error)
        }
    }

    private func handleSession(
        data: CMPedometerData?,
        error: Error?,
        shouldTween: Bool = true
    ) {
        if let data {
            apply(
                actualValue: data.numberOfSteps.intValue,
                at: data.endDate,
                to: .session,
                shouldTween: shouldTween
            )
            statusMessage = nil
        } else if let error {
            handle(error)
        }
    }

    private func apply(
        actualValue: Int,
        at date: Date,
        to counter: Counter,
        shouldTween: Bool
    ) {
        var tween = tweenState(for: counter)
        tween.task?.cancel()
        setDisplayedValue(actualValue, for: counter)

        let previousValue = tween.lastActualValue
        let previousDate = tween.lastActualDate
        tween.lastActualValue = actualValue
        tween.lastActualDate = date
        tween.task = nil

        guard shouldTween,
              let previousValue,
              let previousDate else {
            setTweenState(tween, for: counter)
            return
        }

        let stepDelta = actualValue - previousValue
        let readingInterval = date.timeIntervalSince(previousDate)

        guard stepDelta > 1, readingInterval > 0 else {
            setTweenState(tween, for: counter)
            return
        }

        let delayPerStep = readingInterval / Double(stepDelta)
        let maximumPredictionDuration: TimeInterval = 2
        let predictedStepCount = Int(
            ceil(maximumPredictionDuration / delayPerStep)
        ) - 1

        guard predictedStepCount > 0 else {
            setTweenState(tween, for: counter)
            return
        }

        tween.task = Task { [weak self] in
            for offset in 1...predictedStepCount {
                do {
                    try await Task.sleep(for: .seconds(delayPerStep))
                } catch {
                    return
                }

                guard !Task.isCancelled else { return }
                self?.setDisplayedValue(actualValue + offset, for: counter)
            }
        }

        setTweenState(tween, for: counter)
    }

    private func tweenState(for counter: Counter) -> TweenState {
        switch counter {
        case .today:
            todayTween
        case .session:
            sessionTween
        }
    }

    private func setTweenState(_ tween: TweenState, for counter: Counter) {
        switch counter {
        case .today:
            todayTween = tween
        case .session:
            sessionTween = tween
        }
    }

    private func setDisplayedValue(_ value: Int, for counter: Counter) {
        switch counter {
        case .today:
            todaySteps = value
        case .session:
            sessionSteps = value
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

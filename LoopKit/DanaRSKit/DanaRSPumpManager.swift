//
//  DanaRSPumpManager.swift
//  LoopKit
//
//  Created by Andy Armstrong on 10/5/2021.
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import HealthKit
import LoopKit
import LoopTestingKit

public protocol DanaRSPumpManagerStateObserver {
    func danaRSPumpManager(_ manager: DanaRSPumpManager, didUpdate state: DanaRSPumpManagerState)
    func danaRSPumpManager(_ manager: DanaRSPumpManager, didUpdate status: PumpManagerStatus, oldStatus: PumpManagerStatus)
}

private enum DanaRSPumpManagerError: LocalizedError {
    case pumpSuspended
    case communicationFailure
    case bolusInProgress

    var failureReason: String? {
        switch self {
        case .pumpSuspended:
            return "Pump is suspended"
        case .communicationFailure:
            return "Unable to communicate with pump"
        case .bolusInProgress:
            return "Bolus in progress"
        }
    }
}

public final class DanaRSPumpManager: TestingPumpManager {

    public static let managerIdentifier = "DanaRSPumpManager"
    public static let localizedTitle = "Simulator"
    private static let device = HKDevice(
        name: DanaRSPumpManager.managerIdentifier,
        manufacturer: nil,
        model: nil,
        hardwareVersion: nil,
        firmwareVersion: nil,
        softwareVersion: String(LoopKitVersionNumber),
        localIdentifier: nil,
        udiDeviceIdentifier: nil
    )

    private static let deliveryUnitsPerMinute = 1.5
    private static let pulsesPerUnit: Double = 20
    private static let pumpReservoirCapacity: Double = 200

    public var pumpReservoirCapacity: Double {
        return DanaRSPumpManager.pumpReservoirCapacity
    }

    public var reservoirFillFraction: Double {
        get {
            return state.reservoirUnitsRemaining / pumpReservoirCapacity
        }
        set {
            state.reservoirUnitsRemaining = newValue * pumpReservoirCapacity
        }
    }

    public var supportedBolusVolumes: [Double] {
        return supportedBasalRates
    }

    public var supportedBasalRates: [Double] {
        return (0...700).map { Double($0) / Double(type(of: self).pulsesPerUnit) }
    }

    public var maximumBasalScheduleEntryCount: Int {
        return 48
    }

    public var minimumBasalScheduleEntryDuration: TimeInterval {
        return .minutes(30)
    }

    public var testingDevice: HKDevice {
        return type(of: self).device
    }

    public var lastReconciliation: Date? {
        return Date()
    }

    private func basalDeliveryState(for state: DanaRSPumpManagerState) -> PumpManagerStatus.BasalDeliveryState {
        if case .suspended(let date) = state.suspendState {
            return .suspended(date)
        }
        if let temp = state.unfinalizedTempBasal, !temp.finished {
            return .tempBasal(DoseEntry(temp))
        }
        if case .resumed(let date) = state.suspendState {
            return .active(date)
        } else {
            return .active(Date())
        }
    }

    private func bolusState(for state: DanaRSPumpManagerState) -> PumpManagerStatus.BolusState {
        if let bolus = state.unfinalizedBolus, !bolus.finished {
            return .inProgress(DoseEntry(bolus))
        } else {
            return .none
        }
    }

    private func status(for state: DanaRSPumpManagerState) -> PumpManagerStatus {
        return PumpManagerStatus(
            timeZone: .current,
            device: DanaRSPumpManager.device,
            pumpBatteryChargeRemaining: state.pumpBatteryChargeRemaining,
            basalDeliveryState: basalDeliveryState(for: state),
            bolusState: .none)
    }

    public var pumpBatteryChargeRemaining: Double? {
        get {
            return state.pumpBatteryChargeRemaining
        }
        set {
            state.pumpBatteryChargeRemaining = newValue
        }
    }

    public var status: PumpManagerStatus {
        get {
            return status(for: self.state)
        }
    }

    private func notifyObservers() {
    }

    public var state: DanaRSPumpManagerState {
        didSet {
            let newValue = state

            let oldStatus = status(for: oldValue)
            let newStatus = status(for: newValue)

            if oldStatus != newStatus {
                statusObservers.forEach { $0.pumpManager(self, didUpdate: newStatus, oldStatus: oldStatus) }
            }

            stateObservers.forEach { $0.DanaRSPumpManager(self, didUpdate: self.state) }

            delegate.notify { (delegate) in
                if newValue.reservoirUnitsRemaining != oldValue.reservoirUnitsRemaining {
                    delegate?.pumpManager(self, didReadReservoirValue: self.state.reservoirUnitsRemaining, at: Date()) { result in
                        // nothing to do here
                    }
                }
                delegate?.pumpManagerDidUpdateState(self)
            }
        }
    }

    public var pumpManagerDelegate: PumpManagerDelegate? {
        get {
            return delegate.delegate
        }
        set {
            delegate.delegate = newValue
        }
    }

    public var delegateQueue: DispatchQueue! {
        get {
            return delegate.queue
        }
        set {
            delegate.queue = newValue
        }
    }

    private let delegate = WeakSynchronizedDelegate<PumpManagerDelegate>()

    private var statusObservers = WeakSynchronizedSet<PumpManagerStatusObserver>()
    private var stateObservers = WeakSynchronizedSet<DanaRSPumpManagerStateObserver>()

    public init() {
        state = DanaRSPumpManagerState(
            reservoirUnitsRemaining: DanaRSPumpManager.pumpReservoirCapacity,
            tempBasalEnactmentShouldError: false,
            bolusEnactmentShouldError: false,
            deliverySuspensionShouldError: false,
            deliveryResumptionShouldError: false,
            maximumBolus: 25.0,
            maximumBasalRatePerHour: 5.0,
            suspendState: .resumed(Date()),
            pumpBatteryChargeRemaining: 1,
            unfinalizedBolus: nil,
            unfinalizedTempBasal: nil,
            finalizedDoses: [])
    }

    public init?(rawState: RawStateValue) {
        guard let state = (rawState["state"] as? DanaRSPumpManagerState.RawValue).flatMap(DanaRSPumpManagerState.init(rawValue:)) else {
            return nil
        }
        self.state = state
    }

    public var rawState: RawStateValue {
        return ["state": state.rawValue]
    }

    public func createBolusProgressReporter(reportingOn dispatchQueue: DispatchQueue) -> DoseProgressReporter? {
        if case .inProgress(let dose) = status.bolusState {
            return MockDoseProgressEstimator(reportingQueue: dispatchQueue, dose: dose)
        }
        return nil
    }

    public var pumpRecordsBasalProfileStartEvents: Bool {
        return false
    }

    public func addStatusObserver(_ observer: PumpManagerStatusObserver, queue: DispatchQueue) {
        statusObservers.insert(observer, queue: queue)
    }

    public func addStateObserver(_ observer: DanaRSPumpManagerStateObserver, queue: DispatchQueue) {
        stateObservers.insert(observer, queue: queue)
    }

    public func removeStatusObserver(_ observer: PumpManagerStatusObserver) {
        statusObservers.removeElement(observer)
    }

    public func assertCurrentPumpData() {

        state.finalizeFinishedDoses()

        storeDoses { (error) in
            self.delegate.notify { (delegate) in
                delegate?.pumpManagerRecommendsLoop(self)
            }

            guard error == nil else {
                return
            }

            DispatchQueue.main.async {
                let totalInsulinUsage = self.state.finalizedDoses.reduce(into: 0 as Double) { total, dose in
                    total += dose.units
                }

                self.state.finalizedDoses = []
                self.state.reservoirUnitsRemaining -= totalInsulinUsage
            }
        }
    }

    private func storeDoses(completion: @escaping (_ error: Error?) -> Void) {
        state.finalizeFinishedDoses()
        let pendingPumpEvents = state.dosesToStore.map { NewPumpEvent($0) }
        delegate.notify { (delegate) in
            delegate?.pumpManager(self, hasNewPumpEvents: pendingPumpEvents, lastReconciliation: self.lastReconciliation) { error in
                completion(error)
            }
        }
    }

    public func enactTempBasal(unitsPerHour: Double, for duration: TimeInterval, completion: @escaping (PumpManagerResult<DoseEntry>) -> Void) {
        if state.tempBasalEnactmentShouldError {
            completion(.failure(PumpManagerError.communication(DanaRSPumpManagerError.communicationFailure)))
        } else {
            let now = Date()
            if let temp = state.unfinalizedTempBasal, temp.finishTime.compare(now) == .orderedDescending {
                state.unfinalizedTempBasal?.cancel(at: now)
            }
            state.finalizeFinishedDoses()

            if duration < .ulpOfOne {
                // Cancel temp basal
                let temp = UnfinalizedDose(tempBasalRate: unitsPerHour, startTime: now, duration: duration)
                storeDoses { (error) in
                    completion(.success(DoseEntry(temp)))
                }
            } else {
                let temp = UnfinalizedDose(tempBasalRate: unitsPerHour, startTime: now, duration: duration)
                state.unfinalizedTempBasal = temp
                storeDoses { (error) in
                    completion(.success(DoseEntry(temp)))
                }
            }
        }
    }

    public func enactBolus(units: Double, at startDate: Date, willRequest: @escaping (DoseEntry) -> Void, completion: @escaping (PumpManagerResult<DoseEntry>) -> Void) {

        if state.bolusEnactmentShouldError {
            completion(.failure(SetBolusError.certain(PumpManagerError.communication(DanaRSPumpManagerError.communicationFailure))))
        } else {

            state.finalizeFinishedDoses()

            if let _ = state.unfinalizedBolus {
                completion(.failure(SetBolusError.certain(PumpManagerError.deviceState(DanaRSPumpManagerError.bolusInProgress))))
                return
            }

            if case .suspended = status.basalDeliveryState {
                completion(.failure(SetBolusError.certain(PumpManagerError.deviceState(DanaRSPumpManagerError.pumpSuspended))))
                return
            }
            let bolus = UnfinalizedDose(bolusAmount: units, startTime: Date(), duration: .minutes(units / type(of: self).deliveryUnitsPerMinute))
            let dose = DoseEntry(bolus)
            willRequest(dose)
            state.unfinalizedBolus = bolus
            storeDoses { (error) in
                completion(.success(dose))
            }
        }
    }

    public func cancelBolus(completion: @escaping (PumpManagerResult<DoseEntry?>) -> Void) {

        state.unfinalizedBolus?.cancel(at: Date())

        storeDoses { (_) in
            DispatchQueue.main.async {
                self.state.finalizeFinishedDoses()
                completion(.success(nil))
            }
        }
    }

    public func setMustProvideBLEHeartbeat(_ mustProvideBLEHeartbeat: Bool) {
        // nothing to do here
    }

    public func suspendDelivery(completion: @escaping (Error?) -> Void) {
        if self.state.deliverySuspensionShouldError {
            completion(PumpManagerError.communication(DanaRSPumpManagerError.communicationFailure))
        } else {
            let now = Date()
            state.unfinalizedTempBasal?.cancel(at: now)
            state.unfinalizedBolus?.cancel(at: now)

            let suspendDate = Date()
            let suspend = UnfinalizedDose(suspendStartTime: suspendDate)
            self.state.finalizedDoses.append(suspend)
            self.state.suspendState = .suspended(suspendDate)
            storeDoses { (error) in
                completion(error)
            }
        }
    }

    public func resumeDelivery(completion: @escaping (Error?) -> Void) {
        if self.state.deliveryResumptionShouldError {
            completion(PumpManagerError.communication(DanaRSPumpManagerError.communicationFailure))
        } else {
            let resumeDate = Date()
            let resume = UnfinalizedDose(resumeStartTime: resumeDate)
            self.state.finalizedDoses.append(resume)
            self.state.suspendState = .resumed(resumeDate)
            storeDoses { (error) in
                completion(error)
            }
        }
    }

    public func injectPumpEvents(_ pumpEvents: [NewPumpEvent]) {
        state.finalizedDoses += pumpEvents.compactMap { $0.unfinalizedDose }
    }
}

extension DanaRSPumpManager {
    public var debugDescription: String {
        return """
        ## DanaRSPumpManager
        status: \(status)
        state: \(state)
        stateObservers.count: \(stateObservers.cleanupDeallocatedElements().count)
        statusObservers.count: \(statusObservers.cleanupDeallocatedElements().count)
        """
    }
}

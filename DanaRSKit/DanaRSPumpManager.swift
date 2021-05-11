//
//  DanaRSPumpManager.swift
//  LoopKit
//
//  Created by Andy Armstrong on 10/5/2021.
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import HealthKit
import LoopKit


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

public final class DanaRSPumpManager: PumpManager {
    public var supportedBasalRates: [Double]
    
    public var supportedBolusVolumes: [Double]
    
    public var maximumBasalScheduleEntryCount: Int
    
    public var minimumBasalScheduleEntryDuration: TimeInterval
    
    public var pumpManagerDelegate: PumpManagerDelegate?
    
    public var pumpRecordsBasalProfileStartEvents: Bool
    
    public var pumpReservoirCapacity: Double
    
    public var lastReconciliation: Date?
    
    public var status: PumpManagerStatus
    
    public func addStatusObserver(_ observer: PumpManagerStatusObserver, queue: DispatchQueue) {
        <#code#>
    }
    
    public func removeStatusObserver(_ observer: PumpManagerStatusObserver) {
        <#code#>
    }
    
    public func ensureCurrentPumpData(completion: (() -> Void)?) {
        <#code#>
    }
    
    public func setMustProvideBLEHeartbeat(_ mustProvideBLEHeartbeat: Bool) {
        <#code#>
    }
    
    public func createBolusProgressReporter(reportingOn dispatchQueue: DispatchQueue) -> DoseProgressReporter? {
        <#code#>
    }
    
    public func enactBolus(units: Double, automatic: Bool, completion: @escaping (PumpManagerResult<DoseEntry>) -> Void) {
        <#code#>
    }
    
    public func cancelBolus(completion: @escaping (PumpManagerResult<DoseEntry?>) -> Void) {
        <#code#>
    }
    
    public func enactTempBasal(unitsPerHour: Double, for duration: TimeInterval, completion: @escaping (PumpManagerResult<DoseEntry>) -> Void) {
        <#code#>
    }
    
    public func suspendDelivery(completion: @escaping (Error?) -> Void) {
        <#code#>
    }
    
    public func resumeDelivery(completion: @escaping (Error?) -> Void) {
        <#code#>
    }
    
    public func setMaximumTempBasalRate(_ rate: Double) {
        <#code#>
    }
    
    public func syncBasalRateSchedule(items scheduleItems: [RepeatingScheduleValue<Double>], completion: @escaping (Result<BasalRateSchedule, Error>) -> Void) {
        <#code#>
    }
    
    public var managerIdentifier: String
    
    public var delegateQueue: DispatchQueue!
    
    public init?(rawState: RawStateValue) {
       
    }

    public var rawValue: RawValue {
        switch self {
        case .suspended(let date):
            return [
                "case": SuspendStateType.suspend.rawValue,
                "date": date
            ]
        case .resumed(let date):
            return [
                "case": SuspendStateType.resume.rawValue,
                "date": date
            ]
        }
    }
    
    public enum SuspendState: Equatable, RawRepresentable {
        public typealias RawValue = [String: Any]

        private enum SuspendStateType: Int {
            case suspend, resume
        }

        case suspended(Date)
        case resumed(Date)

        private var identifier: Int {
            switch self {
            case .suspended:
                return 1
            case .resumed:
                return 2
            }
        }

        public init?(rawValue: RawValue) {
            guard let suspendStateType = rawValue["case"] as? SuspendStateType.RawValue,
                let date = rawValue["date"] as? Date else {
                    return nil
            }
            switch SuspendStateType(rawValue: suspendStateType) {
            case .suspend?:
                self = .suspended(date)
            case .resume?:
                self = .resumed(date)
            default:
                return nil
            }
        }

        public var rawValue: RawValue {
            switch self {
            case .suspended(let date):
                return [
                    "case": SuspendStateType.suspend.rawValue,
                    "date": date
                ]
            case .resumed(let date):
                return [
                    "case": SuspendStateType.resume.rawValue,
                    "date": date
                ]
            }
        }
    }
    
    public var rawState: RawStateValue
    
    public func acknowledgeAlert(alertIdentifier: Alert.AlertIdentifier) {
        <#code#>
    }
    
    public func getSoundBaseURL() -> URL? {
        <#code#>
    }
    
    public func getSounds() -> [Alert.Sound] {
        <#code#>
    }
    
    public var localizedTitle: String = ""
    
    public var isOnboarded: Bool

}

extension DanaRSPumpManager {
    public var debugDescription: String {
       ""
    }
}

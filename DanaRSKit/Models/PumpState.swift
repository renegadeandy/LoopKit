//
//  PumpState.swift
//  LoopKit
//
//  Created by Andy Armstrong on 13/05/2021.
//  Copyright © 2021 LoopKit Authors. All rights reserved.
//

import Foundation


public struct PumpState: RawRepresentable, Equatable {
    public typealias RawValue = [String: Any]

    public var timeZone: TimeZone
    
    public var pumpModel: PumpModel?
    
    public var awakeUntil: Date?
    
    public var lastValidFrequency: Measurement<UnitFrequency>?
    
    public var lastTuned: Date?

    var isAwake: Bool {
        if let awakeUntil = awakeUntil {
            return awakeUntil.timeIntervalSinceNow > 0
        }

        return false
    }
    
    var lastWakeAttempt: Date?

    public init() {
        self.timeZone = .currentFixed
    }

    public init(timeZone: TimeZone, pumpModel: PumpModel) {
        self.timeZone = timeZone
        self.pumpModel = pumpModel
    }

    public init?(rawValue: RawValue) {
        guard
            let timeZoneSeconds = rawValue["timeZone"] as? Int,
            let timeZone = TimeZone(secondsFromGMT: timeZoneSeconds)
        else {
            return nil
        }

        self.timeZone = timeZone
        
        if let pumpModelNumber = rawValue["pumpModel"] as? PumpModel.RawValue {
            pumpModel = PumpModel(rawValue: pumpModelNumber)
        }
        
        if let frequencyRaw = rawValue["lastValidFrequency"] as? Double {
            lastValidFrequency = Measurement<UnitFrequency>(value: frequencyRaw, unit: .megahertz)
        }
    }

    public var rawValue: RawValue {
        var rawValue: RawValue = [
            "timeZone": timeZone.secondsFromGMT(),
        ]

        if let pumpModel = pumpModel {
            rawValue["pumpModel"] = pumpModel.rawValue
        }
        
        if let frequency = lastValidFrequency?.converted(to: .megahertz) {
            rawValue["lastValidFrequency"] = frequency.value
        }

        return rawValue
    }
}


extension PumpState: CustomDebugStringConvertible {
    public var debugDescription: String {

        return [
            "## PumpState",
            "timeZone: \(timeZone)",
            "pumpModel: \(pumpModel?.rawValue ?? "")",
            "awakeUntil: \(awakeUntil ?? .distantPast)",
            "lastValidFrequency: \(String(describing: lastValidFrequency))",
            "lastTuned: \(awakeUntil ?? .distantPast))",
            "lastWakeAttempt: \(String(describing: lastWakeAttempt))"
        ].joined(separator: "\n")
    }
}

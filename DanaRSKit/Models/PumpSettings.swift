//
//  PumpSettings.swift
//  LoopKit
//
//  Created by Andy Armstrong on 13/05/2021.
//  Copyright © 2021 LoopKit Authors. All rights reserved.
//

import Foundation
public struct PumpSettings: RawRepresentable {
    public typealias RawValue = [String: Any]

    public var pumpID: String

    public var pumpRegion: PumpRegion = .northAmerica

    public init?(rawValue: RawValue) {
        guard let pumpID = rawValue["pumpID"] as? String else {
            return nil
        }

        self.pumpID = pumpID

        if let pumpRegionRaw = rawValue["pumpRegion"] as? PumpRegion.RawValue,
            let pumpRegion = PumpRegion(rawValue: pumpRegionRaw) {
            self.pumpRegion = pumpRegion
        }
    }

    public init(pumpID: String, pumpRegion: PumpRegion? = nil) {
        self.pumpID = pumpID

        if let pumpRegion = pumpRegion {
            self.pumpRegion = pumpRegion
        }
    }

    public var rawValue: RawValue {
        return [
            "pumpID": pumpID,
            "pumpRegion": pumpRegion.rawValue
        ]
    }
}


extension PumpSettings: CustomDebugStringConvertible {
    public var debugDescription: String {
        return [
            "## PumpSettings",
            "pumpID: ✔︎",
            "pumpRegion: \(pumpRegion)",
        ].joined(separator: "\n")
    }
}

extension PumpSettings: Equatable {
    public static func ==(lhs: PumpSettings, rhs: PumpSettings) -> Bool {
        return lhs.pumpID == rhs.pumpID && lhs.pumpRegion == rhs.pumpRegion
    }
}
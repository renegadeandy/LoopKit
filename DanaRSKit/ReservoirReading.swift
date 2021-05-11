//
//  ReservoirReading.swift
//  LoopKit
//
//  Created by Andy Armstrong on 11/05/2021.
//  Copyright © 2021 LoopKit Authors. All rights reserved.
//

//
//  ReservoirReading.swift
//  MinimedKit
//
//  Created by Pete Schwamb on 2/4/19.
//  Copyright © 2019 Pete Schwamb. All rights reserved.
//

import Foundation
import LoopKit

public struct ReservoirReading: RawRepresentable, Equatable {

    public typealias RawValue = [String: Any]

    public let units: Double
    public let validAt: Date

    public init(units: Double, validAt: Date) {
        self.units = units
        self.validAt = validAt
    }

    public init?(rawValue: RawValue) {
        guard
            let units = rawValue["units"] as? Double,
            let validAt = rawValue["validAt"] as? Date
            else {
                return nil
        }

        self.units = units
        self.validAt = validAt
    }

    public var rawValue: RawValue {
        return [
            "units": units,
            "validAt": validAt
        ]
    }
}

extension ReservoirReading: ReservoirValue {
    public var startDate: Date {
        return validAt
    }

    public var unitVolume: Double {
        return units
    }
}

//
//  InsulinDataSource.swift
//  LoopKit
//
//  Created by Andy Armstrong on 13/05/2021.
//  Copyright © 2021 LoopKit Authors. All rights reserved.
//

import Foundation


public enum InsulinDataSource: Int, CustomStringConvertible {
    case pumpHistory = 0
    case reservoir

    public var description: String {
        switch self {
        case .pumpHistory:
            return LocalizedString("Event History", comment: "Describing the pump history insulin data source")
        case .reservoir:
            return LocalizedString("Reservoir", comment: "Describing the reservoir insulin data source")
        }
    }
}

//
//  PumpRegion.swift
//  LoopKit
//
//  Created by Andy Armstrong on 13/05/2021.
//  Copyright © 2021 LoopKit Authors. All rights reserved.
//

import Foundation
public enum PumpRegion: Int, CustomStringConvertible  {
    case northAmerica = 0
    case worldWide
    case canada
    
    public var description: String {
        switch self {
        case .worldWide:
            return LocalizedString("World-Wide", comment: "Describing the worldwide pump region")
        case .northAmerica:
            return LocalizedString("North America", comment: "Describing the North America pump region")
        case .canada:
            return LocalizedString("Canada", comment: "Describing the Canada pump region ")
        }
    }
}

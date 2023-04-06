//
//  Crop.swift
//  Coffee Display
//
//  Created by Brian Rosales on 4/6/23.
//

import SwiftUI

//Mark: Crop Config
enum Crop: Equatable {
    case circle
    case rectangle
    case square
    case custom(CGSize)
    
    //used to Display the button on the action sheet
    func name() -> String {
        switch self {
        case .circle:
            return "Circle"
        case .rectangle:
            return "Rectangle"
        case .square:
            return "Square"
        case let .custom(cGSize):
            return "Custom \(Int(cGSize.width))X\(Int(cGSize.height))"
        }
    }
    
    func size() -> CGSize {
        switch self {
        case .circle:
            return .init(width: 300, height: 300)
        case .rectangle:
            return .init(width: 300, height: 300)
        case .square:
            return .init(width: 300, height: 300)
        case .custom(let cGSize):
            return cGSize
        }
    }
}

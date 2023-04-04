//
//  ItemData.swift
//  Coffee Display
//
//  Created by Brian Rosales on 3/21/23.
//

import Foundation
struct BasicItem: Identifiable, Hashable {
    let id = UUID()
    var title: String = "Taco"
    var price: String = "$2.99"
    var description: String? = "Item description"
    var position: Int = 0
}



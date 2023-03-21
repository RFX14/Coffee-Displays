//
//  ItemData.swift
//  Coffee Display
//
//  Created by Brian Rosales on 3/21/23.
//

import Foundation
struct BasicItem: Identifiable, Hashable {
    let id = UUID()
    var title: String = "Yummy Taco"
    var price: String = "$2.99/lb"
    var description: String? = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua"
    var position: Int = 0
}

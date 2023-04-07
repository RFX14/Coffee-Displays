//
//  Screen.swift
//  Coffee Display
//
//  Created by Brian Rosales on 3/21/23.
//

import Foundation

struct Screen: Identifiable, Hashable  {
    static func == (lhs: Screen, rhs: Screen) -> Bool {
        if lhs.name == rhs.name {
            if lhs.items.count == rhs.items.count {
                for i in 0..<lhs.items.count {
                    if lhs.items[i] != rhs.items[i] {
                        return false
                    }
                }
                if lhs.images.count == rhs.images.count {
                    for i in 0..<lhs.images.count {
                        if lhs.images[i] != rhs.images[i] {
                            return false
                        }
                    }
                }
                return true
            }
        }
        return false
    }

    
    let id = UUID()
    let name: String
    var items: [BasicItem] = []
    var images: [Images] = []
}

//
//  Images.swift
//  Coffee Display
//
//  Created by Brian Rosales on 4/7/23.
//

import Foundation
import UIKit

struct Images: Identifiable, Hashable  {
    let id = UUID()
    var title: String? = "image"
    var link: String? = "N/A"
    var position: Int? = 0
    var image: UIImage? = UIImage(named: "imageTest.png")!
}


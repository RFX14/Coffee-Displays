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
    var title: String? = "Image"
    var position: Int? = 0
    var image: UIImage? = nil
}


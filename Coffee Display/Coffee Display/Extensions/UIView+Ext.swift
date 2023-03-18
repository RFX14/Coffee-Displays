//
//  UIView+Ext.swift
//  Coffee Display
//
//  Created by Brian Rosales on 3/17/23.
//

import UIKit

extension UIView {
    func pin(to superView: UIView) {
        translatesAutoresizingMaskIntoConstraints                                   = false
        topAnchor.constraint(equalTo: superView.topAnchor).isActive                 = true
        leadingAnchor.constraint(equalTo: superView.leadingAnchor).isActive         = true
        trailingAnchor.constraint(equalTo: superView.trailingAnchor).isActive       = true
        bottomAnchor.constraint(equalTo: superView.bottomAnchor).isActive           = true
    }
}

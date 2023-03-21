//
//  Coffee_DisplayApp.swift
//  Coffee Display
//
//  Created by Brian Rosales on 3/20/23.
//

import SwiftUI
import Firebase

@main
struct Coffee_DisplayApp: App {
    init() {
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            Screens(manager: .init())
        }
    }
}

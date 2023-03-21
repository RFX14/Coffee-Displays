//
//  Coffee_DisplayApp.swift
//  Coffee Display
//
//  Created by Brian Rosales on 3/20/23.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
      FirebaseApp.configure()

      return true
  }
}

@main
struct Coffee_DisplayApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            Screens(manager: .init())
        }
    }
}

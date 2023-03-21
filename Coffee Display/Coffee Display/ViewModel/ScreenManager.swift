//
//  ScreenManager.swift
//  Coffee Display
//
//  Created by Brian Rosales on 3/20/23.
//

import SwiftUI
import FirebaseFirestore

class ScreenManager: ObservableObject {
    init() {
    }
    func fetchCurrentScreensInfo() async -> [String: [ItemData]] {
        let db  = Firestore.firestore()
        let docRef = db.collection("users").document("test_acct")
        var screens: [String: [ItemData]] = [:]
        
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                let screensMap = data?["screens"] as? [String: Any] ?? [:]
                // loop Per Screen.
                for (curScreen, _) in screensMap {
                    let screenMap = screensMap["\(curScreen)"] as? [String: Any] ?? [:]
                    let screenName = "\(curScreen)"
                    // loop per item.
                    for (curItem, _) in screenMap {
                        let templateId = screenMap["templateID"] as? Int ?? 0
                        let itemSpec = screenMap["\(curItem)"] as? [String: Any] ?? [:]
                        // loop per item details.
                        for (_, _) in itemSpec {
                            let price = screenMap["price"] as? String ?? "0.00"
                            let position = screenMap["position"] as? Int ?? 0
                            let description = screenMap["description"] as? String ?? "N/A"
                            
                            let curItem = ItemData(screenName: screenName, description: description, position: position, price: price, templateID: templateId)
                            
                            if screens[screenName] == nil {
                                screens[screenName] = []
                            }

                            screens[screenName]?.append(curItem)
                        }
                    }
                    
                }
            } else {
                print("Document does not exist")
            }
        }
        print(screens)
        return screens
    }
    /*
    let data = document.data()
    let user = document.documentID
    let screenName = data["de"] as? String ?? "N/A"
    let description = data["descrption"] as? String ?? "N/A"
    let position = data["position"] as? Int ?? 0
    let price = data["price"] as? String ?? "N/A"
    let template = data["template"] as? Int ?? 0
    screensInfo[user] = currentScreenInfo
    print(screensInfo)
    return screensInfo
     */
}

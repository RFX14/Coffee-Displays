//
//  ScreenManager.swift
//  Coffee Display
//
//  Created by Brian Rosales on 3/20/23.
//

import SwiftUI
import FirebaseFirestore

class ScreenManager: ObservableObject {
    @Published var screens: [Screen] = []
    @Published var screen: String = "Austin"
    private var changes: [String: Any] = [:]
    
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var user: String = "test_acct"
    
    func uploadChanges() {
        db.collection("users").document(user).updateData([
            "screens.\(screen)": screens
        ])
    }
    
    // Note: completion handler was used to make sure everthing was completed before the name sorting would be completed in the main view.
    func fetchAvailableScreens(completion: @escaping(() -> Void)) {
        print("Fetching!!")
        db.collection("users").document(user).getDocument { [self] docSnapshot, err in
            guard let doc = docSnapshot else {
                print("Error fetching document: \(err!)")
                return
            }
            
            guard let data = doc.data() else {
                print("Error fetching data: \(err!)")
                return
            }
            
            let screens = data["screens"] as? [String: Any] ?? [:]
            
            for (name, item) in screens {
                let item = item as? [String: Any] ?? [:]
                var items: [BasicItem] = []
                for (title, details) in item {
                    let details = details as? [String: Any] ?? [:]
                    let price = details["price"] as? String ?? ""
                    let description = details["description"] as? String ?? ""
                    let position = details["position"] as? Int ?? 0
                    
                    items.append(.init(title: title, price: price, description: description, position: position))
                }
                
                self.screens.append(Screen(name: name, items: items))
            }
            completion()
        }
    }
    
    func deleteItems(newScreen: Screen) {
        for idx in screens.indices {
            if screens[idx].id == newScreen.id {
                //add the newScreen in manager Screens with the same index
                screens[idx] = newScreen
                print(screens)
                createFirebaseTemplate(index: idx)
            }
        }
    }
    

    func createFirebaseTemplate(index: Int) {
        var firebaseTemplate: [String: [String: Any]] = [:]
        for currentScreen in screens {
            if firebaseTemplate[currentScreen.name] == nil {
                firebaseTemplate[currentScreen.name] = [:]
            }
            
            for curItem in currentScreen.items {
                firebaseTemplate[currentScreen.name]?[curItem.title] = ["description": curItem.description ?? "N/A", "position": curItem.position, "price": curItem.price] as [String : Any]
            }
        }
        print(firebaseTemplate)
        updateFirebase(firebaseTemplate: firebaseTemplate)
    }
    
    func updateFirebase(firebaseTemplate: [String: [String: Any]] ) {
        db.collection("users").document(user).setData([
            "screens": firebaseTemplate
        ]) { err in
           if let err = err {
               print("Error adding document: \(err)")
           } else {
               print("Document added with ID")
           }
        }
    }
}

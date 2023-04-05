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
    
    /*
    func saveCurrentScreens(curScreenId: UUID) {
        //will probably have to loop through each item and then add it to firebase
        for (idx, screen) in screens.enumerated() {
            if screen.id == curScreenId {
                let curItemArray = screens[idx].items
                for curItem in curItemArray {
                    
                    db.collection("users").document(user).updateData([
                        "screens.\(screens[idx].name).\(curItem.title).description" : curItem.description,
                        "screens.\(screens[idx].name).\(curItem.position).position" : curItem.position,
                        //"screens.\(screens[idx].name).\(curItem.price).price" : curItem.price
                    ])
                }
            }
        }
    }
    */
    func createNewItemTemplate(index: Int) {
        var newItemTemplate: [String: [String: Any]] = [:]
        let currentScreen = screens[index]
        
        if newItemTemplate[currentScreen.name] == nil {
            newItemTemplate[currentScreen.name] = [:]
        }
        
        for curItem in currentScreen.items {
            newItemTemplate[currentScreen.name]?[curItem.title] = ["description": curItem.description, "position": curItem.position, "price": curItem.price]
        }
        
        addingItemToFirebase(newitem: newItemTemplate)
    }
    
    func addingItemToFirebase(newitem: [String: [String: Any]] ) {
        
        db.collection("users").document(user).setData([
            "screens": newitem
        ]) { err in
           if let err = err {
               print("Error adding document: \(err)")
           } else {
               print("Document added with ID")
           }
        }
    }
}

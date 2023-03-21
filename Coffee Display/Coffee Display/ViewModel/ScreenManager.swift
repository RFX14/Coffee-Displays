//
//  ScreenManager.swift
//  Coffee Display
//
//  Created by Brian Rosales on 3/20/23.
//

import SwiftUI
import FirebaseFirestore

class ScreenManager: ObservableObject {
    @Published var items: [BasicItem] = []
    @Published var isUsingCache = true
    
    private var screen: String = "Austin"
    private var user: String = "rfx14"
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    deinit {
        removeListener()
        print("Listener Removed!")
    }
    
    func removeListener() {
        listener?.remove()
    }
    
    func fetchItems() {
        listener = db.collection("users").document(user).addSnapshotListener(includeMetadataChanges: true) { [self] docSnapshot, err in
            print("Getting items!")
            guard let doc = docSnapshot else {
                print("Error fetching document: \(err!)")
                return
            }
            
            guard let data = doc.data() else {
                print("Error fetching data: \(err!)")
                return
            }
            
            isUsingCache = docSnapshot!.metadata.isFromCache ? true : false
            items = []
            
            let screens = data["screens"] as? [String: Any] ?? [:] // All screens
            let items = screens[self.screen] as? [String: Any] ?? [:] // Items at current screen
            
            for (title, details) in items {
                print("In \(title)")
                let details = details as? [String: Any] ?? [:]
                let price = details["price"] as? String ?? ""
                let description = details["description"] as? String ?? ""
                let position = details["position"] as? Int ?? 0
                
                self.items.append(.init(title: title, price: price, description: description, position: position))
            }
            //position represents the order in which the text & image will be saved on firebase
            self.items.sort(by: { $0.position < $1.position })
        }
    }
}

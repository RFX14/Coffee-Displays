//
//  ScreenManager.swift
//  Coffee Display
//
//  Created by Brian Rosales on 3/20/23.
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage
@MainActor
class ScreenManager: ObservableObject {
    @Published var screens: [Screen] = []
    @Published var screen: String = "Austin"
    @Published var imageLink: [UIImage: String] = [:]
    
    private var links: [String] = []
    private var linkWithImage: [String: UIImage] = [:]
    private var changes: [String: Any] = [:]
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var user: String = "test_acct"
    
    
    /*
    func uploadChanges() {
        db.collection("users").document(user).updateData([
            "screens.\(screen)": screens
        ])
    }
     */
    
    // Note: completion handler was used to make sure everthing was completed before the name sorting would be completed in the main view.
    //Current Issue: when ever I add another image to a screen it messes up the fetching and creates duplicate screens.
    func fetchAvailableScreens(completion: @escaping(() -> Void)) {
        self.db.collection("users").document(self.user).getDocument { docSnapshot, err in
            print("grab data")
            guard let doc = docSnapshot else {
                print("Error fetching document: \(err!)")
                return
            }
            
            guard let data = doc.data() else {
                print("Error fetching data: \(err!)")
                return
            }
            let allScreens = data["screens"] as? [String: Any] ?? [:]
            
            // Items
            for (curScreen, item) in allScreens {
                //print(item)
                let item = item as? [String: Any] ?? [:]
                var items: [BasicItem] = []
                var images: [Images] = []
                
                for (title, details) in item {
                     if title == "items" {
                        let item_details = details as? [String: [String: Any]] ?? [:]
                        for (item_name, item_values) in item_details {
                            let price = item_values["price"] as? String ?? ""
                            let description = item_values["description"] as? String ?? ""
                            let position = item_values["position"] as? Int ?? 0
                            
                            items.append(.init(title: item_name, price: price, description: description, position: position))
                            
                        }
                    }
                }
                //Images
                for (title, details) in item {
                    if title == "images" {
                        let image_details = details as? [String: [String: Any]] ?? [:]
                        
                        for (image_name, image_values) in image_details {
                            let image_link = image_values["link"] as? String ?? ""
                            let position = image_values["position"] as? Int ?? 0
                            images.append(.init(title: image_name, link: image_link, position: position, image: UIImage(named: "imageTest.png")!))
                            self.links.append(image_link)
                        }
                    }
                }
                
                self.screens.append(Screen(name: curScreen, items: items, images: images))
            }
            completion()
        }
    }
    func fetchImages(completion: @escaping (() -> Void)) {
        print("fetchImages")
        let storageRef = Storage.storage().reference()
        let group = DispatchGroup() // create a dispatch group
        for link in self.links {
            group.enter() // enter the group for each request
            let httpsReference = storageRef.storage.reference(forURL: link)
            httpsReference.getData(maxSize: 5 * 1024 * 1024) { data, error in
                if let error = error {
                    print(error.localizedDescription)
                } else if let data = data {
                    if let image = UIImage(data: data) {
                        self.linkWithImage[link] = image
                    } else {
                        print("Invalid image data")
                    }
                } else {
                    print("No data received")
                }
                group.leave() // leave the group when the request completes
            }
        }
        group.notify(queue: DispatchQueue.main) {
            print(self.linkWithImage)
            completion() // call the completion handler when all requests have completed
        }
    }
    
    func addNewImages(completion: @escaping (() -> Void)) {
        print("add new images")
        let group = DispatchGroup()
        for (i, curScreen) in self.screens.enumerated() {
            let images = curScreen.images
            for (j, curImage) in images.enumerated() {
                if let link = curImage.link {
                    if let newImage = self.linkWithImage[link] {
                        group.enter()
                        DispatchQueue.main.async {
                            self.screens[i].images[j].image = newImage
                            group.leave()
                        }
                    }
                }
            }
        }
        group.notify(queue: DispatchQueue.main) {
            completion()
        }
    }
    
    func deleteItems(newScreen: Screen) {
        for idx in screens.indices {
            if screens[idx].id == newScreen.id {
                //add the newScreen in manager Screens with the same index
                screens[idx] = newScreen
                //print(screens)
                createFirebaseTemplate(index: idx)
            }
        }
    }
    

    func createFirebaseTemplate(index: Int) {
        var firebaseTemplate: [String: [String: [String: Any]]] = [:]
        for currentScreen in screens {
            if firebaseTemplate[currentScreen.name] == nil {
                firebaseTemplate[currentScreen.name] = [:]
            }
            
            if firebaseTemplate[currentScreen.name]?["items"] == nil {
                firebaseTemplate[currentScreen.name]?["items"] = [:]
            }
            
            if firebaseTemplate[currentScreen.name]?["images"] == nil {
                firebaseTemplate[currentScreen.name]?["images"] = [:]
            }
            
            for curItem in currentScreen.items {
                firebaseTemplate[currentScreen.name]?["items"]?[curItem.title] = [
                    "description": curItem.description as Any,
                    "position": curItem.position,
                    "price": curItem.price
                ]
            }
            
            let group = DispatchGroup()
            
            for curImage in currentScreen.images {
                group.enter()
                
                if let image = curImage.image,
                   let imageKey = imageLink.keys.first(where: { $0 == image }),
                   let imageUrl = imageLink[imageKey] {
                    firebaseTemplate[currentScreen.name]?["images"]?[curImage.title ?? "image_0"] = [
                        "link": imageUrl,
                        "position": curImage.position
                    ]
                    group.leave()
                } else {
                    uploadImage(newImage: curImage.image ?? UIImage(named: "imageTest")!) { [weak self] newUrl in
                        guard let self = self else {
                            group.leave()
                            return
                        }
                        
                        self.imageLink[curImage.image ?? UIImage(named: "imageTest")!] = newUrl
                        
                        if let imageKey = self.imageLink.keys.first(where: { $0 == curImage.image }),
                           let imageUrl = self.imageLink[imageKey] {
                            firebaseTemplate[currentScreen.name]?["images"]?[curImage.title ?? "image_0"] = [
                                "link": imageUrl,
                                "position": curImage.position
                            ]
                        }
                        
                        group.leave()
                    }
                }
            }
            
            group.notify(queue: .main) {
                self.updateFirebase(firebaseTemplate: firebaseTemplate)
            }
        }
    }
    
    func uploadImage(newImage: UIImage, completion: @escaping ((String) -> ())) {
        guard let imageData = newImage.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        let storageRef = Storage.storage().reference()
        let path = "images/\(UUID().uuidString).jpg"
        let fileRef = storageRef.child(path)
        
        // Check if the file already exists
        fileRef.listAll { result, error in
            if let error = error {
                // Handle error
                print("Error listing files: \(error.localizedDescription)")
                return
            }
            
            let files = result?.items
            if files!.count > 0 {
                // File already exists, return its download URL
                files![0].downloadURL { url, error in
                    if let error = error {
                        // Handle error
                        print("Error getting download URL: \(error.localizedDescription)")
                        return
                    }
                    
                    if let url = url {
                        completion(url.absoluteString)
                    }
                }
            } else {
                // File does not exist, upload the new file
                let uploadTask = fileRef.putData(imageData, metadata: nil) { metadata, error in
                    if error == nil && metadata != nil {
                        fileRef.downloadURL { url, error in
                            if let error = error {
                                // Handle error
                                print("Error getting download URL: \(error.localizedDescription)")
                                return
                            }
                            
                            if let url = url {
                                completion(url.absoluteString)
                            }
                        }
                    }
                }
            }
        }
    }

    
    /*
    //Whats gonna happen is we upload the image to firebase and the retrieve the image link and then return that as string. which will then be saved to firebase. Note need to make sure if image already exist in storage, if so then we just return the link that is found globally.
    func uploadImage(newImage: UIImage, completion: @escaping((String) -> ())) {
        guard newImage != nil else {
            return
        }
        
        let storageRef = Storage.storage().reference()
        
        let imageData = newImage.jpegData(compressionQuality: 0.8)
        
        guard imageData != nil else {
            return
        }
        let path = "images/\(UUID().uuidString).jpg"
        let fileRef = storageRef.child(path)
        
        let uploadTask = fileRef.putData(imageData!, metadata: nil) { metadata, error in
            
            if error == nil && metadata != nil {
                completion(path)
            }
        }
    }
    */
    
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


extension String {
    subscript(i: Int) -> String {
        return  i < count ? String(self[index(startIndex, offsetBy: i)]) : ""
    }
}

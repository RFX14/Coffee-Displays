//
//  ScreenManager.swift
//  Coffee Display
//
//  Created by Brian Rosales on 3/20/23.
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage

class ScreenManager: ObservableObject {
    @Published var screens: [Screen] = []
    @Published var screen: String = "Austin"
    @Published var imageLink: [UIImage: String] = [:]
    
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
    func fetchAvailableScreens(completion: @escaping(() -> Void)) {
        //We going to wait for "fetchAvailableImages" and then run the stuff below
        fetchAvailableImages { fetchedImages in [self]
            self.db.collection("users").document(self.user).getDocument { docSnapshot, err in
                guard let doc = docSnapshot else {
                    print("Error fetching document: \(err!)")
                    return
                }
                
                guard let data = doc.data() else {
                    print("Error fetching data: \(err!)")
                    return
                }
                let screens = data["screens"] as? [String: Any] ?? [:]
                
                // Items
                for (screens, item) in screens {
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
                                
                                //Adding Images.
                                for (curScreen, image_details) in fetchedImages {
                                    for image_data in image_details {
                                        if images.last?.position != image_data.position && curScreen == screens {
                                            images.append(.init(title: image_data.title, position: image_data.position, image: image_data.image))
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    self.screens.append(Screen(name: screens, items: items, images: images))
                }
                print(self.screens)
                completion()
            }
        }
    }
    
    func fetchAvailableImages(completion: @escaping(([String: [Images]]) -> ())) {
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
            var allImages: [String: [Images]] = [:]
            var imageCounter: [String: Int] = [:]
            var isAllImagesDownloaded: [String: Bool] = [:]
            
            for (screensName, item) in screens {
                
                let item = item as? [String: Any] ?? [:]
                
                
                if allImages[screensName] == nil {
                    allImages[screensName] = []
                }
                
                if imageCounter[screensName] == nil {
                    imageCounter[screensName] = 0
                }
                
                if isAllImagesDownloaded[screensName] == nil {
                    isAllImagesDownloaded[screensName] = false
                }
                
                for (title, details) in item {
                    
                    if title == "images" {
                        let image_details = details as? [String: [String: Any]] ?? [:]
                        
                        for (image_name, image_values) in image_details {
                            let image_link = image_values["link"] as? String ?? ""
                            let position = image_values["position"] as? Int ?? 0
                            
                            
                            let storageRef = Storage.storage().reference()
                            let httpsReference = storageRef.storage.reference(forURL: image_link)

                            
                            
                            httpsReference.getData(maxSize: 5 * 1024 * 1024) { data, error in
                                if error == nil && data != nil {
                                    let cur_image = UIImage(data: data!)
                                    self.imageLink[cur_image ?? UIImage(named: "imageTest.png")!] = image_link
                                    allImages[screensName]?.append(Images(title: image_name, position: position, image: cur_image))
                                    imageCounter[screensName]! += 1
                                    
                                    for (curScreen, _) in allImages {
                                        if allImages[curScreen]?.count == imageCounter[curScreen] {
                                            isAllImagesDownloaded[screensName] = true
                                        } else if allImages[curScreen]?.count != imageCounter[curScreen] {
                                            isAllImagesDownloaded[screensName] = false
                                        }
                                    }
                                    
                                    if isAllImagesDownloaded.allSatisfy({$0.value == true}) {
                                        completion(allImages)
                                    }
                                } else if data == nil {
                                    print("No Data")
                                }
                            }
                        }

                    }
                }
            }
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
            
            //if image exist in storage we will just use the url saved in the dictionary. Otherwise we will upload the image to storage and then grab url.
            for curItem in currentScreen.items {
                firebaseTemplate[currentScreen.name]?["items"]?[curItem.title] = ["description": curItem.description as Any, "position": curItem.position, "price": curItem.price] as [String : Any]
            }
            for curImage in currentScreen.images {
                if imageLink.keys.contains((curImage.image ?? UIImage(named: "imageTest"))!) {
                    firebaseTemplate[currentScreen.name]?["images"]?[curImage.title ?? "image_0"] = ["link": imageLink[(curImage.image ?? UIImage(named: "imageTest"))!] as Any, "position": curImage.position as Any]
                } else {
                    uploadImage(newImage: curImage.image!, completion: { newUrl in
                        //TO DO: Look into how often to delete photos from firebase
                        //Saves new image & url in dictionary
                        self.imageLink[(curImage.image ?? UIImage(named: "imageTest"))!] = newUrl
                        
                        if self.imageLink.keys.contains((curImage.image ?? UIImage(named: "imageTest"))!) {
                            firebaseTemplate[currentScreen.name]?["images"]?[curImage.title ?? "image_0"] = ["link": self.imageLink[(curImage.image ?? UIImage(named: "imageTest"))!] as Any, "position": curImage.position as Any]
                        } else {
                            print("something went wrong")
                        }
                        print("image uploaded:\t\(newUrl)")
                    })
    
                }
            }
        }
        print(firebaseTemplate)
        updateFirebase(firebaseTemplate: firebaseTemplate)
    }
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
    
    func fetchImageURL(imagePath: String,completion: @escaping((String) -> ())) {
        // Create a reference to the file you want to download
        let storageRef = Storage.storage().reference()
        let fileRef = storageRef.child(imagePath)

        // Fetch the download URL
        fileRef.downloadURL { url, error in
          if let error = error {
            // Handle any errors
              print("something went wrong")
          } else {
              let newURL = url?.absoluteString
              completion(newURL ?? "N/A")
          }
        }
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


extension String {
    subscript(i: Int) -> String {
        return  i < count ? String(self[index(startIndex, offsetBy: i)]) : ""
    }
}

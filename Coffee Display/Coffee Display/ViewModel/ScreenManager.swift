//
//  ScreenManager.swift
//  Coffee Display
//
//  Created by Brian Rosales on 3/20/23.
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage
// Ok we going to limit the amount of images per user to ten. This will help us not have so many image/duplicates. Probably we shall allow each user to delete any photos on the cloud. Does that mean we want them to also choose photos from the cloud? more than likely yes!(still debating on doing that right now...)
@MainActor
class ScreenManager: ObservableObject {
    @Published var screens: [Screen] = []
    @Published var screen: String = "Austin"
    @Published var imageLink: [UIImage: String] = [:]
    
    var curImages: [UIImage: String] = [:]
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

    func processImageUrls(completion: @escaping () -> Void) {
        // Create a dispatch group
        let group = DispatchGroup()
        
        // Example: Download the images
        for imageUrl in links {
            let url = URL(string: imageUrl)
            // Enter the dispatch group
            group.enter()
            
            downloadImage(from: url!) {
                // Leave the dispatch group when image download is finished
                group.leave()
            }
        }
        
        // Notify the group when all image downloads are finished
        group.notify(queue: .main) {
            //Don't know why but I'm only getting testImage.png...
            //print(self.curImages)
            //print(self.linkWithImage)
            // Call the completion closure
            completion()
        }
    }

    
    func downloadImage(from url: URL, completion: @escaping () -> Void) {
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                // Handle error
                print("Error downloading image: \(error.localizedDescription)")
                completion()
                return
            }
            
            // Process the downloaded image data as needed
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    
                    self.curImages[image] = "\(url)"
                    self.linkWithImage["\(url)"] = image
                    //print(self.curImages)
                    completion()
                }
            } else {
                DispatchQueue.main.async {
                    completion()
                }
            }
        }.resume()
    }

    
    // Note: completion handler was used to make sure everthing was completed before the name sorting would be completed in the main view.
    //Current Issue: when ever I add another image to a screen it messes up the fetching and creates duplicate screens.
    func fetchAvailableScreens(completion: @escaping(() -> Void)) {
        self.db.collection("users").document(self.user).getDocument { docSnapshot, err in
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
                //Images (this will be modified and merged with something)
                for (title, details) in item {
                    if title == "images" {
                        let image_details = details as? [String: [String: Any]] ?? [:]
                        
                        for (image_name, image_values) in image_details {
                            let image_link = image_values["link"] as? String ?? ""
                            let position = image_values["position"] as? Int ?? 0
                            images.append(.init(title: image_name, link: image_link, position: position, image: UIImage(named: "imageTest.png")!))
                            // Will be used to grab the images and refill screens.image with the proper images. will call download images which will populate a dictionary...(linkWithImage) we will use addImages to merge everything.
                            self.linkWithImage[image_link] = UIImage(named: "imageTest.png")!
                            self.links.append(image_link)
                        }
                    }
                }
                self.screens.append(Screen(name: curScreen, items: items, images: images))
            }
            completion()
        }
    }
    //Since simply updates Screen with the images that were found in storage.
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
                    } else {
                        print(curImage.link)
                        print("image not found")
                    }
                }
            }
        }
        group.notify(queue: DispatchQueue.main) {
            print(self.linkWithImage)
            completion()
        }
    }
    
    func deleteItems(newScreen: Screen) {
        for idx in screens.indices {
            if screens[idx].id == newScreen.id {
                //add the newScreen in manager Screens with the same index
                screens[idx] = newScreen
                //print(screens)
                createFirebaseTemplate()
            }
        }
    }
    
    //it seem when an image is updated firebase ended up deleting the other image that was not updated. so like if there is image_1 and image_2, and I updated the photo of image_2 then image_1 would be deleted... either its not saving to Screens or its not adding to firebasetemplate...
    func createFirebaseTemplate() {
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
                //chatgpt made this fancy...
                if let image = curImage.image,
                   let imageKey = imageLink.keys.first(where: { $0 == image }),
                   let imageUrl = imageLink[imageKey] {
                    firebaseTemplate[currentScreen.name]?["images"]?[curImage.title ?? "image_0"] = [
                        "link": imageUrl,
                        "position": curImage.position
                    ]
                    group.leave()
                } else {
                    //basically if the image does not exist in imageLink dictionary than we add it to firebase... is that what we want though since we will update...will check this later...
                    //this might change b/c I will update imageLink with all the images and url that are in firebase... jun 1, 2023
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
                print("firebase Template: \(firebaseTemplate)")
                //erasing the images that were not updated.
                self.updateFirebase(firebaseTemplate: firebaseTemplate)
            }
        }
    }
    
    //sends NEW pictures twice if we changed one photo. Gotta see why...I'm confused. ill figure it out tho
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
            
            
            print("New IMAGE: \(newImage)")
            if self.curImages.contains(where: { $0.key == newImage })  {
                print("Found Image")
                completion(self.curImages[newImage]!)
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
                            //The adding to curImages needs more work it keep adding alot of things
                            if let url = url {
                                print("added New Image: \(newImage)")
                                //Save new image to curImages
                                self.curImages[newImage] = "\(url)"
                                completion(url.absoluteString)
                            }
                        }
                    }
                }
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

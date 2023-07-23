//
//  ScreenManager.swift
//  Coffee Display
//
//  Created by Brian Rosales on 3/20/23.
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import CryptoKit
//current Issue: So b/c url and images structures are unique I'm going to have to use SHA-256 b/c that will ACTUALLY check if images are the same. That being said I will probably have to download images for database and convert them to SHA-256. I'll probably save it to the dictionary but in a different form. So in dictionary: key = SHA256: Value [dictionary(image and url)]. So when I save them to the dictionary if SHA256 exist we don't add it. Only problem is that I will start calling alot of image downloads. Which can be a problem however if we treat aschyc in should be a problem.

// first step: grab urls from data base, download images, convert to SHA256 and then save it to dictionary

// 2nd step: download all images from storage, convert to SHA256 and then save to dictionary.

// Note: Make the func for converting to SHA256 as flexible as possible so it be used by multiple functions.
@MainActor
class ScreenManager: ObservableObject {
    @Published var screens: [Screen] = []
    @Published var screen: String = "Austin"
    //I'm wondering if we can flip this? so that its url: UIimage? not yet.. but thats the goal.
    @Published var imageLink: [UIImage: String] = [:]
    
    private var urlsFromDatabase: [String] = []
    private var links: [String] = []
    // This will be used to store and as well update screens with the latest images from firebase
    private var currentImagesInStorage: [String: Any] = [:]
    private var linksWithImages: [String: UIImage] = [:] //Maybe will be deleted for the new dictionary of [SHA256: [image: UImage, image_url: string]]
    private var changes: [String: Any] = [:]
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var user: String = "test_acct"
    
    //right after this create a function that converts to SHA256 and then returns that value.
    func fetchImagesFromDatabase(completion: @escaping () -> Void) {
        let storage = Storage.storage()
        let dispatchGroup = DispatchGroup()
        var tempcurrentImagesInStorage = currentImagesInStorage

        for imageURL in self.urlsFromDatabase {
            dispatchGroup.enter()

            // Get a reference to the image with the specified URL
            let imageRef = storage.reference(forURL: imageURL)
            
            // Download the image data
            imageRef.getData(maxSize: 10 * 1024 * 1024) { (data, error) in
                if let error = error {
                    print("Error fetching image data for URL \(imageURL): \(error.localizedDescription)")
                } else {
                    // If image data is successfully retrieved, create a UIImage from the data
                    if let imageData = data {
                        // Call ConvertToSHA256 and then save to dictionary
                        let sHA256Hash = self.convertToSHA256(imageData: imageData)
                        tempcurrentImagesInStorage[sHA256Hash] = ["image": UIImage(data: imageData) ?? UIImage(named: "imageTest.png")!, "link": imageURL] as [String : Any]
                    }
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.currentImagesInStorage = tempcurrentImagesInStorage
            completion()
        }
    }
    
    func convertToSHA256(imageData: Data) -> String {
        let hashedData = SHA256.hash(data: imageData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    func fetchAllImages(completion: @escaping () -> Void) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        var tempcurrentImagesInStorage = currentImagesInStorage

        // Assuming you have a folder named "images" in Firebase Storage
        let imagesRef = storageRef.child("images")

        // Create a dispatch group
        let dispatchGroup = DispatchGroup()
        var counter: [String] = []

        // Fetch the list of items (images) in the "images" folder
        imagesRef.listAll { (result, error) in
            if let error = error {
                print("Error fetching images: \(error.localizedDescription)")
                completion() // Call the completion block with an error if needed
                return
            }

            // Enumerate through the list of items (images)
            for imageRef in result?.items ?? [] {
                dispatchGroup.enter() // Enter the dispatch group before starting each image retrieval
                
                imageRef.getData(maxSize: 10 * 1024 * 1024) { (data, error) in
                    defer {
                        dispatchGroup.leave() // Leave the dispatch group once the image data is fetched
                    }
                    
                    if let error = error {
                        print("Error fetching image data: \(error.localizedDescription)")
                        return
                    }

                    if let imageData = data {
                        imageRef.downloadURL { (url, error) in
                            if let error = error {
                                print("Error fetching download URL: \(error.localizedDescription)")
                                return
                            }

                            if let downloadURL = url {
                                let sHA256Hash = self.convertToSHA256(imageData: imageData)
                                tempcurrentImagesInStorage[sHA256Hash] = ["image": UIImage(data: imageData) ?? UIImage(named: "imageTest.png")!, "link": String(describing: downloadURL)] as [String : Any]
                                //just a counter(will probably change)
                                counter.append(String(describing: downloadURL))

                                // Check if all images have been processed and download URLs are retrieved
                                if counter.count == result?.items.count {
                                    completion()
                                }
                            }
                        }
                    }
                }
            }
        }
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
                            
                            items.append(.init(title: item_name, price: price, description: description, position: position ))
                            
                        }
                    }
                }
                for (title, details) in item {
                    if title == "images" {
                        let image_details = details as? [String: [String: Any]] ?? [:]
                    
                        for (image_name, image_values) in image_details {
                            let image_link = image_values["link"] as? String ?? ""
                            let position = image_values["position"] as? Int ?? 0
                            images.append(.init(title: image_name, link: image_link, position: position, image: UIImage(named: "imageTest.png")!))
                            self.urlsFromDatabase.append(image_link)
                        }
                    }
                }
                self.screens.append(Screen(name: curScreen, items: items, images: images))
            }
            completion()
        }
    }
    
    //this will probably be deleted. I'm wondering if I should add the SHA256 to the database b/c I dont know what images belong to each screen or image box.
    func addNewImages(completion: @escaping (() -> Void)) {
        print("add new images")
        let group = DispatchGroup()
        
        // Create a temporary copy of the global 'screens' array
        var tempScreens = self.screens
        
        for (i, curScreen) in tempScreens.enumerated() {
            let images = curScreen.images
            for (j, curImage) in images.enumerated() {
                if let link = curImage.link {
                    // Basically, if the URL exists in the dictionary as a KEY, then we grab the image and update tempScreens with it.
                    if let image = self.linksWithImages[link] {
                        print("updating tempScreens")
                        group.enter()
                        DispatchQueue.main.async {
                            tempScreens[i].images[j].image = image
                            group.leave()
                        }
                    } else {
                        print("Image not found for link: \(link)")
                    }
                }
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            // Update the global 'screens' variable with the temporary copy
            self.screens = tempScreens
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
                        "position": curImage.position ?? -1
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
                                "position": curImage.position ?? -1
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
    
    //sends NEW pictures twice if we changed one photo...I wonder if we should avoid checking storage and just download everything locally... would that bite us in the butt? like if we limit 10 per user I think we should be fine...yeah that should works. its just we need to make sure
    func uploadImage(newImage: UIImage, completion: @escaping (String) -> Void) {
        guard let imageData = newImage.jpegData(compressionQuality: 0.8) else {
            print("Cannot Convert To Image.")
            return
        }
        
        // Makes sure its not the test image.
        guard newImage != UIImage(named: "imageTest.png") else {
            print("image Test: \(newImage)")
            return
        }
        
        // Ignores Test Image
        guard newImage != UIImage(named: "imageTest") else {
            print("imageData is equal to imageTest")
            return
        }
        
        // Checks if images already exists (This part needs work, I'm not sure if every image is unique interally, look into it.
        print("imageLInk: \(imageLink)")
        print("newImage: \(newImage)")
        if let urlFound = imageLink[newImage] {
            completion("\(String(describing: urlFound))")
        }

        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        // Replace "images/image.jpg" with your desired path and filename
        let imageRef = storageRef.child("images/\(UUID().uuidString).jpg")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        let uploadTask = imageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                return
            } else {
                imageRef.downloadURL { url, error in
                    completion("\(String(describing: url))")
                }
            }
        }

        // Optionally, observe the progress of the upload
        uploadTask.observe(.progress) { snapshot in
            let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
                / Double(snapshot.progress!.totalUnitCount)
            print("Upload progress: \(percentComplete)%")
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

//
//  ScreenManager.swift
//  Coffee Display
//
//  Created by Brian Rosales on 3/20/23.
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage
//current Issue: so this is just a guess. But since I grab the images twice from different functions that way they are "grabbed" each image has a different number/encoding which inturn makes curImages not match the other images. gotta look into it.
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
    
    //Will fetch all the urls images for the current user. This will then call another function that will fetch the images and save curImages. This will be used to determine whether or not an image exist in firebase or not.
    func fetchUrlsForUser(completion: @escaping () -> Void) {
        let storageRef = Storage.storage().reference()
        let imagesRef = storageRef.child("images")

        // List all items (images) in the folder
        imagesRef.listAll { result, error in
            if let error = error {
                // Handle error
                print("Error listing images: \(error.localizedDescription)")
                completion()
                return
            }
            
            // Retrieve the list of items (images)
            let items = result?.items
            
            // Create an array to store the URLs of the images
            var imageUrls: [URL] = []
            
            // Create a dispatch group
            let group = DispatchGroup()
            
            // Iterate over the items
            for item in items ?? [] {
                // Enter the dispatch group
                group.enter()
                
                // Get the download URL for each image
                item.downloadURL { (url, error) in
                    if let error = error {
                        // Handle error
                        print("Error getting download URL: \(error.localizedDescription)")
                    } else if let url = url {
                        // Store the download URL in the array
                        imageUrls.append(url)
                    }
                    
                    // Leave the dispatch group
                    group.leave()
                }
            }
            
            // Notify the group when all tasks are complete
            group.notify(queue: .main) {
                // Use the imageUrls array as needed
                // For example, you can pass it to a function for further processing
                self.processImageUrls(imageUrls) {
                    // Call the completion closure when all image downloads are finished
                    completion()
                }
            }
        }
    }

    func processImageUrls(_ imageUrls: [URL], completion: @escaping () -> Void) {
        // Perform any desired actions with the image URLs
        // For example, you can display the images or download them
        
        // Create a dispatch group
        let group = DispatchGroup()
        
        // Example: Download the images
        for imageUrl in imageUrls {
            // Enter the dispatch group
            group.enter()
            
            downloadImage(from: imageUrl) {
                // Leave the dispatch group when image download is finished
                group.leave()
            }
        }
        
        // Notify the group when all image downloads are finished
        group.notify(queue: .main) {
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
                self.curImages[image] = "\(url)"
            }
            
            completion()
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
            //print(self.linkWithImage)
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
    
    //it seem when an image is updated firebase ended up deleting the other image that was not updated. so like if there is image_1 and image_2, and I updated the photo of image_2 then image_1 would be deleted... either its not saving to Screens or its not adding to firebasetemplate...
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
                //firebaseTemplate is right... how updateFirebase is not reading it right....
                self.updateFirebase(firebaseTemplate: firebaseTemplate)
            }
        }
    }
    
    //should only activate if images were never changed!
    func createFirebaseTemplateTextOnly(index: Int) {
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
                firebaseTemplate[currentScreen.name]?["items"]?[curItem.title] = ["description": curItem.description, "position": curItem.position, "price": curItem.price]
            }
            
            for curImage in currentScreen.images {
                if imageLink.keys.contains(curImage.image!) {
                    firebaseTemplate[currentScreen.name]?["images"]?[curImage.title ?? "image_0"] = ["link": imageLink[(curImage.image ?? UIImage(named: "imageTest"))!
    ], "position": curImage.position]
                } else {
                    firebaseTemplate[currentScreen.name]?["images"]?[curImage.title ?? "image_0"] = ["link": curImage.link, "position": curImage.position]
                }
            }
        }
        //print(firebaseTemplate)
        updateFirebase(firebaseTemplate: firebaseTemplate)
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
            print("IMAGE: \(newImage)")
            print(self.curImages)
            // Check if specific image already exists(STILL NEEDS WORK) Must compare images to each other make sure to check really should check if in
            //The idea is if we find out that the image already exist in firebase storage than we send back a string that notifies to not update the link. However we still need to see if firebase will allow us to compare or else I will have to download each image which is not Ideal and will force me to find another way to compare images.
            if self.curImages.contains(where: { $0.key == newImage })  {
                print("active")
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
                                completion(url.absoluteString)
                            }
                        }
                    }
                }
            }
        }
    }


    func updateFirebase(firebaseTemplate: [String: [String: [String: Any]]] ) {
        
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

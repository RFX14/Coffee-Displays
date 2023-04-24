//
//  TestManager.swift
//  Coffee Display
//
//  Created by Brian Rosales on 4/23/23.
//

import Foundation
import Firebase
import FirebaseStorage
class TestManager: ObservableObject {
    var allLinks: [String] = []
    private var db = Firestore.firestore()
    
    func fetchLinks() {
        // Create a reference to the file you want to download
        let storageRef = Storage.storage().reference()
        let starsRef = storageRef.child("images/8CF1AF73-9647-4997-B05A-AF94C16FC458.jpg")

        // Fetch the download URL
        starsRef.downloadURL { url, error in
          if let error = error {
            // Handle any errors
              print("something went wrong")
          } else {
            // Get the download URL for 'images/stars.jpg'
              print("This is the url: \t \(url)")
          }
        }

    }
}

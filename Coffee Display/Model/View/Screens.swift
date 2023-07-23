//
//  Screens.swift
//  Coffee Display
//
//  Created by Brian Rosales on 3/20/23.
//

import SwiftUI

struct Screens: View {
    @StateObject var manager: ScreenManager
    @State var selectedScreen: Screen?
    
    var body: some View {
        NavigationSplitView {
            // Makes list of all the current screens
            List(manager.screens, id: \.self, selection: $selectedScreen) { screen in
                Text(screen.name)
            }
        } detail: {
            if selectedScreen != nil {
                ImageEditor(manager: manager, selectedScreen: selectedScreen!)
            } else {
                Text("Select Screen To View & Edit")
            }
        }
        .onAppear {
            //Honestly in the future look into this occuring ever minute or so.(just incase other devices are using the same account)
            
            // Grabs all the images and urls that are currently being displayed.
            //This forces test image so fetching allImages should come after this to overwrite dictionary.
            manager.fetchAvailableScreens {
                //Download images that are for the database side and add to global dictionary.
                manager.fetchImagesFromDatabase() {
                    // Fetches all images and saves to dictionary
                    manager.fetchAllImages {
                        // Add all image to screens
                        manager.addNewImages {
                            //print("Screens: \(manager.screens)")
                            manager.screens.sort(by: {$0.name < $1.name})
                        }

                    }
                }
            }
        }
    }
}

struct Screens_Previews: PreviewProvider {
    static var previews: some View {
        Screens(manager: ScreenManager())
    }
}

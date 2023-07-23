//
//  ImageEditor.swift
//  Coffee Display
//
//  Created by Brian Rosales on 3/21/23.
//

import SwiftUI
struct ImageEditor: View {
    
    @StateObject var manager: ScreenManager
    @State var selectedScreen: Screen
    @State var numColumns = 1
    
    @State private var oldItems: [BasicItem] = []
    @State private var selectedItemIdx: Int = 0
    @State private var selectedImageIdx: Int = 0
    @State private var showSharedMenu = false
    @State private var createNewItem = false
    
    @State private var newItemName = ""
    @State private var newItemPrice = ""
    @State private var newItemDescription = ""
    
    @Environment(\.editMode) private var editMode
    @State private var canKeepAdding = true
    @State private var canKeepSubtracting = false
    
    @State private var location: CGPoint = CGPoint(x: 430, y: 155)
    @GestureState private var fingerLocation: CGPoint? = nil
    @GestureState private var startLocation: CGPoint? = nil
    
    //Image variables
    @State private var showingImagePicker = false
    @State private var croppedImage: UIImage? = nil
    @State private var oldImages = [1]
    
    /*
    var simpleDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                var newLocation = startLocation ?? location // 3
                newLocation.x += value.translation.width
                newLocation.y += value.translation.height
                self.location = newLocation
            }.updating($startLocation) { (value, startLocation, transaction) in
                startLocation = startLocation ?? location // 2
            }
    }
    
    
    var fingerDrag: some Gesture {
        DragGesture()
            .updating($fingerLocation) { (value, fingerLocation, transaction) in
                fingerLocation = value.location
                //print("fingerDrag activated")
            }
    }
    */
    //Need to fix the multiple uploads of images to firebase...will check
    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack {
                    List {
                        Section("TextField") {
                            ForEach(selectedScreen.items.indices, id: \.self) { idx in
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(selectedScreen.items[idx].title)
                                            .fontWeight(.medium)
                                        Spacer()
                                        Text(selectedScreen.items[idx].price)
                                    }
                                    Text(selectedScreen.items[idx].description ?? "")
                                }.contentShape(Rectangle())
                                .onTapGesture {
                                    let item = selectedScreen.items[idx]
                                    newItemName = item.title
                                    newItemPrice = item.price
                                    newItemDescription = item.description ?? ""
                                    showSharedMenu = true
                                    selectedItemIdx = idx
                                }
                            }
                            .onMove(perform: move)
                            .onDelete { indexSet in
                                selectedScreen.items.remove(atOffsets: indexSet)
                                updateItemsWithChanges(screen: selectedScreen)
                                //manager.deleteItems(newScreen: selectedScreen)
                            }
                        }
                        
                        Section("Images") {
                            ForEach(selectedScreen.images.indices, id: \.self) { idx in
                                VStack(alignment: .leading) {
                                    ZStack {
                                        HStack {
                                            if let image = selectedScreen.images[idx].image {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 100, height: 100)
                                            }
                                            Text("\t\t\t:Image \(idx)")
                                        }
                                    }
                                    .onTapGesture {
                                        showingImagePicker = true
                                        selectedImageIdx = idx
                                    }
                                }
                            }
                            .onMove(perform: moveImage)
                        }
                        
                        Button(action: {
                            let group = DispatchGroup()
                            // Issue: Not saving to firebase properly. url is an optional why?
                            for (idx, curImage) in selectedScreen.images.enumerated() {
                                // Enter the group before the loop
                                group.enter()
                                // we wanna make sure for any image we change we get a url back for upload image.
                                manager.uploadImage(newImage: curImage.image!) { imagePath in
                                    // Update the imageLink Dictionary.
                                    //This is just saving to the list of images/links we know exist in firebase storage.
                                    manager.imageLink[selectedScreen.images[idx].image!] = imagePath
                                    // newImage is already in selectedScreen we now just updating it with the URL
                                    self.selectedScreen.images[idx].link = imagePath // This works
                                    group.leave()
                                }
                            }
                            group.notify(queue: .main) {
                                // Action to perform when the button is tapped/later fix the updating firebase again...may 25
                                updateItemsWithChanges(screen: selectedScreen)
                                //there is a possibility that updateItems is not finishing so when we grab the newurls then that dictionary is not updated. which ends up uploading duplicates of the same thing. remember curImage in manager holds any images that exist in storage.
                            }
                            
                        }) {
                            Text("Submit Changes")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .onChange(of: croppedImage) { newImage in
                            //this is getting a little confusing, when ever I change an image it should save the image to the selectedScreens. When that happens forEach will visually change it on the screen. The important thing is that this should be saved to selectedscreen and then when submit button is pressed it should loop through the selectedScreen Images and based whats on their upload or return a url associated with that image. And thats what images should be returning... each time it has to call the function which should return a url and we save that new url to the selected screen....
                            if let newImage = newImage {
                                selectedScreen.images[selectedImageIdx].image = newImage
                                self.croppedImage = nil
                            }
                        }
                    }.onAppear {
                        print("View Appearing!")
                        //print("\t\(selectedScreen.items.first?.title)")
                        oldItems = selectedScreen.items
                        //print("\tOld Items Stored")
                    }.onDisappear {
                        //will probably delete this
                        /*
                        print("View Disappearing!")
                        selectedScreen.items = oldItems
                        updateFullArrayWithChanges(screen: selectedScreen)
                        print("\t\(selectedScreen.items.first?.title)")
                        print("\t\(oldItems.first?.title)")
                        print("\tItems Reset")
                         */
                    }
                }
            }.toolbar {
                EditButton()
                Button(action: {
                    print("Add Stuff!")
                    showSharedMenu = true
                    createNewItem = true
                    newItemName = ""
                    newItemPrice = ""
                    newItemDescription = ""
                }, label: {
                    Image(systemName: "plus")
                }).alert(createNewItem ? "Add New Item" : "Edit Item", isPresented: $showSharedMenu) {
                    TextField("Item Name", text: $newItemName)
                    TextField("Item Price", text: $newItemPrice)
                    TextField("Item Description", text: $newItemDescription)
                    
                    Button(role: .cancel, action: {
                        print(createNewItem ? "Adding Cancelled!" : "Editing Cancelled!")
                        createNewItem = false
                    }, label: {
                        Text("Cancel")
                    })
                    
                    Button(action: {
                        print(createNewItem ? "Adding to Array!" : "Editing Item")
                        if createNewItem {
                            let newPosition = selectedScreen.items.count
                            selectedScreen.items.append(.init(title: newItemName, price: newItemPrice, description: newItemDescription, position: newPosition))
                            addItemsToScreen(screen: selectedScreen)
                        } else {
                            selectedScreen.items[selectedItemIdx].title = newItemName
                            selectedScreen.items[selectedItemIdx].price = newItemPrice
                            selectedScreen.items[selectedItemIdx].description = newItemDescription
                        }
                        createNewItem = false
                    }, label: {
                        Text("Ok")
                    })
                }
            }.onChange(of: numColumns) { _ in
                if numColumns <= 11 {
                    canKeepAdding = true
                } else {
                    canKeepAdding = false
                }
                
                if numColumns > 1 {
                    canKeepSubtracting = true
                } else {
                    canKeepSubtracting = false
                }
            }.onAppear {
                manager.screen = selectedScreen.name
                selectedScreen.items.sort(by: {$0.position < $1.position})
                selectedScreen.images.sort(by: {$0.position ?? 0 < $1.position ?? 1})
                location = .init(x: geo.size.height / 2, y: geo.size.width / 2)
            }
            //Turned off other shapes.
            .cropImagePicker(options: [.custom(.init(width: 400, height: 400))], show: $showingImagePicker, croppedImage: $croppedImage)
        }
    }
    
    //Movement for Items
    func move(from source: IndexSet, to destination: Int) {
        selectedScreen.items.move(fromOffsets: source, toOffset: destination)
        updatePositionIndexes()
        updateFullArrayWithChanges(screen: selectedScreen)
    }
    
    func updatePositionIndexes() {
        for idx in 0..<selectedScreen.items.count {
            selectedScreen.items[idx].position = idx
        }
        selectedScreen.items.sort(by: {$0.position < $1.position})
    }
    
    //Movement for Images
    func moveImage(from source: IndexSet, to destination: Int) {
        selectedScreen.images.move(fromOffsets: source, toOffset: destination)
        updateImagePositionIndexes()
        updateFullArrayWithChanges(screen: selectedScreen)
    }
    
    func updateImagePositionIndexes() {
        for idx in 0..<selectedScreen.images.count {
            selectedScreen.images[idx].position = idx
        }
        selectedScreen.images.sort(by: {$0.position ?? 0 < $1.position ?? 0})
    }
    
    func addItemsToScreen(screen: Screen) {
        for idx in manager.screens.indices {
            //checks that the current screen is the only one that is updated with the new item.
            if manager.screens[idx].id == screen.id {
                manager.screens[idx].items.append(screen.items[(screen.items.count - 1)])
                updateItemsWithChanges(screen: selectedScreen)
                print("\tAdd Succeded!!")
                return
            }
        }
        print("\tAdd Failed")
    }
    
    func updateFullArrayWithChanges(screen: Screen) {
        for idx in manager.screens.indices {
            if manager.screens[idx].id == screen.id {
                manager.screens[idx].items = screen.items
                manager.screens[idx].images = screen.images
                //print("\tUpdate Succeded!!")
            }
        }
        //updateItemsWithChanges(screen: screen)
        /*
        for idx in manager.screens.indices {
            manager.createFirebaseTemplate(index: idx)
        }
         */
    }
    
    // The reason for this function is to line up the UI info with info we going to send to firebase. Cause at this point they are two different "Locations" that hold info. now its more than likely messing up during the looping part or the info is messed up before the looping. Gotta check both.(info sent to this function is not right)
    func updateItemsWithChanges(screen: Screen) {
        for idx in manager.screens.indices {
            if manager.screens[idx].id == screen.id {
                manager.screens[idx].items = screen.items
                manager.screens[idx].images = screen.images
            }
        }
        print("Current Screens: \(manager.screens)")
        //update firebase with changes
        manager.createFirebaseTemplate()
        print("\tUpdate Succeded!!")
        return
    }
}

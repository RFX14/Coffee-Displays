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
    @State private var didUpdateImages = false
    
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
    //Still need to work on changing the positions for items and images. Its really close, however its not saving to firebase properly. Ok so new Issue since we call the same function for creating a template which will be used to update firebase images it ends up creating new images constantly b/c dont have any way to tell if only text or images have been messed with. Need a Bool to determine  when an image has been modified, if it has not been modified then we simply create template with the new text....(that should reduce the amount of images be uploaded to firebase)
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
                            // Action to perform when the button is tapped
                            updateItemsWithChanges(screen: selectedScreen)
                        }) {
                            Text("Submit Changes")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .onChange(of: croppedImage) { newImage in
                            if let newImage = newImage {
                                // Call uploadImage which will return a new link.
                                manager.uploadImage(newImage: newImage) { imagePath in
                                    // Update the imageLink Dictionary.
                                    manager.imageLink[selectedScreen.images[selectedImageIdx].image!] = imagePath
                                    // Update the image at the selected index.
                                    selectedScreen.images[selectedImageIdx].image = newImage
                                    selectedScreen.images[selectedImageIdx].link = imagePath
                                    didUpdateImages = true
                                    self.croppedImage = nil
                                }
                            }
                        }
                    }.onAppear {
                        //print("selectScreen, \(selectedScreen)")
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
    
    func updateItemsWithChanges(screen: Screen) {
        if didUpdateImages == true {
            for idx in manager.screens.indices {
                if manager.screens[idx].id == screen.id {
                    manager.screens[idx].items[selectedItemIdx] = screen.items[selectedItemIdx]
                    manager.screens[idx].images[selectedImageIdx] = screen.images[selectedImageIdx]
                    //update firebase with changes
                    manager.createFirebaseTemplate(index: idx)
                    print("\tUpdate Succeded!!")
                    return
                }
            }
        } else {
            for idx in manager.screens.indices {
                if manager.screens[idx].id == screen.id {
                    manager.screens[idx].items[selectedItemIdx] = screen.items[selectedItemIdx]
                    manager.screens[idx].images[selectedImageIdx] = screen.images[selectedImageIdx]
                    //update firebase with changes
                    manager.createFirebaseTemplateTextOnly(index: idx)
                    print("\tText Updated!!")
                    return
                }
            }
        }
        
        didUpdateImages = false
        print("\tUpdate Failed")
    }
}

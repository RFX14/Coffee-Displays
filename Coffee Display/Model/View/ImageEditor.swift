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
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack {
                    List {
                        // TODO: FIX THE FORCE UNWRAPPING
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
                        }
                    }.onAppear {
                        print("View Appearing!")
                        print("\t\(selectedScreen.items.first?.title)")
                        oldItems = selectedScreen.items
                        print("\tOld Items Stored")
                    }.onDisappear {
                        print("View Disappearing!")
                        selectedScreen.items = oldItems
                        updateFullArrayWithChanges(screen: selectedScreen)
                        print("\t\(selectedScreen.items.first?.title)")
                        print("\t\(oldItems.first?.title)")
                        print("\tItems Reset")
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
                            updateItemsWithChanges(screen: selectedScreen)
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
                location = .init(x: geo.size.height / 2, y: geo.size.width / 2)
            }
        }
    }
    
    func move(from source: IndexSet, to destination: Int) {
        selectedScreen.items.move(fromOffsets: source, toOffset: destination)
        updatePositionIndexes()
    }
    
    func updatePositionIndexes() {
        for i in 0..<selectedScreen.items.count {
            selectedScreen.items[i].position = i
        }
        
        selectedScreen.items.sort(by: {$0.position < $1.position})
    }
    
    func addItemsToScreen(screen: Screen) {
        for idx in manager.screens.indices {
            //checks that the current screen is the only one that is updated with the new item.
            if manager.screens[idx].id == screen.id {
                manager.screens[idx].items.append(screen.items[(screen.items.count - 1)])
                manager.createNewItemTemplate(index: idx)
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
                
                print("\tUpdate Succeded!!")
                return
            }
        }
        
        print("\tUpdate Failed")
    }
    
    func updateItemsWithChanges(screen: Screen) {
        for idx in manager.screens.indices {
            if manager.screens[idx].id == screen.id {
                manager.screens[idx].items[selectedItemIdx] = screen.items[selectedItemIdx]
                //update firebase with changes
                manager.createNewItemTemplate(index: idx)
                print("\tUpdate Succeded!!")
                return
            }
        }
        
        print("\tUpdate Failed")
    }

}
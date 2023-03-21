//
//  Screens.swift
//  Coffee Display
//
//  Created by Brian Rosales on 3/20/23.
//

import SwiftUI

struct Screens: View {
    @StateObject var manager: ScreenManager
    //@State var screens: [String: [ItemData]] = [:]
    @State var screenNames: [String] = []
    @State var selectedScreen: String?
    
    var body: some View {
        NavigationSplitView {
            List(manager.items, id: \.self, selection: $selectedScreen) { screen in
                Text(screen.title)
            }
        } detail: {
            Text("hi")
        }
        .onAppear {
            manager.fetchItems()
            print(manager.items)
            
        }
    }
}

struct Screens_Previews: PreviewProvider {
    static var previews: some View {
        Screens(manager: ScreenManager())
    }
}

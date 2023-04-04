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
            manager.fetchAvailableScreens {
                manager.screens.sort(by: {$0.name < $1.name})
            }
        }
    }
}

struct Screens_Previews: PreviewProvider {
    static var previews: some View {
        Screens(manager: ScreenManager())
    }
}

//
//  Screens.swift
//  Coffee Display
//
//  Created by Brian Rosales on 3/20/23.
//

import SwiftUI

struct Screens: View {
    @StateObject var manager: ScreenManager
    @State var screens: [String: [ItemData]] = [:]
    var body: some View {
        NavigationSplitView {
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        } detail: {
            Text("hi")
        }
        .task {
            self.screens = await manager.fetchCurrentScreensInfo()
        }
    }
}

struct Screens_Previews: PreviewProvider {
    static var previews: some View {
        Screens(manager: ScreenManager())
    }
}

//
//  test.swift
//  Coffee Display
//
//  Created by Brian Rosales on 4/23/23.
//

import SwiftUI

struct test: View {
    @StateObject var manager: TestManager
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            .onAppear {
                manager.fetchLinks()
            }
    }
}


struct test_Previews: PreviewProvider {
    static var previews: some View {
        test(manager: TestManager())
    }
}

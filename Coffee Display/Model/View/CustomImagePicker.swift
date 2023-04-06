//
//  CustomImagePicker.swift
//  Coffee Display
//
//  Created by Brian Rosales on 4/6/23.
//

import SwiftUI
import PhotosUI
extension View {
    @ViewBuilder
    func cropImagePicker(options: [Crop], show: Binding<Bool>, croppedImage: Binding<UIImage?>) -> some View {
        CustomImagePicker(options: options, show: show, croppedImage: croppedImage) {
            self
        }
    }
}

fileprivate struct CustomImagePicker<Content: View>: View {
    var content: Content
    var options: [Crop]
    @Binding var show: Bool
    @Binding var croppedImage: UIImage?
    init(options: [Crop], show: Binding<Bool>, croppedImage: Binding<UIImage?>,@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
        self._show = show
        self._croppedImage = croppedImage
        self.options = options
    }
    
    @State private var photosItem: PhotosPickerItem?
    var body: some View {
        content
            .photosPicker(isPresented: $show, selection: $photosItem)
    }
}


 struct CustomImagePicker_Previews: PreviewProvider {
     static var previews: some View {
         ImageEditor(manager: ScreenManager(), selectedScreen: Screen(name: "screen_1", items:[Coffee_Display.BasicItem(title: "item 1", price: "$1300", description: Optional("blah"), position: 0), Coffee_Display.BasicItem(title: "Churro", price: "$1000", description: Optional("Sugar"), position: 1)]))
     }
 }


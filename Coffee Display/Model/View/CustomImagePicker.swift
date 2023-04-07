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
    // For making is simple and easy to use
    @ViewBuilder
    func frame(_ size: CGSize) -> some View {
        self
            .frame(width: size.width, height: size.height)
    }
    
    //Haptic Feedback
    func haptics(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
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
    
    // View Properties
    @State private var photosItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showDialog: Bool = false
    @State private var selectedCropType: Crop = .circle
    @State private var showCropView: Bool = false
    
    var body: some View {
        content
            .photosPicker(isPresented: $show, selection: $photosItem)
            .onChange(of: photosItem) { newValue in
                //Extracting Image
                if let newValue {
                    Task {
                        if let imageData = try? await newValue.loadTransferable(type: Data.self), let image = UIImage(data: imageData) {
                            // UI Must be updated on Main Thread.
                            await MainActor.run(body: {
                                selectedImage = image
                                showDialog.toggle()
                            })
                        }
                    }
                }
            }
            .confirmationDialog("", isPresented: $showDialog) {
                //Display All the options
                ForEach(options.indices, id: \.self) {index in
                    Button(options[index].name()) {
                        selectedCropType = options[index]
                        showCropView.toggle()
                    }
                }
            }
            .fullScreenCover(isPresented: $showCropView) {
            //Whenever the sheet is closed, set selectedImage to Null
                selectedImage = nil
            } content: {
                CropView(crop: selectedCropType, image: selectedImage) { croppedImage, status in
                    if let croppedImage {
                        self.croppedImage = croppedImage
                    }
                }
            }
    }
}

struct CropView: View {
    var crop: Crop
    var image: UIImage?
    // This callback will give the cropped image and result status when the checkmark button is pressed
    var onCrop: (UIImage?, Bool) ->()
    
    //View Properties
    @Environment(\.dismiss) private var dismiss
    //Gesture Properties
    @State private var scale: CGFloat = 1
    @State private var lastscale: CGFloat = 0
    @State private var offset: CGSize = .zero
    @State private var lastStoredOffset: CGSize = .zero
    //Indicates whether or not the gesture is in interaction
    @GestureState private var isInteracting: Bool = false
    var body: some View {
        NavigationStack {
            ImageView()
                .navigationTitle("Crop View")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(Color.black, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    Color.black
                        .ignoresSafeArea()
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            //Converting View to Image(Native iOS 16+)
                            let renderer = ImageRenderer(content: ImageView(hideGrids: true))
                            renderer.proposedSize = .init(crop.size())
                            if let image = renderer.uiImage {
                                onCrop(image, true)
                            } else {
                                onCrop(nil, false)
                            }
                            dismiss()
                        } label: {
                            Image(systemName: "checkmark")
                                .font(.callout)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                         dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.callout)
                                .fontWeight(.semibold)
                        }
                    }
                }
        }
    }
    // Image View
    @ViewBuilder
    func ImageView(hideGrids: Bool = false) -> some View {
        let cropSize = crop.size()
        GeometryReader {
            let size = $0.size
            
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .overlay(content: {
                        GeometryReader { proxy in
                            let rect = proxy.frame(in: .named("CROPVIEW"))
                            
                            // Since Overlay was used before the .frame(), it will give the image natural size, thus helping us find its edges(left, right, top and bottom)
                            //CoordinateSpace ensures that it will calculate its rect. from the given view and not from the global view.
                            Color.clear
                                .onChange(of: isInteracting) { newValue in
                                    // True = Dragging
                                    // False = Stopped Dragging
                                    // With the help of GeometryReader we can now read the minX, Y and maxX, Y of the Image
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        if rect.minX > 0 {
                                            //Resetting to Last Location
                                            offset.width = (offset.width - rect.minX)
                                            haptics(.medium)
                                        }
                                        if rect.minY > 0 {
                                            //Resetting to Last Location
                                            offset.height = (offset.height - rect.minY)
                                            haptics(.medium)
                                        }
                                        
                                        // Doing the Same for maxX, Y
                                        if rect.maxX < size.width {
                                            //Resetting to Last Location
                                            offset.width = (rect.minX - offset.width)
                                            haptics(.medium)
                                        }
                                        if rect.maxY < size.height {
                                            //Resetting to Last Location
                                            offset.height = (rect.minY - offset.height)
                                            haptics(.medium)
                                        }
                                        
                                    }
                                        
                                    if !newValue {
                                        lastStoredOffset = offset
                                    }
                                }
                            
                        }
                    })
                    .frame(size)
                    // Notice we dont use onEnded(). This is b/c onEnd does on always call
            }
        }
        .scaleEffect(scale)
        .offset(offset)
        .overlay(content: {
            //So if hideGrids = false then we show grid
            if !hideGrids {
                Grids()
            }
        })
        .coordinateSpace(name: "CROPVIEW")
        .gesture(
            DragGesture()
                .updating($isInteracting, body: { _, out, _ in
                    out = true
                }).onChanged({ value in
                    let translation = value.translation
                    offset = CGSize(width: translation.width + lastStoredOffset.width, height: translation.height + lastStoredOffset.height)
                })
        )
        .gesture(
            MagnificationGesture()
                .updating($isInteracting, body: { _, out, _ in
                        out = true
                }).onChanged({ value in
                    let updatedScale = value + lastscale
                    // Limiting beyond 1
                    scale = (updatedScale < 1 ? 1: updatedScale)
                }).onEnded({ value in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if scale < 1 {
                            scale = 1
                            lastscale = 0
                        } else {
                            lastscale = scale - 1
                        }
                    }
                })
        )
        .frame(cropSize)
        .cornerRadius(crop == .circle ? cropSize.height / 2 : 0)
    }
    
    @ViewBuilder
    func Grids() -> some View {
        ZStack {
            HStack {
                ForEach(1...5, id: \.self) { _ in
                    Rectangle()
                        .fill(.white.opacity(0.7))
                        .frame(width: 1)
                        .frame(maxWidth: .infinity)
                }
            }
            VStack {
                ForEach(1...8, id: \.self) { _ in
                    Rectangle()
                        .fill(.white.opacity(0.7))
                        .frame(height: 1)
                        .frame(maxHeight: .infinity)
                    
                }
            }
        }
    }
}

struct CustomImagePicker_Previews: PreviewProvider {
    static var previews: some View {
        CropView(crop: .circle, image: UIImage(named: "Sample Pic")) { _, _ in
            
        }
    }
    /*
    ImageEditor(manager: ScreenManager(), selectedScreen: Screen(name: "screen_1", items:[Coffee_Display.BasicItem(title: "item 1", price: "$1300", description: Optional("blah"), position: 0), Coffee_Display.BasicItem(title: "Churro", price: "$1000", description: Optional("Sugar"), position: 1)]))
     */
}


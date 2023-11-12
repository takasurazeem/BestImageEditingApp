//
//  ContentView.swift
//  BestImageEditingApp
//
//  Created by Takasur Azeem on 28/10/2023.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import PhotosUI
import CoreTransferable

@available(iOS 16.0, *)
struct MultipleSelectView: View {
    let context = CIContext()
    
    @State var images: [UIImage] = []
    @State var invertedImages: [UIImage] = []
    @State private var showInvertedImages = false
    @State var selectedItems: [PhotosPickerItem] = []
    
    @State private var currentZoom = 0.0
    @State private var totalZoom = 1.0
    
    @State private var showingSavedAlert = false
    @State private var imagesFailedToSave = false
    @State private var errorMessage = "Failed to save images. You need to grant the app access to store images. To do this, open the Settings app on your device, scroll down to Invert, and enable access to Photos or just tap the open App Settings Button. Allowing full access will enable the app to store and manage images, providing you with a better experience."
    
    var body: some View {
        
        List {
            Section {
                TabView {
                    ForEach(
                        showInvertedImages ? invertedImages : images, id: \.self
                    ){ image in
                        GeometryReader { proxy in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                            //                                .frame(width: proxy.size.width, height: proxy.size.height)
                                .clipShape(Rectangle())
                                .modifier(ImageModifier(contentSize: CGSize(width: proxy.size.width, height: proxy.size.height)))
                                .accessibilityZoomAction { action in
                                    if action.direction == .zoomIn {
                                        totalZoom += 1
                                    } else {
                                        totalZoom -= 1
                                    }
                                }
                        }
                    }
                } //: Tabview
                .tabViewStyle(PageTabViewStyle())
                .frame(height: 470)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
            Section {
                PhotosPicker(
                    selection: $selectedItems,
                    matching: .images
                ) {
                    Text("Select Photos")
                }
                .onChange(of: selectedItems) { selectedItems in
                    images = []
                    invertedImages = []
                    for item in selectedItems {
                        item.loadTransferable(type: Data.self) { result in
                            switch result {
                            case .success(let imageData):
                                if let imageData {
                                    self.images.append(UIImage(data: imageData)!)
                                } else {
                                    print("No supported content type found.")
                                }
                            case .failure(let error):
                                print(error)
                            }
                        }
                    }
                }
                
                Button {
                    invertImages()
                } label: {
                    Text("Invert Colour")
                }
                .disabled(images.isEmpty)
            }
            Section {
                Button {
                    saveImages()
                } label: {
                    Text("Save")
                }
            }
            .disabled(invertedImages.isEmpty)
            .alert(isPresented: $showingSavedAlert) {
                Alert(
                    title: Text("Images saved"),
                    message: Text("Thank you for using the app."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert(isPresented: $imagesFailedToSave) {
                Alert(
                    title: Text("Images failed to save"),
                    message: Text(errorMessage),
                    primaryButton: .default(
                        Text("Ok"), action: {
                            imagesFailedToSave = false
                        }
                    ),
                    secondaryButton: .default(
                        Text("Open app settings."),
                        action: {
                            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
                                return
                            }
                            
                            UIApplication.shared.open(settingsURL)
                        }))
            }
        }
    }
    
    func saveImages() {
        // Request photo library access
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            if status == .authorized {
                // Save the new images
                for (index, image) in invertedImages.enumerated() {
                    PHPhotoLibrary.shared().performChanges {
                        PHAssetChangeRequest.creationRequestForAsset(from: image)
                    } completionHandler: { success, error in
                        if success {
                            // Do nothing
                        } else if let error = error {
                            errorMessage = error.localizedDescription
                            imagesFailedToSave = true
                        }
                    }
                    if index == invertedImages.count - 1 {
                        DispatchQueue.main.async {
                            images = []
                            invertedImages = []
                            self.showingSavedAlert = true
                        }
                    }
                }
            } else {
                imagesFailedToSave = true
            }
        }
    }
    
    func invertImages() {
        invertedImages = []
        let dispatchGroup = DispatchGroup()
        let currentFilter: CIFilter = .colorInvert()
        for (_, image) in images.enumerated() {
            dispatchGroup.enter()
            DispatchQueue.global().async {
                let beginImage = CIImage(image: image)
                currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
                guard let outputImage = currentFilter.outputImage else { return }
                if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                    let uiImage = UIImage(cgImage: cgimg)
                    DispatchQueue.main.async {
                        invertedImages.append(uiImage)
                        dispatchGroup.leave()
                    }
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            showInvertedImages = true
        }
    }
}

@available(iOS 16.0, *)
#Preview {
    MultipleSelectView()
}

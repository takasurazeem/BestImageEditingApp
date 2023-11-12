//
//  ContentView.swift
//  BestImageEditingApp
//
//  Created by Takasur Azeem on 28/10/2023.
//

import SwiftUI

import SwiftUI
import PhotosUI
import CoreTransferable

@available(iOS 16.0, *)
struct MultipleSelectView: View {
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
                    ForEach(showInvertedImages ? invertedImages : images, id:\.self){ image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .scaleEffect(currentZoom + totalZoom)
                            .gesture(
                                MagnifyGesture()
                                    .onChanged { value in
                                        currentZoom = value.magnification - 1
                                    }
                                    .onEnded { value in
                                        totalZoom += currentZoom
                                        currentZoom = 0
                                    }
                            )
                            .accessibilityZoomAction { action in
                                if action.direction == .zoomIn {
                                    totalZoom += 1
                                } else {
                                    totalZoom -= 1
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
                    Text("Pick Photo")
                }
                .onChange(of: selectedItems) {
                    images = []
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
                    saveAndDeleteImages()
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
    func saveAndDeleteImages() {
        // Request photo library access
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            if status == .authorized {
                // Save the new images
                for image in invertedImages {
                    PHPhotoLibrary.shared().performChanges {
                        PHAssetChangeRequest.creationRequestForAsset(from: image)
                    } completionHandler: { success, error in
                        if success {
                            showingSavedAlert = true
                        } else if let error = error {
                            errorMessage = error.localizedDescription
                            imagesFailedToSave = true
                        }
                    }
                }
                
                // TODO: Fix later.
                //                        // Delete the previously selected images
                //                        for item in selectedItems {
                //                            guard let asset = item.photoAsset else {
                //                                print("Unable to get PHAsset from selected item.")
                //                                continue
                //                            }
                //
                //                            PHPhotoLibrary.shared().performChanges {
                //                                PHAssetChangeRequest.deleteAssets([asset] as NSArray)
                //                            } completionHandler: { success, error in
                //                                if success {
                //                                    print("Image deleted successfully.")
                //                                } else if let error = error {
                //                                    print("Error deleting image: \(error.localizedDescription)")
                //                                }
                //                            }
                //                        }
            } else {
                imagesFailedToSave = true
            }
        }
    }
    func invertImages() {
        invertedImages = []
        let dispatchGroup = DispatchGroup()

        for (_, image) in images.enumerated() {
            dispatchGroup.enter()
            
            DispatchQueue.global().async {
                if let ciImage = CIImage(image: image) {
                    let filter = CIFilter(name: "CIColorControls")
                    filter?.setValue(ciImage, forKey: kCIInputImageKey)
                    filter?.setValue(1.0, forKey: kCIInputContrastKey)
                    filter?.setValue(0.0, forKey: kCIInputBrightnessKey)
                    filter?.setValue(-1.0, forKey: kCIInputSaturationKey)
                    
                    if let outputImage = filter?.outputImage {
                        let context = CIContext()
                        if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                            let uiImage = UIImage(cgImage: cgImage)
                            DispatchQueue.main.async {
                                invertedImages.append(uiImage)
                                dispatchGroup.leave()
                            }
                        }
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
        .previewLayout(.fixed(width: 400, height: 300))
}

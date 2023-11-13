//
//  ViewModel.swift
//  BestImageEditingApp
//
//  Created by Takasur Azeem on 13/11/2023.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import PhotosUI
import CoreTransferable

extension InvertImageView {
    @MainActor class ViewModel: ObservableObject {
        
        func invertImages() {
            invertedImages = []
            let dispatchGroup = DispatchGroup()
            let currentFilter: CIFilter = .colorInvert()
            for (_, image) in images.enumerated() {
                dispatchGroup.enter()
                DispatchQueue.global().async { [weak self] in
                    guard let self else { return }
                    let beginImage = CIImage(image: image)
                    currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
                    guard let outputImage = currentFilter.outputImage else { return }
                    if let cgimg = self.context.createCGImage(outputImage, from: outputImage.extent) {
                        let uiImage = UIImage(cgImage: cgimg)
                        DispatchQueue.main.async {
                            self.invertedImages.append(uiImage)
                            dispatchGroup.leave()
                        }
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) { [weak self] in
                guard let self else { return }
                self.showInvertedImages = true
            }
        }
        
        func saveImages() {
            // Request photo library access
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
                guard let self else { return }
                if status == .authorized {
                    // Save the new images
                    for (index, image) in self.invertedImages.enumerated() {
                        PHPhotoLibrary.shared().performChanges {
                            PHAssetChangeRequest.creationRequestForAsset(from: image)
                        } completionHandler: { success, error in
                            if success {
                                // Do nothing
                            } else if let error = error {
                                self.errorMessage = error.localizedDescription
                                self.imagesFailedToSave = true
                            }
                        }
                        if index == invertedImages.count - 1 {
                            DispatchQueue.main.async {
                                self.images = []
                                self.invertedImages = []
                                self.showingSavedAlert = true
                            }
                        }
                    }
                } else {
                    self.imagesFailedToSave = true
                }
            }
        }
        
        func updateSelection(
            with selectedItems: [PhotosPickerItem]
        ) {
            images = []
            invertedImages = []
            showInvertedImages = false
            for item in selectedItems {
                item.loadTransferable(type: Data.self) { [weak self] result in
                    guard let self else { return }
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let imageData):
                            if let imageData, let uiImage = UIImage(data: imageData) {
                                self.images.append(uiImage)
                            } else {
                                print("No supported content type found.")
                            }
                        case .failure(let error):
                            print(error)
                        }
                    }
                }
            }
        }
        
        let context = CIContext()
        
        @Published var images: [UIImage] = []
        @Published var invertedImages: [UIImage] = []
        @Published var showInvertedImages = false
        @Published var selectedItems: [PhotosPickerItem] = []
        
        @Published var currentZoom = 0.0
        @Published var totalZoom = 1.0
        
        @Published var showingSavedAlert = false
        @Published var imagesFailedToSave = false
        @Published var errorMessage = "Failed to save images. You need to grant the app access to store images. To do this, open the Settings app on your device, scroll down to Invert, and enable access to Photos or just tap the open App Settings Button. Allowing full access will enable the app to store and manage images, providing you with a better experience."
    } // ViewModel
}

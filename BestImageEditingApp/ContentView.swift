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
            }
            Section {
                Button {
                    // TODO: Save
                } label: {
                    Text("Save")
                }
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

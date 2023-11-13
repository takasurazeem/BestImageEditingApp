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
struct InvertImageView: View {
    @StateObject var viewModel: ViewModel
    
    var body: some View {
        
        List {
            Section {
                TabView {
                    ForEach(
                        viewModel.showInvertedImages ? viewModel.invertedImages : viewModel.images, id: \.self
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
                                        viewModel.totalZoom += 1
                                    } else {
                                        viewModel.totalZoom -= 1
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
                    selection: $viewModel.selectedItems,
                    matching: .images
                ) {
                    Text("Select Photos")
                }
                .onChange(of: viewModel.selectedItems) { selectedItems in
                    viewModel.updateSelection(with: selectedItems)
                }
                
                Button {
                    viewModel.invertImages()
                } label: {
                    Text("Invert Colour")
                }
                .disabled(viewModel.images.isEmpty)
            }
            Section {
                Button {
                    viewModel.saveImages()
                } label: {
                    Text("Save")
                }
            }
            .disabled(viewModel.invertedImages.isEmpty)
            .alert(isPresented: $viewModel.showingSavedAlert) {
                Alert(
                    title: Text("Images saved"),
                    message: Text("Thank you for using the app."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert(isPresented: $viewModel.imagesFailedToSave) {
                Alert(
                    title: Text("Images failed to save"),
                    message: Text(viewModel.errorMessage),
                    primaryButton: .default(
                        Text("Ok"), action: {
                            viewModel.imagesFailedToSave = false
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
}

@available(iOS 16.0, *)
#Preview {
    InvertImageView(
        viewModel: InvertImageView.ViewModel()
    )
}

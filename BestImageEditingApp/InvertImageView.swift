//
//  ContentView.swift
//  BestImageEditingApp
//
//  Created by Takasur Azeem on 28/10/2023.
//

import SwiftUI
import PhotosUI

@available(iOS 16.0, *)
struct InvertImageView: View {
    @StateObject var viewModel: ViewModel
    
    var body: some View {
        
        List {
            Section {
                TabView {
                    ForEach(
                        viewModel.showInvertedImages ? viewModel.invertedImages.indices : viewModel.images.indices, id: \.self
                    ) { index in
                        let image = viewModel.showInvertedImages ? viewModel.invertedImages[index] : viewModel.images[index]
                        GeometryReader { proxy in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
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
                        .background {
                            Image(uiImage: viewModel.images[index])
                                .resizable()
                                .scaledToFill()
                                .blur(radius: 3)
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
            .overlay {
                EmptyView()
                    .alert(isPresented: $viewModel.showingSavedAlert) {
                        Alert(
                            title: Text("Images saved"),
                            message: Text("Thank you for using the app."),
                            dismissButton: .default(Text("OK"))
                        )
                    }
            }
            .disabled(viewModel.invertedImages.isEmpty)
            .overlay {
                EmptyView()
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
}

@available(iOS 16.0, *)
#Preview {
    InvertImageView(
        viewModel: InvertImageView.ViewModel()
    )
}

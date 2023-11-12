//
//  Playground.swift
//  BestImageEditingApp
//
//  Created by Takasur Azeem on 13/11/2023.
//

import SwiftUI

struct Playground: View {
    var body: some View {
        Image("fund-example")
            .resizable()
            .scaledToFill()
            .colorInvert()
    }
}

#Preview {
    Playground()
}

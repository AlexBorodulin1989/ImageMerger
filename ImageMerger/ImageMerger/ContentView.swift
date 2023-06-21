//
//  ContentView.swift
//  ImageMerger
//
//  Created by Aleksandr Borodulin on 19.06.2023.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel: ContentViewModel

    var body: some View {
        VStack {
            if let img = viewModel.image {
                Image(img,
                      scale: 1.0,
                      label: Text("Merged image"))
                .resizable()
            } else {
                Text("Merging...")
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: .init())
    }
}

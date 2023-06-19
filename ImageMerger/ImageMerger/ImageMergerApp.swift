//
//  ImageMergerApp.swift
//  ImageMerger
//
//  Created by Aleksandr Borodulin on 19.06.2023.
//

import SwiftUI

@main
struct ImageMergerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: .init())
        }
    }
}

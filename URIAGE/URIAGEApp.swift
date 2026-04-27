//
//  URIAGEApp.swift
//  URIAGE
//
//  Created by zlf on 2026/04/26.
//

import SwiftUI
import SwiftData

@main
struct URIAGEApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [SoldItem.self, SupplyItem.self])
    }
}

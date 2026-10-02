//
//  ECommerceSwiftUIDemoApp.swift
//  ECommerceSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import SwiftUI

@main
struct ECommerceSwiftUIDemoApp: App {
    @State private var deps = AppDependencies()

    var body: some Scene {
        WindowGroup {
            RootView(deps: deps)
        }
    }
}

//
//  inventappApp.swift
//  inventapp
//
//  Created by Iván Alejandro on 23-11-26.
//

import SwiftData
import SwiftUI

@main
struct inventappApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // Conectamos la base de datos local SwiftData a toda la jerarquía de vistas.
        .modelContainer(for: [
            Equipment.self,
            Employee.self,
            AssignmentRecord.self
        ])
    }
}

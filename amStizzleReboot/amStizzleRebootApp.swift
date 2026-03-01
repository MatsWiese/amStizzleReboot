//
//  amStizzleRebootApp.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 16.12.25.
//

import Dependencies
import SwiftUI

@main
struct amStizzleRebootApp: App {
  init () {
    prepareDependencies {
      try! $0.bootstrapDatabase()
    }
  }
    var body: some Scene {
      WindowGroup {
        NavigationStack {
          EventsListView()
        }
      }
    }
}

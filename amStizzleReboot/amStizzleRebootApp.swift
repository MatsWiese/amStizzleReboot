//
//  amStizzleRebootApp.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 16.12.25.
//

import Auth
import Dependencies
import SwiftUI
import Supabase

extension EnvironmentValues {
  @Entry var appState: AppState = AppState()
}

@Observable
final class AppState {
  enum State {
    case login
    case authenticated
  }
  var state: State = .login
  
  init() {
    Task { @MainActor in
      for await sessionState in Supabase.shared.auth.authStateChanges {
        if [.initialSession, .signedIn, .signedOut].contains(sessionState.event) {
          if sessionState.session == nil {
            self.state = .login
          } else {
            self.state = .authenticated
          }
        }
      }
    }
  }
}

@main
struct amStizzleRebootApp: App {
  @Environment(\.appState) var appState
//  init () {
//    prepareDependencies {
//      try! $0.bootstrapDatabase()
//    }
//  }
    var body: some Scene {
      WindowGroup {
        switch appState.state {
          case .login:
          LogInView()
          case .authenticated:
          EventsListView()
        }
      }
    }
}

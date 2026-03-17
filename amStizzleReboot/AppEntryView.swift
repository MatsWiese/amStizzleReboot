////
////  AppEntryView.swift
////  amStizzleReboot
////
////  Created by Fred Erik on 13.03.26.
////
//
//import SwiftUI
//import Supabase
//
//struct AppEntryView: View {
//  @State var isAuthenticated = false
//  
//    var body: some View {
//      Group {
//        if isAuthenticated {
//          EventsListView()
//        } else {
//          LogInView()
//        }
//      }
//      .task {
//        for await state in Supabase.shared.auth.authStateChanges {
//          if [.initialSession, .signedIn, .signedOut].contains(state.event) {
//            isAuthenticated = state.session != nil
//          }
//        }
//      }
//    }
//  }
//
//#Preview {
//    AppEntryView()
//}

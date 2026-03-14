//
//  AppEntryView.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 13.03.26.
//

import SwiftUI
import Supabase

struct AppEntryView: View {
  let supabase = SupabaseClient(
    supabaseURL:
      URL(string: "https://urexdmyfiqtievtbpcnx.supabase.co")!,
    supabaseKey: "sb_publishable_BIfX14NlCjhsyjoVJBg2Ag_RcP_IkFY"
  )
  
  @State var isAuthenticated = false
  
    var body: some View {
      Group {
        if isAuthenticated {
          EventsListView()
        } else {
          LogInView()
        }
      }
      .task {
        for await state in supabase.auth.authStateChanges {
          if [.initialSession, .signedIn, .signedOut].contains(state.event) {
            isAuthenticated = state.session != nil
          }
        }
      }
    }
  }

#Preview {
    AppEntryView()
}

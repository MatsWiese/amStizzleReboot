//
//  AccountView.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 13.03.26.
//

import SwiftUI
import Supabase

struct AccountView: View {
  @State var firstName = ""
  @State var lastName = ""
  @State var username = ""

  @State var isLoading = false

  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextField("First name", text: $firstName)
          TextField("Last name", text: $lastName)
          TextField("Username", text: $username)
            .textContentType(.username)
            .textInputAutocapitalization(.never)
        }
        .textContentType(.name)

        Section {
          Button("Update profile") {
            updateProfileButtonTapped()
          }
          .bold()

          if isLoading {
            ProgressView()
          }
        }
      }
      .navigationTitle("Profile")
      .toolbar(content: {
        ToolbarItem(placement: .topBarLeading){
          Button("Sign out", role: .destructive) {
            Task {
              try? await Supabase.shared.auth.signOut()
            }
          }
        }
      })
    }
    .task {
      await getInitialProfile()
    }
  }

  func getInitialProfile() async {
    do {
      let currentUser = try await Supabase.shared.auth.session.user

      let profile: Profile =
      try await Supabase.shared
        .from("profiles")
        .select()
        .eq("id", value: currentUser.id)
        .single()
        .execute()
        .value

      self.firstName = profile.firstName ?? ""
      self.lastName = profile.lastName ?? ""
      self.username = profile.username ?? ""

    } catch {
      debugPrint(error)
    }
  }

  func updateProfileButtonTapped() {
    Task {
      isLoading = true
      defer { isLoading = false }
      do {
        let currentUser = try await Supabase.shared.auth.session.user

        try await Supabase.shared
          .from("profiles")
          .update(
            UpdateProfileParams(
              firstName: firstName,
              lastName: lastName,
              username: username,
              avatarURL: ""
            )
          )
          .eq("id", value: currentUser.id)
          .execute()
      } catch {
        debugPrint(error)
      }
    }
  }
}

#Preview {
    AccountView()
}

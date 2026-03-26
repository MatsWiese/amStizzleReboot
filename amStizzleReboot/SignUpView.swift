//
//  LogInView.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 12.03.26.
//

import Auth
import os
import Supabase
import SwiftUI

struct SignUpView: View {
  @Environment(\.appState) private var appState
  
  let logger = Logger(subsystem: "amStizzleReboot", category: "SignUpView")
  
  @State private var email: String = ""
  @State private var password: String = ""
  @State private var username: String = ""
  @State var isLoading = false
  @State var result: Result<Void, Error>?
  
  var body: some View {
    VStack {
      Text("Please enter a valid email and a password")
      TextField("eMail", text: $email)
        .textContentType(.emailAddress)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .textFieldStyle(.roundedBorder)
      SecureField("Password", text: $password)
        .textFieldStyle(.roundedBorder)
        .padding(.bottom, 30)
      Text("How do you want to be called in this app?")
      TextField("userName", text: $username)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .textFieldStyle(.roundedBorder)
        .onSubmit {
          signUpButtonTapped()
        }
        
      if isLoading {
        ProgressView()
      } else {
        Button {
          signUpButtonTapped()
        } label: {
          ZStack {
            RoundedRectangle(cornerRadius: 8)
              .fill(((email.isEmpty || password.isEmpty || username.isEmpty) ? Color.gray.opacity(0.4) : Color.cyan))
            Text("Sign up")
              .fontWeight(.bold)
              .foregroundStyle(.black)
          }
          .frame(height: 50)
        }
        .disabled(email.isEmpty || password.isEmpty || username.isEmpty)
      }
      
      if let result {
        Section {
          if case let .failure(failure) = result {
            Text(failure.localizedDescription).foregroundStyle(.red)
          }
        }
      }
    }
    .padding()
//    .onOpenURL(perform: { url in
//      Task {
//        do {
//          try await Supabase.shared.auth.session(from: url)
//        } catch {
//          self.result = .failure(error)
//        }
//      }
//    })
  }
  
  func signUpButtonTapped() {
    Task {
      isLoading = true
      defer { isLoading = false }
      do {
        try await Supabase.shared.auth.signUp(
          email: email,
          password: password
        )
        let currentUser = try await Supabase.shared.auth.session.user
        
        let newProfile = Profile(id: currentUser.id, firstName: "", lastName: "", username: username, avatarURL: "", createdAt: Date.now, updatedAt: Date.now)
        
        try await Supabase.shared
          .from("profiles")
          .insert(newProfile)
//          .eq("profile_id", value: eventAttendee.profileId)
//          .eq("event_id", value: eventAttendee.eventId )
          .execute()
        
        appState.state = .authenticated
      } catch {
        result = .failure(error)
      }
    }
    logger.info("signedUp new user \(username) with email: \(email)")
  }
}

#Preview {
  LogInView()
}

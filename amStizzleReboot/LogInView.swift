//
//  LogInView.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 12.03.26.
//

import Auth
import Supabase
import SwiftUI

struct LogInView: View {
  @Environment(\.appState) private var appState
  @State private var email: String = ""
  @State private var password: String = ""
  @State var isLoading = false
  @State var result: Result<Void, Error>?
  
  var body: some View {
    VStack {
      Text("Please log into your account.")
      TextField("eMail", text: $email)
        .textContentType(.emailAddress)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .textFieldStyle(.roundedBorder)
      SecureField("Password", text: $password)
        .textFieldStyle(.roundedBorder)
        .onSubmit {
          signInButtonTapped()
        }
        
      if isLoading {
        ProgressView()
      } else {
        Button {
          signInButtonTapped()
        } label: {
          ZStack {
            RoundedRectangle(cornerRadius: 8)
              .fill(.cyan)
//              .stroke(style: StrokeStyle(lineWidth: 1))
            Text("Log in")
              .fontWeight(.bold)
              .foregroundStyle(.black)
          }
          .frame(height: 50)
        }
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
    .onOpenURL(perform: { url in
      Task {
        do {
          try await Supabase.shared.auth.session(from: url)
        } catch {
          self.result = .failure(error)
        }
      }
    })
  }
  
  func signInButtonTapped() {
    Task {
      isLoading = true
      defer { isLoading = false }
      do {
        try await Supabase.shared.auth.signIn(email: email, password: password)
        appState.state = .authenticated
      } catch {
        result = .failure(error)
      }
    }
  }
}

#Preview {
  LogInView()
}

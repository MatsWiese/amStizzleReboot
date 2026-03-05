//
//  DebugChangeUserView.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 02.03.26.
//

import SwiftUI
import SQLiteData

struct DebugChangeUserView: View {
  @Environment(\.dismiss) var dismiss
  @AppStorage("selectedUserID") var selectedUserID: String = ""
  
  @FetchAll
  var users: [User]
  
  var body: some View {
    List {
      ForEach(users) { user in
        Button(action: {
          selectedUserID = user.id.uuidString
          dismiss()
        }) {
          HStack {
            Text(user.firstName)
            Text(user.lastName)
            if user.id.uuidString == selectedUserID {
              Image(systemName: "checkmark")
            }
          }
        }
      }
    }
  }
}

#Preview {
  let users = prepareDependencies {
    try! $0.bootstrapDatabase()
    try! $0.defaultDatabase.seed()
    return try! $0.defaultDatabase.read { db in
      try User.fetchAll(db)
        }
  }
    DebugChangeUserView()
}

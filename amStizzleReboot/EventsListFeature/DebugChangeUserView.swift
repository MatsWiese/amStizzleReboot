//
//  DebugChangeUserView.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 02.03.26.
//

import os
import SwiftUI
import SQLiteData

struct DebugChangeUserView: View {
  @ObservationIgnored @Dependency(\.defaultDatabase) var database
  @Environment(\.dismiss) var dismiss
  let logger = Logger(subsystem: "amStizzleReboot", category: "DebugChangeUserView")
  @AppStorage("selectedUserID") var currentUserIDString: String = ""
  
  @FetchAll
  var users: [User]
  
  @State private var newUserFirstName: String = ""
  @State private var newUserLastName: String = ""
  
  var body: some View {
    List {
      HStack {
        TextField("First name", text: $newUserFirstName)
        TextField("Last name", text: $newUserLastName)
        Button {
          withErrorReporting {
            try database.write { db in
              try User.insert { User.Draft(firstName: newUserFirstName, lastName: newUserLastName)
              }
              .execute(db)
            }
          }
          logger.info(">>>>> new User inserted")
        } label: {
          Image(systemName: "plus.circle.fill")
        }
      }
      ForEach(users) { user in
        Button(action: {
          currentUserIDString = user.id.uuidString
          dismiss()
        }) {
          HStack {
            VStack(alignment: .leading) {
              HStack {
                Text(user.firstName)
                Text(user.lastName)
              }
              Text("\(user.id.uuidString)")
                .font(.caption2)
            }
            Spacer()
            if user.id.uuidString == currentUserIDString {
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

//
//  AttendeeManagerSheet.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 01.03.26.
//
//
import os
import SwiftUI
import SQLiteData

struct AttendeeManagerSheet: View {
  @Dependency(\.defaultDatabase) var database
  let logger = Logger(subsystem: "amStizzleReboot", category: "AttendeeManagerSheet")
//
  @FetchAll(animation: .default)
  var users: [User]
  
  @State var newUserFirstName = ""
  @State var newUserLastName = ""
  
  let event: Event?
  
  @FetchAll
  var eventAttendees: [EventAttendee]
  
  var body: some View {
    List {
      HStack {
        TextField("First Name", text: $newUserFirstName)
        TextField("Last Name", text: $newUserLastName)
          .onSubmit {
            saveNewUser()
          }
        Button {
          saveNewUser()
        } label: {
          Image(systemName: "plus.circle")
        }
      }
      .padding()
      
      Section {
        #if Debug
        if let event {
          Text(event.title)
          Text("eventId: \(event.id)")
            .font(.footnote )
        }
        #endif
        ForEach(users, id: \.id) { user in
          HStack {
            Text(user.firstName)
            Text(user.lastName)
            Spacer()
            if let event {
              if eventAttendees.contains(where: { $0.userId == user.id && $0.eventId == event.id }) {
                Image(systemName: "checkmark")
              }
            }
          }
          .onTapGesture {
            if let event {
              if eventAttendees.contains(where: { $0.userId == user.id }) {
                
                logger.info("%%% user is already registered for the event")
                withErrorReporting {
                  try database.write { db in
                    try EventAttendee
                      .where { $0.userId.eq(user.id)/* && $0.eventId.eq(event.id)*/ }
                      .delete()
                      .execute(db)
                  }
                  logger.info("%%% eventAttendee deleted")
                }
              } else {
                withErrorReporting {
                  try database.write { db in
                    try EventAttendee.insert { EventAttendee.Draft(eventId: event.id, userId: user.id) }
                      .execute(db)
                  }
                }
                logger.info(">>>>> eventAttendee inserted")
              }
            }
          }
        }
      }
    }
    .navigationBarTitle("Manage Users")
  }

  func saveNewUser() {
    withErrorReporting {
      try database.write { db in
        try User.insert { User.Draft(firstName: newUserFirstName, lastName: newUserLastName) }
          .execute(db)
      }
    }
    logger.info(">>>>> new User inserted")
  }
}

#Preview {
  let event = prepareDependencies {
    try! $0.bootstrapDatabase()
    try! $0.defaultDatabase.seed()
    return try! $0.defaultDatabase.read { db in
          try Event.fetchOne(db)!
        }
  }
  NavigationStack {
    AttendeeManagerSheet(event: event)
  }
}

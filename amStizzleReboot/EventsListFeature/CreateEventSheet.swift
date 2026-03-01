//
//  CreateEventSheet.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 26.02.26.
//

import SwiftUI
import SQLiteData

struct CreateEventSheet: View {
  @Dependency(\.defaultDatabase) var database
  @Environment(\.dismiss) var dismiss
  
//  @State var event: Event.Draft
  
  @State var newEventTitle = ""
  @State var eventBegin = Date()
  @State var eventEnd = Date() + 3600
  
  @State var newUserFirstName = ""
  @State var newUserLastName = ""
  
  @FetchAll
  var users: [User]
  
  @State var attendees: [User] = []
  
  var body: some View {
    Form {
      Section {
        TextField("Event title", text: $newEventTitle)
        DatePicker("Event Begin", selection: $eventBegin, displayedComponents: .date)
        DatePicker("Event ends", selection: $eventEnd, displayedComponents: .date)
      }
      
      Section("Add Attendees") {
        HStack {
          TextField("First Name", text: $newUserFirstName)
          TextField("Last Name", text: $newUserLastName)
            .onSubmit {
              withErrorReporting {
                try database.write { db in
                  try User.insert { User.Draft(id: UUID(), firstName: newUserFirstName, lastName: newUserLastName) }
                    .execute(db)
                }
              }
            }
        }
        
        List {
          ForEach(users, id: \.id) { user in
            HStack {
              Text(user.firstName)
              Text(user.lastName)
              if attendees.contains(where: { $0.id == user.id }) {
                Image(systemName: "checkmark")
              }
            }
            .onTapGesture {
              if attendees.contains(where: { $0.id == user.id }) {
                attendees.removeAll(where: { $0.id == user.id })
              } else {
                attendees.append(user)
              }
            }
          }
        }
      }
    }
    .navigationTitle("New Event")
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") { dismiss() }
      }
      ToolbarItem(placement: .confirmationAction) {
        Button("Save") {
          withErrorReporting {
            try database.write { db in
              // with Draft as the usual Point Free Way
              // try Event
              //   .insert { Event.Draft(title: newEventTitle, startDate: eventBegin, endDate: eventEnd)
              //  }
              //  .execute(db)
              // with id to join eventAttendees with event
              try Event.insert { Event(id: UUID(), title: newEventTitle, startDate: eventBegin, endDate: eventEnd)
              }
              .execute(db)
              
            }
          }
          dismiss()
        }
        .disabled(newEventTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
    }
  }
}

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
  
  @State var newEventTitle = ""
  @State var eventBegin = Date()
  @State var eventEnd = Date() + 3600
  
  var body: some View {
    Form {
      Section {
        TextField("Event title", text: $newEventTitle)
        DatePicker("Event Begin", selection: $eventBegin, displayedComponents: .date)
        DatePicker("Event ends", selection: $eventEnd, displayedComponents: .date)
      }
      
//      Button {
      #warning("No event yet to pass on.")
      NavigationLink(destination: AttendeeManagerSheet(event: nil)) {
          Text("Manage Attendees")
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

#Preview {
  let event = prepareDependencies {
    try! $0.bootstrapDatabase()
    try! $0.defaultDatabase.seed()
    return try! $0.defaultDatabase.read { db in
          try Event.fetchOne(db)!
        }
  }
  NavigationStack {
    CreateEventSheet()
  }
}

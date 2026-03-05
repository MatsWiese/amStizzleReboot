//
//  CreateEventSheet.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 26.02.26.
//

import os
import SwiftUI
import SQLiteData

@Observable class CreateEventModel {
  @ObservationIgnored @Dependency(\.defaultDatabase) var database
  let logger = Logger(subsystem: "amStizzleReboot", category: "CreateEventModel")
  
  let event = Event(id: UUID(), title: "", startDate: Date.now, endDate: Date.now + 3600)
  
  var newEventTitle = ""
  var eventBegin = Date()
  var eventEnd = Date() + 3600
  
  func saveEventButtonTapped() {
  withErrorReporting {
    try database.write { db in
      // with Draft as the usual Point Free Way
       try Event
        .upsert { Event(id: event.id, title: newEventTitle, startDate: eventBegin, endDate: eventEnd)
        }
        .execute(db)
      // with id to join eventAttendees with event
//      try Event.insert { Event(id: UUID(), title: newEventTitle, startDate: eventBegin, endDate: eventEnd)
//      }
//      .execute(db)
    }
    }
  }
}

struct CreateEventSheet: View {
  @State var model: CreateEventModel
  init() {
    _model = State(wrappedValue: CreateEventModel())
  }
  
  @Environment(\.dismiss) var dismiss
  
  var body: some View {
    Form {
      Section {
        TextField("Event title", text: $model.newEventTitle)
          .onSubmit {
            model.saveEventButtonTapped()
          }
        DatePicker("Event Begin", selection: $model.eventBegin, displayedComponents: [.date, .hourAndMinute])
        DatePicker("Event ends", selection: $model.eventEnd, displayedComponents: [.date, .hourAndMinute])
      }
    
#warning("Navlink upserts event. not best solution I guess")
    NavigationLink(destination: AttendeeManagerSheet(event: model.event)) {
      Text("Manage Attendees")
    }
    .simultaneousGesture(TapGesture().onEnded {
      model.saveEventButtonTapped()
      print("saved saved saved")
    } )
    .disabled(model.newEventTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
  }
    .navigationTitle("New Event")
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") { dismiss() }
      }
      ToolbarItem(placement: .confirmationAction) {
        Button("Save") {
          model.saveEventButtonTapped()
          dismiss()
        }
        .disabled(model.newEventTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
    }
  }
}

#Preview {
//
  
  NavigationStack {
    CreateEventSheet()
  }
}

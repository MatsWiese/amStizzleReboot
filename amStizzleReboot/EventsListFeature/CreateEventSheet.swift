//
//  CreateEventSheet.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 26.02.26.
//

import os
import SwiftUI
import SQLiteData

private enum Destination {
  case attendeeManager(event: Event)
  
  var view: some View {
    switch self {
    case .attendeeManager(event: let event):
      AttendeeManagerSheet(event: event)
    }
  }
}

extension Destination: Hashable, Equatable {
  static func == (lhs: Destination, rhs: Destination) -> Bool {
    switch (lhs, rhs) {
      case let (.attendeeManager(lhsEvent), .attendeeManager(rhsEvent)):
      return lhsEvent.id == rhsEvent.id
    }
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(self)
  }
}
@Observable class CreateEventModel {
  @ObservationIgnored @Dependency(\.defaultDatabase) var database
  let logger = Logger(subsystem: "amStizzleReboot", category: "CreateEventModel")
  
  var event = Event(id: UUID(), title: "", startDate: Date.now, endDate: Date.now + 3600)
  
  var newEventTitle = ""
  var eventBegin = Date()
  var eventEnd = Date() + 3600
  
  func saveEventButtonTapped() {
  withErrorReporting {
    try database.write { db in
      event.title = newEventTitle
      event.startDate = eventBegin
      event.endDate = eventEnd
      
      try Event
        .upsert { event }
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
  @Environment(\.dismiss) var dismiss
  
  @State var model: CreateEventModel
  @State private var path: [Destination] = []
  
  init() {
    _model = State(wrappedValue: CreateEventModel())
  }
  
  var body: some View {
    NavigationStack(path: $path) {
      Form {
        Section {
          TextField("Event title", text: $model.newEventTitle)
            .autocorrectionDisabled()
            .onSubmit {
              model.saveEventButtonTapped()
            }
          DatePicker("Event Begin", selection: $model.eventBegin, displayedComponents: [.date, .hourAndMinute])
          DatePicker("Event ends", selection: $model.eventEnd, displayedComponents: [.date, .hourAndMinute])
        }
        
#warning("Navlink upserts event. not best solution I guess")
//        NavigationLink(destination: AttendeeManagerSheet(event: model.event)) {
//          Text("Manage Attendees")
//        }
//        .simultaneousGesture(TapGesture().onEnded {
//          model.saveEventButtonTapped()
//          print("saved saved saved")
//        } )
        Button {
          model.saveEventButtonTapped()
          path.append(.attendeeManager(event: model.event))
        } label: {
          HStack {
            Text("Manage attendees")
              .frame(maxWidth: .infinity)
            Image(systemName: "chevron.right")
          }
        }
        .disabled(model.newEventTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
      .navigationDestination(for: Destination.self, destination: \.view)
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
    CreateEventSheet()
}

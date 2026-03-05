
//  EventDetailView.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 18.12.25.

import os
import SwiftUI
import SQLiteData
//import Dependencies

@Observable class EventDetailModel {
  let logger = Logger(subsystem: "amStizzleReboot", category: "EventDetailView")
  @ObservationIgnored @Dependency(\.defaultDatabase) var database
  @ObservationIgnored @AppStorage("selectedUserID") var currentUserIDString: String = ""
  
  let event: Event
  
  @ObservationIgnored @FetchAll(EventAttendee.none)
  var eventAttendees
  
  init(event: Event) {
    self.event = event
  }
  
  func attendees(for event: Event) -> [EventAttendee] {
    (try? database.read { db in
      try EventAttendee.where { $0.eventId.eq(event.id) }
        .fetchAll(db)
    })
    ?? []
  }
  
  func attendeeCount(for event: Event) -> Int {
    (try? database.read { db in
      try EventAttendee.where { $0.eventId.eq(event.id) }
        .fetchCount(db)
    })
    ?? 0
  }
  
  func acceptEventInvitation() {
    guard let userId = UUID(uuidString: currentUserIDString) else { return }
    withErrorReporting {
      print(userId.uuidString)
      try database.write { db in
        try EventAttendee.insert { EventAttendee.Draft(eventId: event.id, userId: userId) }
          .execute(db)
      }
    }
  }
  
  func declineEventInvitation() {
    guard let currentUserId = UUID(uuidString: currentUserIDString) else { return }
    withErrorReporting {
      try database.write { db in
        try EventAttendee
          .where { $0.userId.eq(currentUserId) }
          .delete()
          .execute(db)
      }
      logger.info("%%% Attendee for event deleted")
    }
  }
  
  func reloadAttendeeData() async {
    await withErrorReporting {
      _ = try await $eventAttendees.load(
        EventAttendee
          .where { $0.eventId.eq(event.id) }
        , animation: .default
      )
    }
  }
    
  func loadTask() async {
    //    await reloadUsersData()
    await reloadAttendeeData()
  }
}

struct EventDetailView: View {
  @State var model: EventDetailModel
  init(event: Event) {
    _model = State(wrappedValue: EventDetailModel(event: event))
  }
  
  var body: some View {
    Form {
      HStack {
        Text("From: ")
        Spacer()
        Text(model.event.startDate.formatted(date: .abbreviated, time: .shortened))
      }
      HStack {
        Text("To: ")
        Spacer()
        Text(model.event.endDate.formatted(date: .abbreviated, time: .shortened))
      }
      HStack {
        Text("Attendees: ")
        Spacer()
        NavigationLink(destination: AttendeeManagerSheet(event: model.event)) {
#warning("works only when coming from EventsList")
          Text("\(model.attendeeCount(for: model.event))")
        }
      }
      
      ForEach(model.attendees(for: model.event)) { attendee in
        Text(attendee.userId.uuidString)
          .font(.footnote)
      }
      
      HStack {
        Button {
          model.declineEventInvitation()
        } label: {
          ZStack {
            RoundedRectangle(cornerRadius: 8)
              .fill(Color.red)
            Text("Nope")
          }
        }
        
        Button {
          // implement maybe-logic
        } label: {
          ZStack {
            RoundedRectangle(cornerRadius: 8)
              .fill(Color.yellow)
            Text("maybe")
          }
          .frame(width: 70)
        }
        
        Button {
          model.acceptEventInvitation()
        } label: {
          ZStack {
            RoundedRectangle(cornerRadius: 8)
              .fill(Color.green)
            Text("am Stizzle!")
          }
        }
      }
      .frame(height: 50)
      .navigationTitle(model.event.title)
    }
    .task {
      await model.loadTask()
    }
    .onAppear {
      print("%%%% selectedUserID: \(model.currentUserIDString)")
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
    EventDetailView(event: event)
  }
}

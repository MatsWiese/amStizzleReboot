
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
  
  func invitationCount(for event: Event) -> Int {
    (try? database.read { db in
      try EventAttendee.where { $0.eventId.eq(event.id) && $0.status.eq(AttandanceStatus.invited) }
        .fetchCount(db)
    })
    ?? 0
  }
  
  func attendeeCount(for event: Event) -> Int {
    (try? database.read { db in
      try EventAttendee.where { $0.eventId.eq(event.id) && $0.status.eq(AttandanceStatus.attending) }
        .fetchCount(db)
    })
    ?? 0
  }
  
    func declinedCount(for event: Event) -> Int {
      (try? database.read { db in
        try EventAttendee.where { $0.eventId.eq(event.id) && $0.status.eq(AttandanceStatus.notAttending) }
          .fetchCount(db)
      })
      ?? 0
  }
  
  func acceptEventInvitation() {
    guard let userId = UUID(uuidString: currentUserIDString) else { return }
    withErrorReporting {
      print(userId.uuidString)
      try database.write { db in
        try EventAttendee.upsert { EventAttendee.Draft(eventId: event.id, userId: userId, status: .attending) }
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
  
  func reloadCurrentUserData() async {
    guard let currentUserId = UUID(uuidString: currentUserIDString) else { return }
    await withErrorReporting {
      _ = try await $currentUser.load(
        EventAttendee
          .where { $0.eventId.eq(event.id) && $0.userId.eq(currentUserId) }
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
//      HStack {
////        Text("Attendees: ")
////        Spacer()
        NavigationLink(destination: AttendeeManagerSheet(event: model.event)) {
#warning("works only when coming from EventsList")
          HStack {
            Text("Attendees: ")
            Text("\(model.attendeeCount(for: model.event))")
            Spacer()
            Text("Declined: ")
            Text("\(model.declinedCount(for: model.event))")
            Spacer()
            Text("Invited: ")
            Text("\(model.invitationCount(for: model.event))")
          }
        }
//      }
      
      ForEach(model.attendees(for: model.event)) { attendee in
        HStack {
          Text(attendee.userId.uuidString)
          Spacer()
          Text(attendee.status.displayName)
        }
        .font(.caption2)
      }
      
      
      
      HStack {
        
        if model.currentUser?.status ?? .invited != .notAttending {
          Button {
            model.declineEventInvitation()
          } label: {
            ZStack {
              RoundedRectangle(cornerRadius: 8)
                .fill(Color.red)
              Text("Nope")
            }
          }
        }
        
        if model.currentUser?.status ?? .invited != .unsure {
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
        }
        
        if model.currentUser?.status ?? .invited != .attending {
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

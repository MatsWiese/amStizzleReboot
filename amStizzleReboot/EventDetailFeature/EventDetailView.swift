
//  EventDetailView.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 18.12.25.

import os
import SwiftUI
import SQLiteData
//import Dependencies

//@Observable class EventDetailModel {
//  let event: Event
//  
//}

struct EventDetailView: View {
  @Dependency(\.defaultDatabase) var database
  @AppStorage("selectedUserID") var currentUserIDString: String = ""
  
  let logger = Logger(subsystem: "amStizzleReboot", category: "EventDetailView")
  
  let event: Event
  
  //  @FetchAll(
  //  EventAttendee.where { $0.eventId.eq(event.id) })
  //  var attendees: [EventAttendee]
  
  var body: some View {
    Form {
      HStack {
        Text("From: ")
        Spacer()
        Text(event.startDate.formatted(date: .abbreviated, time: .shortened))
      }
      HStack {
        Text("To: ")
        Spacer()
        Text(event.endDate.formatted(date: .abbreviated, time: .shortened))
      }
      HStack {
        Text("Attendees: ")
        Spacer()
        NavigationLink(destination: AttendeeManagerSheet(event: event)) {
#warning("works only when coming from EventsList")
          Text("\(attendeeCount(for: event))")
        }
      }
      
        ForEach(attendees(for: event)) { attendee in
          Text(attendee.userId.uuidString)
            .font(.footnote)
      }
      
      
      HStack {
        Button {
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
        } label: {
          ZStack {
            RoundedRectangle(cornerRadius: 8)
              .fill(Color.red)
            Text("Nope")
          }
        }
        
        Button {
          
        } label: {
          ZStack {
            RoundedRectangle(cornerRadius: 8)
              .fill(Color.yellow)
            Text("maybe")
          }
          .frame(width: 70)
        }
        
        Button {
          guard let userId = UUID(uuidString: currentUserIDString) else { return }
          withErrorReporting {
            print(userId.uuidString)
            try database.write { db in
              try EventAttendee.insert { EventAttendee.Draft(eventId: event.id, userId: userId) }
                .execute(db)
            }
          }
        } label: {
          ZStack {
            RoundedRectangle(cornerRadius: 8)
              .fill(Color.green)
            Text("am Stizzle!")
          }
        }
      }
      .frame(height: 50)
        .navigationTitle(event.title)
    }
    .onAppear {
      print("%%%% selectedUserID: \(currentUserIDString)")
    }
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


//  EventDetailView.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 18.12.25.

import os
import SwiftUI
import Supabase
import Dependencies

@Observable class EventDetailModel {
  let logger = Logger(subsystem: "amStizzleReboot", category: "EventDetailView")
  //  @ObservationIgnored @Dependency(\.defaultDatabase) var database
  //  @ObservationIgnored @AppStorage("selectedUserID") var currentUserIDString: String = ""
  //
  let event: Event
  //
  //  @ObservationIgnored @FetchAll(EventAttendee.none)
  //  var eventAttendees
  //
  //  @ObservationIgnored @FetchOne(EventAttendee.none)
  //  var currentUser
  //  //    .where($0.userId.eq(UUID(uuidString: currentUserIDString))
  //
  init(event: Event) {
    self.event = event
  }
  
  var currentProfile = Profile(
    id: UUID(),
    firstName: "",
    lastName: "",
    username: "",
    avatarURL: "",
    createdAt: Date.now,
    updatedAt: Date.now
  )
  
  var currentEventAttendee = EventAttendee(
    id: UUID(),
    createdAt: Date.now,
    updatedAt: Date.now,
    eventId: UUID(),
    profileID: UUID(),
    attendanceStatus: 0
  )
  
  //  func currentUser(for event: Event) -> EventAttendee {
  //    guard let userId = UUID(uuidString: currentUserIDString) else { return EventAttendee(id: UUID(), eventId: UUID(), userId: UUID(), status: .invited) }
  //    (try? database.read { db in
  //      try EventAttendee.where { $0.eventId.eq(event.id) && $0.userId.eq(UUID(uuidString: currentUserIDString)!) }
  //        .fetchOne(db)
  //    })
  //    ?? return EventAttendee(id: UUID(), eventId: UUID(), userId: UUID(), status: .invited)
  //  }
  
  //  func attendees(for event: Event) -> [EventAttendee] {
  //    (try? database.read { db in
  //      try EventAttendee.where { $0.eventId.eq(event.id) }
  //        .fetchAll(db)
  //    })
  //    ?? []
  //  }
  //
  //  func invitationCount(for event: Event) -> Int {
  //    (try? database.read { db in
  //      try EventAttendee.where { $0.eventId.eq(event.id) && $0.status.eq(AttandanceStatus.invited) }
  //        .fetchCount(db)
  //    })
  //    ?? 0
  //  }
  //
  //  func attendeeCount(for event: Event) -> Int {
  //    (try? database.read { db in
  //      try EventAttendee.where { $0.eventId.eq(event.id) && $0.status.eq(AttandanceStatus.attending) }
  //        .fetchCount(db)
  //    })
  //    ?? 0
  //  }
  //
  //  func declinedCount(for event: Event) -> Int {
  //    (try? database.read { db in
  //      try EventAttendee.where { $0.eventId.eq(event.id) && $0.status.eq(AttandanceStatus.notAttending) }
  //        .fetchCount(db)
  //    })
  //    ?? 0
  //  }
  //
  func acceptEventInvitation() async {
    Task {
      do {
        try await Supabase.shared
          .from("event_attendees")
          .update(["attendance_status" : 1])
          .eq("profile_id", value: currentProfile.id)
          .eq("event_id", value: event.id)
          .execute()
        logger.info("AttendanceStatus set to 1")
      } catch {
        logger.error("\(error.localizedDescription)")
      }
    }
  }
  
  func unsureEventInvitation() async {
    Task {
      do {
        try await Supabase.shared
          .from("event_attendees")
          .update(["attendance_status" : 3])
          .eq("profile_id", value: currentProfile.id)
          .eq("event_id", value: event.id)
          .execute()
        logger.info("AttendanceStatus set to 3")
      } catch {
        logger.error("\(error.localizedDescription)")
      }
    }
  }
  
  func declineEventInvitation() async {
//    Task {
      do {
        try await Supabase.shared
          .from("event_attendees")
          .update(["attendance_status" : 2])
          .eq("profile_id", value: currentProfile.id)
          .eq("event_id", value: event.id)
          .execute()
        logger.info("AttendanceStatus set to 2")
      } catch {
        logger.error("\(error.localizedDescription)")
      }
//    }
  }
  
    func reloadAttendeeData() async {
      do {
        logger.info("Current user: \(self.currentProfile.id)")
        
        let eventAttendee: EventAttendee =
        try await Supabase.shared
          .from("event_attendees")
          .select()
          .eq("id", value: currentProfile.id)
          .eq("event_id", value: event.id)
          .single()
          .execute()
          .value
        
        currentEventAttendee = eventAttendee
        
      } catch {
        logger.error("\(error)")
      }
//      await withErrorReporting {
//        _ = try await $eventAttendees.load(
//          EventAttendee
//            .where { $0.eventId.eq(event.id) }
//          , animation: .default
//        )
//      }
    }
  
  func reloadCurrentUserData() async {
    do {
      let currentUser = try await Supabase.shared.auth.session.user
      
      logger.info("Current user: \(currentUser.id)")
      
      let profile: Profile =
      try await Supabase.shared
        .from("profiles")
        .select()
        .eq("id", value: currentUser.id)
        .single()
        .execute()
        .value
      
      currentProfile = profile
      
    } catch {
      logger.error("\(error)")
    }
  }
  
  //
  func loadTask() async {
    await reloadAttendeeData()
    await reloadCurrentUserData()
  }
}

struct EventDetailView: View {
  @State var model: EventDetailModel
  init(event: Event) {
    _model = State(wrappedValue: EventDetailModel(event: event))
  }
  
  var body: some View {
    VStack {
      //      Form {
      HStack {
        Text("From: ")
        Spacer()
        //          Text(model.event.startDate.formatted(date: .abbreviated, time: .shortened))
        Text(model.event.startDate!.formatted(date: .abbreviated, time: .shortened))
      }
      HStack {
        Text("To: ")
        Spacer()
        Text(model.event.endDate!.formatted(date: .abbreviated, time: .shortened))
      }
      HStack {
        Text("Creator: ")
        Spacer()
        Text(model.currentProfile.username ?? "Anonymous")
//          .font(.caption2)
      }
      HStack {
        Text("Attendance Status: ")
        Spacer()
        Text(model.currentEventAttendee.attendanceStatus?.description ?? "Unknown")
//          .font(.caption2)
      }
      
      
      
      NavigationLink("Manager", destination: AttendeeManagerSheet(event: model.event))
      //      {
#warning("works only when coming from EventsList")
      //          HStack {
      //            Text("Attendees: ")
      //            Text("\(model.attendeeCount(for: model.event))")
      //            Spacer()
      //            Text("Declined: ")
      //            Text("\(model.declinedCount(for: model.event))")
      //            Spacer()
      //            Text("Invited: ")
      //            Text("\(model.invitationCount(for: model.event))")
      //          }
      //        }
      //
      //        ForEach(model.attendees(for: model.event)) { attendee in
      //          HStack {
      //            Text(attendee.userId.uuidString)
      //            Spacer()
      //            Text(attendee.status.displayName)
      //          }
      //          .font(.caption2)
      //        }
      //      }
      //      .frame(height: 300)
      
      HStack {
        //        if model.currentUser?.status ?? .invited != .notAttending {
        if model.currentEventAttendee.attendanceStatus != 2 {
          Button {
            Task {
              await model.declineEventInvitation()
              await model.loadTask()
            }
          } label: {
            ZStack {
              RoundedRectangle(cornerRadius: 8)
                .fill(Color.red)
              Text("Nope")
            }
          }
        }
        
        //        if model.currentUser?.status ?? .invited != .unsure {
          if model.currentEventAttendee.attendanceStatus != 3 {
            Button {
              Task {
                await model.unsureEventInvitation()
                await model.loadTask()
              }
            } label: {
              ZStack {
                RoundedRectangle(cornerRadius: 8)
                  .fill(Color.yellow)
                Text("maybe")
              }
              .frame(width: 70)
            }
          }
        
        //        if model.currentUser?.status ?? .invited != .attending {
          if model.currentEventAttendee.attendanceStatus != 1 {
            Button {
              Task {
                await model.acceptEventInvitation()
                await model.loadTask()
              }
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
      .navigationTitle(model.event.title ?? "Event")
      .task {
        await model.loadTask()
      }
      //      .onAppear {
      //        print("%%%% selectedUserID: \(model.currentUserIDString)")
      //      }
      Spacer()
    }
  }
}

#Preview {
  //  let event = prepareDependencies {
  //    try! $0.bootstrapDatabase()
  //    try! $0.defaultDatabase.seed()
  //    return try! $0.defaultDatabase.read { db in
  //      try Event.fetchOne(db)!
  //    }
  //  }
  let event = Event(id: UUID(1), title: "Hello, World!", details: "", startDate: Date.now, endDate: Date.now, createdAt: Date.now, updatedAt: Date.now, creatorId: UUID(1))
  
  NavigationStack {
    EventDetailView(event: event)
      .padding()
  }
}

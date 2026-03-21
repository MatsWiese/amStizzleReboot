
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
  
  let event: Event
  
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
    profileId: UUID(),
    attendanceStatus: 0
  )
  
  var invitationCount: Int = 0
  var invitationAcceptedCount: Int = 0
  var invitationDeclinedCount: Int = 0
  var unsureAboutInvitationCount: Int = 0
  
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
//        await loadAttendanceStatus()
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
//        await loadAttendanceStatus()
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
//      await loadAttendanceStatus()
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
        .eq("profile_id", value: currentProfile.id)
        .eq("event_id", value: event.id)
        .single()
        .execute()
        .value
      
      logger.info("current AttendanceStatus: \(eventAttendee.attendanceStatus?.description ?? "nil")")
      currentEventAttendee = eventAttendee
      
    } catch {
      logger.error("\(error)")
    }
  }
  
  func loadAttendanceStatus() async {
    do {
      let invitationCount: Int? =
      try await Supabase.shared
        .from("event_attendees")
        .select(head: true, count: .exact)
        .eq("event_id", value: event.id)
        .eq("attendance_status", value: 0)
        .execute()
        .count
      
      logger.info("InvitationCount: \(invitationCount ?? -1)")
      
      self.invitationCount = invitationCount ?? -1
      
    } catch {
      logger.error("\(error)")
    }
    
    do {
      let invitationAcceptedCount: Int? =
      try await Supabase.shared
        .from("event_attendees")
        .select(head: true, count: .exact)
        .eq("event_id", value: event.id)
        .eq("attendance_status", value: 1)
        .execute()
        .count
      
      logger.info("invitationAcceptedCount: \(invitationAcceptedCount ?? -1)")
      
      self.invitationAcceptedCount = invitationAcceptedCount ?? -1
      
    } catch {
      logger.error("\(error)")
    }
    
    do {
      let invitationDeclinedCount: Int? =
      try await Supabase.shared
        .from("event_attendees")
        .select(head: true, count: .exact)
        .eq("event_id", value: event.id)
        .eq("attendance_status", value: 2)
        .execute()
        .count
      
      logger.info("invitationDeclinedCount: \(invitationDeclinedCount ?? -1)")
      
      self.invitationDeclinedCount = invitationDeclinedCount ?? -1
      
    } catch {
      logger.error("\(error)")
    }
    
    do {
      let unsureAboutInvitationCount: Int? =
      try await Supabase.shared
        .from("event_attendees")
        .select(head: true, count: .exact)
        .eq("event_id", value: event.id)
        .eq("attendance_status", value: 3)
        .execute()
        .count
      
      logger.info("unsureAboutInvitationCount: \(unsureAboutInvitationCount ?? -1)")
      
      self.unsureAboutInvitationCount = unsureAboutInvitationCount ?? -1
      
    } catch {
      logger.error("\(error)")
    }
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
    await loadAttendanceStatus()
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
      
      
      HStack {
        NavigationLink("Manage Attendees", destination: AttendeeManagerSheet(event: model.event))
        Spacer()
        Text("Invited: ")
        Text("\(model.invitationCount)")
      }
      HStack {
        Text("Declined: ")
        Text("\(model.invitationDeclinedCount)")
        Spacer()
        Text("Maybe: ")
        Text("\(model.unsureAboutInvitationCount)")
        Spacer()
        Text("Attendees: ")
        Text("\(model.invitationAcceptedCount)")
      }
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
        if model.currentEventAttendee.attendanceStatus != 2 {
          Button {
            Task {
              await model.declineEventInvitation()
              await model.loadTask()
              //                reload Attendance_Counts
            }
          } label: {
            ZStack {
              RoundedRectangle(cornerRadius: 8)
                .fill(Color.red)
              Text("Nope")
            }
          }
        }
        
        if model.currentEventAttendee.attendanceStatus != 3 {
          Button {
            Task {
              await model.unsureEventInvitation()
              await model.loadTask()
              //                reload Attendance_Counts
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
      Spacer()
    }
  }
}

#Preview {
  let event = Event(id: UUID(1), title: "Hello, World!", details: "", startDate: Date.now, endDate: Date.now, createdAt: Date.now, updatedAt: Date.now, creatorId: UUID(1))
  
  NavigationStack {
    EventDetailView(event: event)
      .padding()
  }
}

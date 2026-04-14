
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
    eventId: UUID(),
    profileId: UUID(),
    username: "",
    attendanceStatus: 0,
    createdAt: Date.now,
    updatedAt: Date.now,
  )
  var eventAttendees: [EventAttendee] = []
  
  var invitationCount: Int = 0
  var invitationAcceptedCount: Int = 0
  var invitationDeclinedCount: Int = 0
  var unsureAboutInvitationCount: Int = 0
  
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
    Task {
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
  
  func reloadCurrentAttendeeData() async {
    do {
      logger.info("Current profileId: \(self.currentProfile.id)")
      
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
  
  func reloadEventAttendees() async {
    do {
      let fetchedEventAttendees: [EventAttendee] =
      try await Supabase.shared
        .from("event_attendees")
        .select()
        .eq("event_id", value: event.id)
        .execute()
        .value
      
      eventAttendees = fetchedEventAttendees
      
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
  
  func loadTask() async {
    await reloadCurrentUserData()
    await reloadCurrentAttendeeData()
    await reloadEventAttendees()
    await loadAttendanceStatus()
  }
  
  func onAcceptEvent() {
    // TODO: Implementation
  }
  
  func onDeclineEvent() {
    // TODO: Implementation
  }
}

struct EventDetailView: View {
  @Environment(AppRouter.self) private var router
  @State var model: EventDetailModel
  init(event: Event) {
    _model = State(wrappedValue: EventDetailModel(event: event))
  }
  
  var body: some View {
      VStack {
        EventRowView(
          event: model.event,
          eventAttendees: model.eventAttendees,
          currentEventAttendee: model.currentEventAttendee,
          onTapAcceptButton: model.onAcceptEvent,
          onTapDeclineButton: model.onDeclineEvent
        )
        HStack {
          Text("Creator: ")
          Spacer()
          Text(model.currentProfile.username ?? "Anonymous")
          //          .font(.caption2)
        }
        HStack {
          Text("EventID: ")
          Spacer()
          Text(model.event.id.uuidString)
            .font(.caption2)
        }
        
        HStack {
          Button {
            router.push(.attendeeManager(event: model.event))
          } label: {
            Text("Manage Attendees")
          }
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
              model.logger.info("AttendanceStatus is not 2")
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
          
          if model.currentEventAttendee.attendanceStatus != 3 {
            Button {
              model.logger.info("AttendanceStatus is not 3")
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
          
          if model.currentEventAttendee.attendanceStatus != 1 {
            Button {
              //            model.logger.info("AttendanceStatus is not 1")
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
  .environment(AppRouter())
}

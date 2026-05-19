
//  EventDetailView.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 18.12.25.

import os
import SwiftUI
import Supabase
import Dependencies

extension EventDetailModel {
  enum State {
    case loading
    case error(String)
    case success(SuccessModel)
    
    struct SuccessModel {
      let event: Event
      let eventAttendees: [EventAttendee]
      let profile: Profile
      let currentAttendee: EventAttendee
    }
  }
}

@Observable class EventDetailModel {
  let logger = Logger(subsystem: "amStizzleReboot", category: "EventDetailView")
  let repository: SupabaseRepository
  let eventID: Event.ID
  var state: State = .loading
  
  init(eventID: Event.ID,/* event: Event,*/ repository: SupabaseRepository = .shared) {
    self.eventID = eventID
//    self.event = event
    self.repository = repository
  }
  
  var currentEventAttendee = EventAttendee(
    id: UUID(),
    eventID: UUID(),
    profileId: UUID(),
    username: "",
    attendanceStatus: 0,
    createdAt: Date.now,
    updatedAt: Date.now,
  )
//  var eventAttendees: [EventAttendee] = []
  
  var invitationCount: Int = 0
  var invitationAcceptedCount: Int = 0
  var invitationDeclinedCount: Int = 0
  var unsureAboutInvitationCount: Int = 0
  
  func loadEvent() async throws -> Event {
      do {
      return try await repository.getEvent(byID: eventID)
      } catch {
        logger.error("\(error)")
        throw error
      }
  }
  
  func acceptEventInvitation() async {
    if case let .success(successModel) = state {
      do {
        try await Supabase.shared
          .from("event_attendees")
          .update(["attendance_status" : 1])
          .eq("profile_id", value: successModel.profile.id)
          .eq("event_id", value: eventID)
          .execute()
        logger.info("AttendanceStatus set to 1")
      } catch {
        logger.error("\(error.localizedDescription)")
      }
    }
  }
  
  func unsureEventInvitation() async {
    if case let .success(successModel) = state {
      do {
        try await Supabase.shared
          .from("event_attendees")
          .update(["attendance_status" : 3])
          .eq("profile_id", value: successModel.profile.id)
          .eq("event_id", value: eventID)
          .execute()
        logger.info("AttendanceStatus set to 3")
      } catch {
        logger.error("\(error.localizedDescription)")
      }
    }
  }
  
  func declineEventInvitation() async {
    if case let .success(successModel) = state {
      do {
        try await Supabase.shared
          .from("event_attendees")
          .update(["attendance_status" : 2])
          .eq("profile_id", value: successModel.profile.id)
          .eq("event_id", value: eventID)
          .execute()
        logger.info("AttendanceStatus set to 2")
      } catch {
        logger.error("\(error.localizedDescription)")
      }
    }
  }
  
//  func loadEvent() async {
//    do {
//      let currentUser = try await Supabase.shared.auth.session.user
//      
//      logger.info("EventDetailModel: CurrentUserID: \(currentUser.id)")
//      
//      let profile: Profile =
//      try await Supabase.shared
//        .from("profiles")
//        .select()
//        .eq("id", value: currentUser.id)
//        .single()
//        .execute()
//        .value
//      
//      currentProfile = profile
//      
//    } catch {
//      logger.error("\(error)")
//    }
//  }
  
  func reloadCurrentUserData() async throws -> Profile {
    do {
      return try await repository.getCurrentUserProfile()
    } catch {
      logger.error("\(error)")
      throw error
    }
  }
  
  func reloadCurrentAttendeeData() async throws -> EventAttendee {
    do {
      return try await repository.getCurrentEventAttendee(for: eventID)
    } catch {
      logger.error("\(error)")
      throw error
    }
  }
  
  func reloadEventAttendees() async throws -> [EventAttendee] {
    do {
    return try await repository.getEventAttendeesWithUsernames(forEvent: eventID)
    } catch {
      logger.error("\(error)")
      throw error
    }
  }
  
  func loadAttendanceStatus() async {
    do {
      let invitationCount: Int? =
      try await Supabase.shared
        .from("event_attendees")
        .select(head: true, count: .exact)
        .eq("event_id", value: eventID)
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
        .eq("event_id", value: eventID)
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
        .eq("event_id", value: eventID)
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
        .eq("event_id", value: eventID)
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
//    try await repository.getEvent(byID: eventID)
    state = .loading
    do {
      let event = try await loadEvent()
      let profile = try await reloadCurrentUserData()
      let currentAttendee = try await reloadCurrentAttendeeData()
      let eventAttendees = try await reloadEventAttendees()
      await loadAttendanceStatus()
      state = .success(.init(event: event, eventAttendees: eventAttendees, profile: profile, currentAttendee: currentAttendee))
    } catch {
      state = .error(error.localizedDescription)
    }
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
  @State var viewModel: EventDetailModel
  init(eventID: Event.ID) {
    _viewModel = State(wrappedValue: EventDetailModel(eventID: eventID))
  }
  
  var body: some View {
    content
      .task(id: viewModel.eventID) {
        await viewModel.loadTask()
      }
  }
}

extension EventDetailView {
  @ViewBuilder
  var content: some View {
    switch viewModel.state {
    case .loading:
      loadingContent
    case .error(let message):
      errorContent(message: message)
    case .success(let successModel):
      successContent(successModel: successModel)
    }
  }
  
  var loadingContent: some View {
    ProgressView()
      .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
  
  func errorContent(message: String) -> some View {
    ContentUnavailableView("Error", image: "exclamationmark.triangle.fill", description: Text(message))
  }
  
  func successContent(successModel: EventDetailModel.State.SuccessModel) -> some View {
    VStack {
        EventRowView(
          event: successModel.event,
          eventAttendees: successModel.eventAttendees,
          currentEventAttendee: successModel.currentAttendee,
          onTapAcceptButton: viewModel.onAcceptEvent,
          onTapDeclineButton: viewModel.onDeclineEvent
        )
      
      HStack {
        Text("Creator: ")
        Spacer()
        Text(successModel.profile.username ?? "Anonymous")
        //          .font(.caption2)
      }
      HStack {
        Text("EventID: ")
        Spacer()
        Text(viewModel.eventID.uuidString)
          .font(.caption2)
      }
      
      HStack {
        Button {
          router.push(.attendeeManager(eventID: viewModel.eventID))
        } label: {
          Text("Manage Attendees")
        }
        Spacer()
        Text("Invited: ")
        Text("\(viewModel.invitationCount)")
      }
      HStack {
        Text("Declined: ")
        Text("\(viewModel.invitationDeclinedCount)")
        Spacer()
        Text("Maybe: ")
        Text("\(viewModel.unsureAboutInvitationCount)")
        Spacer()
        Text("Attendees: ")
        Text("\(viewModel.invitationAcceptedCount)")
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
        if viewModel.currentEventAttendee.attendanceStatus != 2 {
          Button {
            viewModel.logger.info("AttendanceStatus is not 2")
            Task {
              await viewModel.declineEventInvitation()
              await viewModel.loadTask()
            }
          } label: {
            ZStack {
              RoundedRectangle(cornerRadius: 8)
                .fill(Color.red)
              Text("Nope")
            }
          }
        }
        
        if viewModel.currentEventAttendee.attendanceStatus != 3 {
          Button {
            viewModel.logger.info("AttendanceStatus is not 3")
            Task {
              await viewModel.unsureEventInvitation()
              await viewModel.loadTask()
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
        
        if viewModel.currentEventAttendee.attendanceStatus != 1 {
          Button {
            //            model.logger.info("AttendanceStatus is not 1")
            Task {
              await viewModel.acceptEventInvitation()
              await viewModel.loadTask()
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
      .navigationTitle(successModel.event.title ?? "No title")
      
      Spacer()
    }
  }
}
#Preview {
  let event = Event(id: UUID(1), title: "Hello, World!", details: "", startDate: Date.now, endDate: Date.now, createdAt: Date.now, updatedAt: Date.now, creatorId: UUID(1))
  
  NavigationStack {
    EventDetailView(eventID: event.id)
      .padding()
  }
  .environment(AppRouter())
}

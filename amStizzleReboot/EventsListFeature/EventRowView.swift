//
//  ContentView.swift
//  EventRowViewTest
//
//  Created by Mats Wiese on 11.10.25.
//

import os
import Supabase
import SwiftUI

@Observable class EventRowModel {
   var eventsAttendanceStatus = -1
//  let logger = Logger(subsystem: "amStizzleReboot", category: "EventRowModel")
//
//  let event: Event
//  let currentUser: EventAttendee
//
//  init(event: Event) {
//    self.event = event
//  }
////  func acceptEventInvitation() async {
////    Task {
////      do {
////        try await Supabase.shared
////          .from("event_attendees")
////          .update(["attendance_status" : 1])
////          .eq("profile_id", value: currentProfile.id)
////          .eq("event_id", value: event.id)
////          .execute()
////        logger.info("AttendanceStatus set to 1")
////      } catch {
////        logger.error("\(error.localizedDescription)")
////      }
////    }
////  }
}

struct EventRowView: View {
  @Environment(\.colorScheme) var colorScheme
  @Environment(AppRouter.self) private var router
  let logger = Logger(subsystem: "amStizzleReboot", category: "EventRowView")
  @State var model = EventRowModel()
  //  let attendingUserNames: [String]
  @State var currentEventAttendee: EventAttendee?
//  @State var eventsAttendanceStatus = -1
  let event: Event
  let currentUserId: UUID
  @State var eventAttendees: [EventAttendee] = []
  //  let groupColor: Color
  
  var body: some View {
    VStack {
      ZStack {
        RoundedRectangle(cornerRadius: 60)
          .fill(colorScheme == .dark ? Color.black.opacity(0.9) : Color.white.opacity(0.5))
          .shadow(color: .black.opacity(0.7), radius: 2, x: 2, y: 2)
          .shadow(color: .white.opacity(0.7), radius: 2, x: -2, y: -2)
        
        VStack {
          Button {
//            EventDetailView(event: event)
            router.push(.eventDetail(event: event))
          } label: {
            TitleView
          }
          
          TimeSection
          
          HStack {
            if model.eventsAttendanceStatus == 1 {
              Button {
                router.push(.eventDetail(event: event))
              } label: {
                AttendanceView(currentEventAttendee: currentEventAttendee!,eventAttendees: eventAttendees, invitationState: .inviteAccepted, image: "checkmark.circle.fill", text: "amStizzle!")
              }
            } else if model.eventsAttendanceStatus == 2 {
              Button {
                router.push(.eventDetail(event: event))
              } label: {
                AttendanceView(currentEventAttendee: currentEventAttendee!, eventAttendees: eventAttendees, invitationState: .inviteDeclined, image: "xmark.circle.fill", text: "You declined")
              }
            } else {
              ButtonView(event: event, userId: currentUserId, buttonType: .refuseButton, image: "xmark", text: "nope, i'm out")
              ButtonView(event: event, userId: currentUserId, buttonType: .attendButton, image: "checkmark", text: "am Stizzle!")
            }
          }
//          .frame(minHeight: 90)
        }
        .padding()
        .navigationDestination(for: Destination.self, destination: \.view)
      }
      .frame(height: 270)
      .containerShape(.rect(cornerRadius: 60))
    }
    .task {
      await loadCurrentAttendee()
      await loadEventAttendees()
    }
    //    .padding()
  }
  
  var TitleView: some View {
    ZStack(alignment: .bottomLeading) {
      ConcentricRectangle()
        .fill(Color.blue.opacity(0.5))
        .shadow(color: .black.opacity(0.7), radius: 2, x: 2, y: 2)
        .shadow(color: .white.opacity(0.7), radius: 2, x: -2, y: -2)
      Text(event.title ?? "Unknown Event")
        .minimumScaleFactor(0.5)
        .foregroundStyle(Color.primary)
        .font(.largeTitle)
        .fontWeight(.bold)
        .padding()
        .shadow(color: .black.opacity(0.7), radius: 1, x: 1, y: 1)
        .shadow(color: .white.opacity(0.7), radius: 1, x: -1, y: -1)
    }
    .frame(height: 70)
  }
  
  var TimeSection: some View {
    ZStack(alignment: .leading) {
      Rectangle()
        .fill(Color.gray.opacity(0.2))
        .shadow(color: .black.opacity(0.7), radius: 2, x: 2, y: 2)
        .shadow(color: .white.opacity(0.7), radius: 2, x: -2, y: -2)
      HStack {
        Text(event.startDate?
          .formatted(date: .abbreviated, time: .omitted) ?? "N/A")
        .minimumScaleFactor(0.5)
        .font(.title)
        .fontWeight(.bold)
        .fontDesign(.rounded)
        .foregroundStyle(Color.primary)
        
        Spacer()
        HStack {
          VStack(alignment: .trailing) {
            Text("From:")
            Text("to:")
          }
          .font(.headline)
          .fontDesign(.monospaced)
          
          VStack(alignment: .leading) {
            Text(event.endDate?.formatted(date: .omitted, time: .shortened) ?? "N/A")
            Text(event.endDate?.formatted(date: .omitted, time: .shortened) ?? "N/A")
          }
          .minimumScaleFactor(0.8)
          .fontWeight(.black)
        }
        .font(.title2)
      }
      .shadow(color: .black.opacity(0.7), radius: 1, x: 1, y: 1)
      .shadow(color: .white.opacity(0.7), radius: 1, x: -1, y: -1)
      .padding()
    }
    //    .padding(.vertical, 6)
  }
  
  func loadCurrentAttendee() async {
    do {
//      let currentUser = try await Supabase.shared.auth.session.user
      
      let currentEventAttendee: EventAttendee =
      try await Supabase.shared
        .from("event_attendees")
        .select()
        .eq("profile_id", value: currentUserId)
        .eq("event_id", value: event.id)
        .single()
        .execute()
        .value
      
//      logger.info("currentEventAttendeeId: \(currentEventAttendee.profileId?.uuidString ?? "no profileId")")
      
      self.currentEventAttendee = currentEventAttendee
      model.eventsAttendanceStatus = currentEventAttendee.attendanceStatus!
      logger.info("event: \(event.title ?? "no title"), attendanceStatus: \(model.eventsAttendanceStatus)")
      //      await loadInvitedEvents()
    } catch {
      logger.error("\(error)")
    }
  }
#warning("join Profiles to get usernames")
  func loadEventAttendees() async {
    do {
      let fetchedEventAttendees: [EventAttendee] =
      try await Supabase.shared
        .from("event_attendees")
        .select()
//        .eq("profile_id", value: currentEventAttendee?.profileId)
        .eq("event_id", value: event.id)
        .execute()
        .value
      
      logger.info("Event: \(event.title ?? "no event title"), EventAttendeesCount: \(fetchedEventAttendees.count)")
      
      self.eventAttendees = fetchedEventAttendees
      
    } catch {
      logger.error("\(error)")
    }
  }
}

struct ButtonView: View {
  @State var model = EventRowModel()
  let logger = Logger(subsystem: "amStizzleReboot", category: "ButtonView")
  
  var event: Event
  var userId: UUID
  
  enum ButtonType {
    case attendButton
    case refuseButton
  }
  var buttonColor: Color {
    switch buttonType {
    case .attendButton:
      return Color.green.opacity(0.6)
    case .refuseButton:
      return Color.red.opacity(0.6)
    }
  }
  var buttonType: ButtonType
  var image: String
  var text: String
  
  var body: some View {
    Button {
      switch buttonType {
      case .attendButton:
        model.eventsAttendanceStatus = 1
        Task {
          do {
            try await Supabase.shared
              .from("event_attendees")
              .update(["attendance_status" : 1])
              .eq("profile_id", value: userId)
              .eq("event_id", value: event.id)
              .execute()
            logger.info("AttendanceStatus set to 1")
          } catch {
            logger.error("\(error.localizedDescription)")
          }
          logger.info("event: \(event.title ?? "unknown title"), eventsAttendanceStatus: \(model.eventsAttendanceStatus)")
        }
        
      case .refuseButton:
        model.eventsAttendanceStatus = 2
        Task {
          do {
            try await Supabase.shared
              .from("event_attendees")
              .update(["attendance_status" : 2])
              .eq("profile_id", value: userId)
              .eq("event_id", value: event.id)
              .execute()
            logger.info("AttendanceStatus set to 2")
          } catch {
            logger.error("\(error.localizedDescription)")
          }
          logger.info("event: \(event.title ?? "unknown title"), eventsAttendanceStatus: \(model.eventsAttendanceStatus)")
        }
      }
    } label: {
      ZStack {
        ConcentricRectangle()
          .fill(buttonColor
            .shadow(.inner(color: .black.opacity(0.7), radius: 1, x: -4, y: -4))
            .shadow(.inner(color: .white.opacity(0.7), radius: 1, x: 4, y: 4))
          )
        VStack {
          Image(systemName: image)
            .font(.largeTitle)
            .fontWeight(.heavy)
            .foregroundStyle(Color.white)
            .padding(.bottom, 1)
          Text(text)
            .font(.caption)
            .foregroundStyle(Color.white)
        }
      }
      .shadow(color: .black.opacity(0.7), radius: 2, x: 2, y: 2)
      .shadow(color: .white.opacity(0.7), radius: 2, x: -2, y: -2)
    }
  }
}

struct AttendanceView: View {
  let logger = Logger(subsystem: "amStizzleReboot", category: "AttendanceView")
  
  enum InvitationState {
    case inviteAccepted
    case inviteDeclined
  }
  var backgroundColor: Color {
    switch invitationState {
    case .inviteAccepted:
      return Color.green.opacity(0.3)
    case .inviteDeclined:
      return Color.red.opacity(0.3)
    }
  }
  
  var currentEventAttendee: EventAttendee
  var eventAttendees: [EventAttendee]
  var invitationState: InvitationState
  var image: String
  var text: String
  
  var body: some View {
    ZStack(alignment: .topLeading) {
      ConcentricRectangle()
        .fill(backgroundColor
          .shadow(.inner(color: .white.opacity(0.7), radius: 1, x: -4, y: -4))
          .shadow(.inner(color: .black.opacity(0.7), radius: 1, x: 4, y: 4))
        )
      VStack(alignment: .leading) {
        Text(text)
          .minimumScaleFactor(0.5)
          .foregroundStyle(Color.primary)
          .font(.title2)
          .fontWeight(.bold)
          .shadow(color: .black.opacity(0.7), radius: 1, x: 1, y: 1)
          .shadow(color: .white.opacity(0.7), radius: 1, x: -1, y: -1)
        HStack(spacing: -6) {
          ForEach(eventAttendees.filter { $0.attendanceStatus == 1 }) { attendee in
#warning("implement circles with usernames after joined fetch")
            //            ZStack {
            //              Circle()
            //                .fill(Color.gray)
            //              HStack {
            //                Text(currentUser.firstName.first!.uppercased() + currentUser.lastName.first!.uppercased())
            //              }
            //              .fontWeight(.bold)
            //              .fontDesign(.rounded)
            //              .foregroundStyle(Color.white)
            //              .fontWidth(.compressed)
            //            }
            Image(systemName: "person.circle")
              .minimumScaleFactor(0.5)
              .foregroundStyle(attendee.profileId == currentEventAttendee.profileId ? Color.orange : Color.primary)
              .font(.title2)
              .fontWeight(.bold)
              .shadow(color: .black.opacity(0.7), radius: 1, x: 1, y: 1)
              .shadow(color: .white.opacity(0.7), radius: 1, x: -1, y: -1)
          }
          Spacer()
          ForEach(eventAttendees.filter { $0.attendanceStatus == 2 }) { attendee in
#warning("implement circles with usernames after joined fetch")
            //            ZStack {
            //              Circle()
            //                .fill(Color.gray)
            //              HStack {
            //                Text(currentUser.firstName.first!.uppercased() + currentUser.lastName.first!.uppercased())
            //              }
            //              .fontWeight(.bold)
            //              .fontDesign(.rounded)
            //              .foregroundStyle(Color.white)
            //              .fontWidth(.compressed)
            //            }
            Image(systemName: "person.circle")
              .minimumScaleFactor(0.5)
              .foregroundStyle(attendee.profileId == currentEventAttendee.profileId ? Color.mint : Color.primary)
              .font(.title2)
              .fontWeight(.bold)
              .shadow(color: .black.opacity(0.7), radius: 1, x: 1, y: 1)
              .shadow(color: .white.opacity(0.7), radius: 1, x: -1, y: -1)
          }
        }
      }
      .padding()
    }
  }
}

#Preview {
  NavigationStack {
    let currentSampleUserId = UUID()
    let currentSampleAttendee = EventAttendee(id: UUID(), eventId: UUID(), profileId: currentSampleUserId, attendanceStatus: 2, createdAt: Date.now, updatedAt: Date.now)
    let event = Event(id: UUID(), title: "Test", details: nil, startDate: Date.now, endDate: Date.now + 3600, createdAt: Date.now, updatedAt: Date.now, creatorId: currentSampleUserId)
    let sampleEventAttendees = [
      currentSampleAttendee,
      EventAttendee(id: UUID(), eventId: event.id, profileId: UUID(), attendanceStatus: 1, createdAt: Date.now, updatedAt: Date.now),
      EventAttendee(id: UUID(), eventId: event.id, profileId: UUID(), attendanceStatus: 1, createdAt: Date.now, updatedAt: Date.now),
      EventAttendee(id: UUID(), eventId: event.id, profileId: UUID(), attendanceStatus: 1, createdAt: Date.now, updatedAt: Date.now),
      EventAttendee(id: UUID(), eventId: event.id, profileId: UUID(), attendanceStatus: 2, createdAt: Date.now, updatedAt: Date.now),
      EventAttendee(id: UUID(), eventId: event.id, profileId: UUID(), attendanceStatus: 2, createdAt: Date.now, updatedAt: Date.now),
      EventAttendee(id: UUID(), eventId: event.id, profileId: UUID(), attendanceStatus: 2, createdAt: Date.now, updatedAt: Date.now)
    ]
    EventRowView(currentEventAttendee: currentSampleAttendee, event: event, currentUserId: currentSampleUserId, eventAttendees: sampleEventAttendees)
  }
  .environment(AppRouter())
}

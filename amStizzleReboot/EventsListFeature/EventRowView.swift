//
//  ContentView.swift
//  EventRowViewTest
//
//  Created by Mats Wiese on 11.10.25.
//

import os
import Supabase
import SwiftUI

struct EventRowView: View {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(AppRouter.self) private var router
  private let logger = Logger(subsystem: "amStizzleReboot", category: "EventRowView")
  
  let event: Event
  let eventAttendees: [EventAttendee]
  let currentEventAttendee: EventAttendee?
  let onTapAcceptButton: () -> Void
  let onTapDeclineButton: () -> Void
  
  var body: some View {
    VStack {
      ZStack {
        RoundedRectangle(cornerRadius: 60)
          .fill(colorScheme == .dark ? Color.black.opacity(0.9) : Color.white.opacity(0.5))
          .shadow(color: .black.opacity(0.7), radius: 2, x: 2, y: 2)
          .shadow(color: .white.opacity(0.7), radius: 2, x: -2, y: -2)
        
        VStack {
          Button {
            if !router.path.contains(.eventDetail(event: event)) {
              router.push(.eventDetail(event: event))
            }
          } label: {
            titleView
          }
          
          timeSection
          
          HStack {
            if let currentEventAttendee, currentEventAttendee.attendanceStatus == 1 {
              AttendanceView(
                currentEventAttendee: currentEventAttendee,
                eventAttendees: eventAttendees,
                invitationState: .inviteAccepted,
                image: "checkmark.circle.fill",
                text: "amStizzle!"
              )
            } else if let currentEventAttendee, currentEventAttendee.attendanceStatus == 2 {
              AttendanceView(
                currentEventAttendee: currentEventAttendee,
                eventAttendees: eventAttendees,
                invitationState: .inviteDeclined,
                image: "xmark.circle.fill",
                text: "You declined"
              )
            } else {
              ButtonView(buttonType: .refuseButton, image: "xmark", text: "nope, i'm out") {
                onTapAcceptButton()
              }
              ButtonView(buttonType: .attendButton, image: "checkmark", text: "am Stizzle!") {
                onTapDeclineButton()
              }
            }
          }
        }
        .padding()
      }
      .frame(height: 270)
      .containerShape(.rect(cornerRadius: 60))
    }
  }
  
  var titleView: some View {
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
  
  var timeSection: some View {
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
  }
  
//#warning("join Profiles to get usernames")
//  func loadEventAttendees() async {
//    do {
//      let fetchedEventAttendees: [EventAttendee] =
//      try await Supabase.shared
//        .from("event_attendees")
//        .select(
//          """
//            id,
//            event_id,
//            profile_id,
//            profiles ( id, username )
//            attendance_status,
//            created_at,
//            updated_at,
//          
//          """
//        )
////        .eq("profile_id", value: "id")
//        .eq("event_id", value: event.id)
//        .execute()
//        .value
//      
//      logger.info("Event: \(event.title ?? "no event title"), EventAttendeesCount: \(fetchedEventAttendees.count)")
//      logger.info("EventAttendees: \(eventAttendees.count)")
//      
//      self.eventAttendees = fetchedEventAttendees
//      
//    } catch {
//      logger.error("\(error)")
//    }
//  }
  
  func updateAttendanceStatus(to newStatus: Int) async {
//    let previousAttendee = currentEventAttendee
//    let previousEventAttendees = eventAttendees
//    
//    if let currentEventAttendee {
//      let updatedAttendee = EventAttendee(
//        id: currentEventAttendee.id,
//        eventId: currentEventAttendee.eventId,
//        profileId: currentEventAttendee.profileId!,
//        username: currentEventAttendee.username,
//        attendanceStatus: newStatus,
//        createdAt: currentEventAttendee.createdAt,
//        updatedAt: Date.now
//      )
//      self.currentEventAttendee = updatedAttendee
//      replaceAttendee(updatedAttendee)
//    }
//    
//    model.eventsAttendanceStatus = newStatus
//    
//    do {
//      try await Supabase.shared
//        .from("event_attendees")
//        .update(["attendance_status" : newStatus])
//        .eq("profile_id", value: currentUserId)
//        .eq("event_id", value: event.id)
//        .execute()
//      logger.info("AttendanceStatus set to \(newStatus)")
//      
//      await model.loadCurrentAttendee()
//      await loadEventAttendees()
//    } catch {
//      logger.error("\(error.localizedDescription)")
//      currentEventAttendee = previousAttendee
//      eventAttendees = previousEventAttendees
//      model.eventsAttendanceStatus = previousAttendee?.attendanceStatus ?? -1
//    }
  }
  
  private func replaceAttendee(_ updatedAttendee: EventAttendee) {
//    if let index = eventAttendees.firstIndex(where: { $0.id == updatedAttendee.id }) {
//      eventAttendees[index] = updatedAttendee
//    } else {
//      eventAttendees.append(updatedAttendee)
//    }
  }
}

struct ButtonView: View {
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
  let action: () async -> Void
  
  var body: some View {
    Button {
      Task {
        await action()
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
  
  @State private var showAttendeeList = false
  
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
        if showAttendeeList {
          VStack(alignment: .leading) {
            Text("Attending:")
            ForEach(eventAttendees.filter { $0.attendanceStatus == 1 }) { attendee in
              Text(attendee.username ?? "0")
            }
            Text("Not Attending:")
            
            ForEach(eventAttendees.filter { $0.attendanceStatus == 2 }) { attendee in
              Text(attendee.username ?? "0")
            }
            Text("Invited:")
            HStack {
              ForEach(eventAttendees.filter { $0.attendanceStatus == 0 }) { attendee in
                Text(attendee.username ?? "0")
              }
            }
          }
        } else {
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
                .foregroundStyle(attendee.username == currentEventAttendee.username ? Color.orange : Color.primary)
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
                .foregroundStyle(attendee.username == currentEventAttendee.username ? Color.mint : Color.primary)
                .font(.title2)
                .fontWeight(.bold)
                .shadow(color: .black.opacity(0.7), radius: 1, x: 1, y: 1)
                .shadow(color: .white.opacity(0.7), radius: 1, x: -1, y: -1)
            }
          }
        }
      }
      .onTapGesture {
        showAttendeeList.toggle()
      }
      .padding()
    }
  }
}

//#Preview {
//  NavigationStack {
//    let currentSampleUserId = UUID()
//    let currentSampleAttendee = EventAttendee(id: UUID(), eventId: UUID(), username: "Tom", attendanceStatus: 2, createdAt: Date.now, updatedAt: Date.now)
//    let event = Event(id: UUID(), title: "Test", details: nil, startDate: Date.now, endDate: Date.now + 3600, createdAt: Date.now, updatedAt: Date.now, creatorId: currentSampleUserId)
//    let sampleEventAttendees = [
//      currentSampleAttendee,
//      EventAttendee(id: UUID(), eventId: event.id, profileId: UUID(), attendanceStatus: 1, createdAt: Date.now, updatedAt: Date.now),
//      EventAttendee(id: UUID(), eventId: event.id, profileId: UUID(), attendanceStatus: 1, createdAt: Date.now, updatedAt: Date.now),
//      EventAttendee(id: UUID(), eventId: event.id, profileId: UUID(), attendanceStatus: 1, createdAt: Date.now, updatedAt: Date.now),
//      EventAttendee(id: UUID(), eventId: event.id, profileId: UUID(), attendanceStatus: 2, createdAt: Date.now, updatedAt: Date.now),
//      EventAttendee(id: UUID(), eventId: event.id, profileId: UUID(), attendanceStatus: 2, createdAt: Date.now, updatedAt: Date.now),
//      EventAttendee(id: UUID(), eventId: event.id, profileId: UUID(), attendanceStatus: 2, createdAt: Date.now, updatedAt: Date.now)
//    ]
//    EventRowView(currentEventAttendee: currentSampleAttendee, event: event, currentUserId: currentSampleUserId, eventAttendees: sampleEventAttendees)
//  }
//  .environment(AppRouter())
//}

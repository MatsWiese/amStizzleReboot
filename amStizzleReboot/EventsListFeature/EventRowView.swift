
//
//  ContentView.swift
//  EventRowViewTest
//
//  Created by Mats Wiese on 11.10.25.
//

import os
import Supabase
import SwiftUI

//@Observable class EventRowModel {
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
//}

struct EventRowView: View {
  @Environment(\.colorScheme) var colorScheme
//  @State var model: EventDetailModel
//  let attendingUserNames: [String]
//  @State var currentUser: EventAttendee
  let event: Event
  let currentUserId: UUID
//  let groupColor: Color
//  let onDetailTapped: () -> Void
  
  var body: some View {
    VStack {
      ZStack {
        RoundedRectangle(cornerRadius: 60)
          .fill(colorScheme == .dark ? Color.black.opacity(0.9) : Color.white.opacity(0.5))
          .shadow(color: .black.opacity(0.7), radius: 2, x: 2, y: 2)
          .shadow(color: .white.opacity(0.7), radius: 2, x: -2, y: -2)
        
        
        VStack {
          //        NavigationLink {
          TitleView
          
          TimeSection
          //        }
          
//          if event.attendees.contains(user.id) || event.notParticipating.contains(user.id) {
//            AttendeesView
//          } else {
            HStack {
              ButtonView(event: event, userId: currentUserId, buttonType: .refuseButton, image: "xmark", text: "nope, i'm out")
              ButtonView(event: event, userId: currentUserId, buttonType: .attendButton, image: "checkmark", text: "am Stizzle!")
//            }
          }
        }
        .padding()
      }
      .frame(height: 300)
      .containerShape(.rect(cornerRadius: 60))
    }
//    .padding()
  }
  
  var TitleView: some View {
    ZStack(alignment: .bottomLeading) {
      ConcentricRectangle()
        .fill(Color.blue.opacity(0.5))
        .shadow(color: .black.opacity(0.7), radius: 2, x: 2, y: 2)
        .shadow(color: .white.opacity(0.7), radius: 2, x: -2, y: -2)
      Text(event.title ?? "Unknown")
        .minimumScaleFactor(0.5)
        .foregroundStyle(Color.primary)
        .font(.largeTitle)
        .fontWeight(.bold)
        .padding()
        .shadow(color: .black.opacity(0.7), radius: 1, x: 1, y: 1)
        .shadow(color: .white.opacity(0.7), radius: 1, x: -1, y: -1)
    }
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
        //          .fontWidth(.condensed)
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
//                  .frame(maxWidth: .infinity)
//          .border(.orange, width: 1)
          .fontWeight(.black)
        }
//        .border(.purple, width: 1)
        .font(.title2)
      }
      .shadow(color: .black.opacity(0.7), radius: 1, x: 1, y: 1)
      .shadow(color: .white.opacity(0.7), radius: 1, x: -1, y: -1)
      .padding()
    }
//    .padding(.vertical, 6)
  }
//  var AttendeesView: some View {
//    ZStack(alignment: .topLeading) {
//      ConcentricRectangle()
//        .fill(event.attendees.contains(user.id) ? Color.green.opacity(0.4) : Color.red.opacity(0.4))
//        .frame(minHeight: 90)
//        .shadow(color: .black.opacity(0.7), radius: 2, x: 2, y: 2)
//        .shadow(color: .white.opacity(0.7), radius: 2, x: -2, y: -2)
//      VStack(alignment: .leading) {
//        HStack {
//          Text("Attendees:")
//            .font(.headline)
//          ForEach(event.attendees, id: \.self) { _ in
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
//          }
//        }
//        HStack {
//          Text("Not attending:")
//            .font(.headline)
//          ForEach(event.notParticipating, id: \.self) { _ in
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
//          }
//        }
//      }
//      .shadow(color: .black.opacity(0.7), radius: 1, x: 1, y: 1)
//      .shadow(color: .white.opacity(0.7), radius: 1, x: -1, y: -1)
//      .padding()
//    }
//  }
//  func loadCurrentAttendee() async {
//    do {
//      let currentUser = try await Supabase.shared.auth.session.user
//      
////      let currentEventAttendee: EventAttendee =
////      try await Supabase.shared
////        .from("event_attendees")
////        .select()
////        .eq("profile_id", value: currentUser.id)
////        .single()
////        .execute()
////        .value
////      
//////      logger.info("MyEventsCount: \(usersFetchedEvents.count)")
////      
////      currentEventAttendee
////      await loadInvitedEvents()
//    } catch {
//      logger.error("\(error)")
//    }
//  }
}


struct ButtonView: View {
  let logger = Logger(subsystem: "amStizzleReboot", category: "EventRowView")
  
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
  
  let attendColor: Color = .green.opacity(0.6)
  let refuseColor: Color = .red.opacity(0.6)
  
  var body: some View {
    Button {
      switch buttonType {
      case .attendButton:
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
        }
//        event.attendees.append(user.id)
//        print("attending: \(event.attendees)")
//        return /*remove after commenting in*/
        
      case .refuseButton:
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
        }
//        event.notParticipating.append(user.id)
//        print("notParticipating: \(event.notParticipating)")
        return /*remove after commenting in*/
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
      .frame(minHeight: 90)
      .shadow(color: .black.opacity(0.7), radius: 2, x: 2, y: 2)
      .shadow(color: .white.opacity(0.7), radius: 2, x: -2, y: -2)
    }
  }
}

#Preview {
  NavigationStack {
    let currentSampleUserId = UUID()
    let event = Event(id: UUID(), title: "Test", details: nil, startDate: Date.now, endDate: Date.now + 3600, createdAt: Date.now, updatedAt: Date.now, creatorId: currentSampleUserId)
    EventRowView(event: event, currentUserId: currentSampleUserId)
  }
}


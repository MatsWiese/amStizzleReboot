////
////  ContentView.swift
////  EventRowViewTest
////
////  Created by Mats Wiese on 11.10.25.
////
//
import os
import Supabase
import SwiftUI

struct EventRowView: View {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(AppRouter.self) private var router
  private let logger = Logger(subsystem: "amStizzleReboot", category: "EventRowView")
  @State private var isShowingTimeframeOverlay = false
  @State private var draftStartDate = Date.now
  @State private var draftEndDate = Date.now.addingTimeInterval(3600)
  
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
                onTapDeclineButton()
              }
              ButtonView(buttonType: .attendButton, image: "checkmark", text: "am Stizzle!") {
                onTapAcceptButton()
              }
            }
          }
        }
        .padding()
      }
      .frame(height: 270)
      .containerShape(.rect(cornerRadius: 60))
    }
    .onAppear {
        syncTimeframeDraft()
        logger.info("EventRowView(onAppear) - CurrentEventAttendeeID: \(currentEventAttendee?.profileId?.uuidString ?? "No EventAttendee")")
    }
    .overlay {
      if isShowingTimeframeOverlay {
        ZStack {
          Color.black.opacity(0.35)
            .ignoresSafeArea()
            .onTapGesture {
              isShowingTimeframeOverlay = false
            }

          VStack(alignment: .trailing, spacing: 12) {
            Button("Done") {
              isShowingTimeframeOverlay = false
            }
            .font(.headline)

            EventTimeframeView(startTime: $draftStartDate, endTime: $draftEndDate)
          }
          .padding(20)
          .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
          .padding(.horizontal, 24)
        }
      }
    }
  }
    
    var titleView: some View {
      ZStack(alignment: .bottomLeading) {
        ConcentricRectangle()
          .fill(Color.blue.opacity(0.5))
          .shadow(color: .black.opacity(0.7), radius: 2, x: 2, y: 2)
          .shadow(color: .white.opacity(0.7), radius: 2, x: -2, y: -2)
        Text(event.title ?? "Unknown Title")
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
    Button {
      if currentEventAttendee?.profileId == event.creatorId {
        syncTimeframeDraft()
        isShowingTimeframeOverlay = true
      }
    } label: {
      ZStack(alignment: .leading) {
        Rectangle()
          .fill(Color.gray.opacity(0.2))
          .shadow(color: .black.opacity(0.7), radius: 2, x: 2, y: 2)
          .shadow(color: .white.opacity(0.7), radius: 2, x: -2, y: -2)
        HStack {
          VStack(alignment: .leading) {
            Text(event.startDate?
              .formatted(date: .abbreviated, time: .omitted) ?? "N/A")
            .minimumScaleFactor(0.5)
            .font(.title)
            .fontWeight(.bold)
            .fontDesign(.rounded)
            .foregroundStyle(Color.primary)
            
            if let startDate = event.startDate,
               let endDate = event.endDate,
               !Calendar.current.isDate(startDate, inSameDayAs: endDate) {
              HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text("until")
                  .minimumScaleFactor(0.5)
                  .font(.caption2)
                  .foregroundStyle(Color.primary)
                Text(endDate.formatted(date: .abbreviated, time: .omitted))
                  .minimumScaleFactor(0.5)
                  .font(.title)
                  .fontWeight(.bold)
                  .fontDesign(.rounded)
                  .foregroundStyle(Color.primary)
              }
            }
          }
          Spacer()
          HStack {
            VStack(alignment: .trailing) {
              Text("From:")
              Text("to:")
            }
            .font(.headline)
            .fontDesign(.monospaced)
            
            VStack(alignment: .leading) {
              Text(event.startDate?.formatted(date: .omitted, time: .shortened) ?? "N/A")
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
    .buttonStyle(.plain)
//    .disabled(!canEditTimeframe)
  }

  private func syncTimeframeDraft() {
    let startDate = event.startDate ?? Date.now
    draftStartDate = startDate
    draftEndDate = event.endDate ?? startDate.addingTimeInterval(3600)
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
//
struct AttendanceView: View {
  private let logger = Logger(subsystem: "amStizzleReboot", category: "AttendanceView")
  
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
            if (eventAttendees.filter { $0.attendanceStatus == 2 }).count > 0 {
              Text("Not Attending:")
                .font(.caption)
              ForEach(eventAttendees.filter { $0.attendanceStatus == 2 }) { attendee in
                if attendee.id == currentEventAttendee.id {
                  HStack {
                    Text(attendee.username ?? "N/A")
                    Spacer()
                    Button {
                      // TODO: Accept-Logic
                    } label: {
                      ZStack {
                        RoundedRectangle(cornerRadius: 8)
                          .fill(.green)
                        Image(systemName: "checkmark")
                          .font(.body)
                          .fontWeight(.heavy)
                      }
                      .frame(width: 40)
                      .foregroundStyle(.white)
                    }
                    .padding(.trailing, 10)
                    //                    .buttonStyle(.bordered)
                    .buttonBorderShape(.roundedRectangle)
                    
                  }
                } else {
                  Text(attendee.username ?? "N/A")
                }
                
                //                Text(attendee.username ?? "0")
              }
            }
            if (eventAttendees.filter { $0.attendanceStatus == 0 }).count > 0 {
              Text("Invited:")
                .font(.caption)
              HStack {
                ForEach(eventAttendees.filter { $0.attendanceStatus == 0 }) { attendee in
                  Text(attendee.username ?? "N/A")
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
                    .foregroundStyle(attendee.id == currentEventAttendee.profileId ? Color.orange : Color.primary)
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
                    .foregroundStyle(attendee.id == currentEventAttendee.profileId ? Color.mint : Color.primary)
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
  }
}
//
//#Preview {
//  NavigationStack {
//    let currentSampleUserId = UUID()
//    let sampleOnTapAcceptButton: () -> Void
//    let sampleOnTapDeclineButton: () -> Void
//    let sampleCurrentEventAttendee = EventAttendee(id: UUID(), eventId: UUID(), profileId: UUID(), username: "Tom", attendanceStatus: 2, createdAt: Date.now, updatedAt: Date.now)
//    let sampleEvent = Event(id: UUID(), title: "Test", details: nil, startDate: Date.now, endDate: Date.now + 3600, createdAt: Date.now, updatedAt: Date.now, creatorId: currentSampleUserId)
//    let sampleEventAttendees = [
//      sampleCurrentEventAttendee,
//      EventAttendee(id: UUID(), eventId: sampleEvent.id, profileId: UUID(), username: "Egon", attendanceStatus: 1, createdAt: Date.now, updatedAt: Date.now),
//      EventAttendee(id: UUID(), eventId: sampleEvent.id, profileId: UUID(), username: "Erwin", attendanceStatus: 1, createdAt: Date.now, updatedAt: Date.now),
//      EventAttendee(id: UUID(), eventId: sampleEvent.id, profileId: UUID(), username: "Erna", attendanceStatus: 1, createdAt: Date.now, updatedAt: Date.now),
//      EventAttendee(id: UUID(), eventId: sampleEvent.id, profileId: UUID(), username: "Klaus", attendanceStatus: 2, createdAt: Date.now, updatedAt: Date.now),
//      EventAttendee(id: UUID(), eventId: sampleEvent.id, profileId: UUID(), username: "Hagen", attendanceStatus: 2, createdAt: Date.now, updatedAt: Date.now),
//      EventAttendee(id: UUID(), eventId: sampleEvent.id, profileId: UUID(), username: "Josef", attendanceStatus: 2, createdAt: Date.now, updatedAt: Date.now)
//    ]
//    EventRowView(event: sampleEvent, eventAttendees: sampleEventAttendees, currentEventAttendee: sampleCurrentEventAttendee, onTapAcceptButton: {}, onTapDeclineButton: {})
//  }
//  .environment(AppRouter())
//}

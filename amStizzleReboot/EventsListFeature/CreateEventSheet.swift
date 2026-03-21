//
//  CreateEventSheet.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 26.02.26.
//

import os
import SwiftUI
import Supabase

@Observable class CreateEventModel {
//  @ObservationIgnored @Dependency(\.defaultDatabase) var database
  let logger = Logger(subsystem: "amStizzleReboot", category: "CreateEventModel")
  
//  @ObservationIgnored @AppStorage("selectedUserID") var currentUserIDString: String = ""
//  
//  private var currentUserUUID: UUID {
//    UUID(uuidString: currentUserIDString)
//    ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
//  }
//  var event: Event
  var event = Event(id: UUID(), title: "", details: "", startDate: Date.now, endDate: Date.now + 3600, createdAt: Date.now, updatedAt: Date.now, creatorId: UUID())
  
  var currentProfileId: UUID?
  
  var newEventTitle = ""
  var newEventDetails = ""
  var eventBegin = Date()
  var eventEnd = Date() + 3600
  
  func saveEventButtonTapped() {
    Task {
      do {
        event = Event(id: UUID(), title: newEventTitle, details: newEventDetails, startDate: eventBegin, endDate: eventEnd, createdAt: Date.now, updatedAt: Date.now, creatorId: currentProfileId)
        
        let eventAttendee = EventAttendee(id: UUID(), createdAt: Date.now, updatedAt: Date.now, eventId: event.id, profileId: currentProfileId!, attendanceStatus: 0)
        
        try await Supabase.shared
          .from("events")
          .insert(event)
          .eq("creator_id", value: currentProfileId)
          .execute()
        
        try await Supabase.shared
          .from("event_attendees")
          .insert(eventAttendee)
          .eq("profile_id", value: currentProfileId)
          .execute()
        
      } catch {
        logger.error("\(error.localizedDescription)")
      }
    }
  }
//    withErrorReporting {
//      try database.write { db in
//        event.title = newEventTitle
//        event.startDate = eventBegin
//        event.endDate = eventEnd
//        event.creatorId = currentUserUUID
//        
//        try Event
//          .upsert { event }
//          .execute(db)
//        
//        
//#warning("Creating user gets upserted two times when using NavLink to AttendeeManagerSheet")
//        try EventAttendee
//          .upsert { EventAttendee(id: currentUserUUID, eventId: event.id, userId: UUID(uuidString: currentUserIDString)! /* ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000"))!*/, status: .invited) }
//          .execute(db)
//      }
//    }
//  }
}

struct CreateEventSheet: View {
  @Environment(\.dismiss) var dismiss
  
  @State var model = CreateEventModel()
  @State private var path: [Destination] = []
  
//  init() {
//    _model = State(wrappedValue: CreateEventModel())
//  }
  
  var body: some View {
    NavigationStack(path: $path) {
      Form {
        Section {
          TextField("Event title", text: $model.newEventTitle)
            .autocorrectionDisabled()
          //            .onSubmit {
          //              model.saveEventButtonTapped()
          //            }
          DatePicker("Event Begin", selection: $model.eventBegin, displayedComponents: [.date, .hourAndMinute])
          DatePicker("Event ends", selection: $model.eventEnd, displayedComponents: [.date, .hourAndMinute])
        }
        
#warning("Navlink upserts event. not best solution I guess")
//                NavigationLink(destination: AttendeeManagerSheet(event: model.event)) {
//                  Text("Manage Attendees")
//                }
        //        .simultaneousGesture(TapGesture().onEnded {
        //          model.saveEventButtonTapped()
        //          print("saved saved saved")
//                } )
        Button {
//          model.saveEventButtonTapped()
          path.append(.attendeeManager(event: model.event))
        } label: {
          HStack {
            Text("Manage attendees")
              .frame(maxWidth: .infinity)
            Image(systemName: "chevron.right")
          }
        }
        .disabled(model.newEventTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
      .navigationDestination(for: Destination.self, destination: \.view)
    }
    .navigationTitle("New Event")
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") { dismiss() }
      }
      ToolbarItem(placement: .confirmationAction) {
        Button("Save") {
          model.saveEventButtonTapped()
          dismiss()
        }
        .disabled(model.newEventTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
    }
    .task {
      await getInitialProfile()
    }
  }
  func getInitialProfile() async {
    do {
      let currentUser = try await Supabase.shared.auth.session.user
      
      model.logger.info("Current user: \(currentUser.id)")
      
      model.currentProfileId = currentUser.id
//      let profile: Profile =
//      try await Supabase.shared
//        .from("profiles")
//        .select()
//        .eq("id", value: currentUser.id)
//        .single()
//        .execute()
//        .value
      
//      model.logger.info("\(profile.firstName!)")
//      model.logger.info("\(profile.lastName!)")
//      model.logger.info("\(profile.username!)")
      
//      if let avatarURL = profile.avatarURL, !avatarURL.isEmpty {
//        try await downloadImage(path: avatarURL)
//      }
      
    } catch {
      model.logger.error("\(error)")
    }
  }
}

//#Preview {
//  CreateEventSheet()
//}

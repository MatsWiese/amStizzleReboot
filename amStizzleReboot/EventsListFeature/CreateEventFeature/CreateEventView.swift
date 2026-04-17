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
    event = Event(id: self.event.id, title: newEventTitle, details: newEventDetails, startDate: eventBegin, endDate: eventEnd, createdAt: self.event.createdAt, updatedAt: Date.now, creatorId: currentProfileId)
    
    let eventAttendee = EventAttendee(id: UUID(), eventId: event.id, profileId: currentProfileId!, username: nil, attendanceStatus: 0, createdAt: Date.now, updatedAt: Date.now)
    
    Task {
      do {
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
  
  func cancelButtonTapped() {
    Task {
      do {
        try await Supabase.shared
          .from("events")
          .delete()
          .eq("id", value: self.event.id)
          .execute()
        
        logger.info("Event \(self.event.title ?? "N/A") deleted")
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

struct CreateEventView: View {
  @Environment(\.dismiss) var dismiss
  @Environment(AppRouter.self) private var router
  @State var model = CreateEventModel()
  
  //  init() {
  //    _model = State(wrappedValue: CreateEventModel())
  //  }
  
  var body: some View {
    //    NavigationStack {
    VStack {
      //      Form {
      //        Section {
      TextField("Event title", text: $model.newEventTitle)
        .font(.title)
        .textFieldStyle(.roundedBorder)
        .autocorrectionDisabled()
      //            .onSubmit {
      //              model.saveEventButtonTapped()
      //            }
      //    }
      EventTimeframeView(startTime: $model.eventBegin, endTime: $model.eventEnd)
      
      Button {
        model.saveEventButtonTapped()
        router.push(.attendeeManager(event: model.event))
      } label: {
        HStack {
          Text("Manage attendees")
            .frame(maxWidth: .infinity)
          Image(systemName: "chevron.right")
        }
        .font(.title2)
      }
      .buttonStyle(.borderedProminent)
      .disabled(model.newEventTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      
      Spacer()
    }
    .navigationDestination(for: Destination.self, destination: \.view)
    //    }
    .navigationTitle("New Event")
    .navigationBarTitleDisplayMode(.inline)
    .navigationBarBackButtonHidden()
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") {
          model.cancelButtonTapped()
          dismiss()
        }
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
    
    //    .environment(router)
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

#Preview {
  NavigationStack {
    CreateEventView()
  }
  .environment(AppRouter())
}

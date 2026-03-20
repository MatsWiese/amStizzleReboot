//
//  AttendeeManagerSheet.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 01.03.26.
//
//
import os
import SwiftUI
import Supabase

@Observable class AttendeeManagerModel {
//  @ObservationIgnored @Dependency(\.defaultDatabase) var database
  let logger = Logger(subsystem: "amStizzleReboot", category: "AttendeeManagerModel")
  
//  @ObservationIgnored @AppStorage("selectedUserID") var currentUserIDString: String = ""

//  private var currentUserUUID: UUID {
//    UUID(uuidString: currentUserIDString)
//    ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
//  }
  var allProfiles: [Profile] = []
  var eventAttendees: [EventAttendee] = []
//  var currentProfile: Profile
  
  let event: Event
//  var isNewUserAlertPresented = false
//  var newUserFirstName = ""
//  var newUserLastName = ""
  var sortForAttendance = false {
    didSet {
      Task { await reloadUsersData() }
    }
  }
//  @ObservationIgnored @FetchAll(User.none) var users
//  @ObservationIgnored @FetchAll(EventAttendee.none) var eventAttendees
  
  init(event: Event) {
    self.event = event
  }
  
  
  
//  func addUserButtonTapped() {
//    newUserFirstName = ""
//    newUserLastName = ""
//    isNewUserAlertPresented = true
//  }
  
  func delete(at offset: IndexSet) async {
      let oldProfiles = allProfiles

      do {
        let profilesToDelete = offset.map { oldProfiles[$0] }

        allProfiles.remove(atOffsets: offset)

        try await Supabase.shared.from("profiles")
          .delete()
          .in("id", values: profilesToDelete.map(\.id))
          .execute()
      } catch {
        logger.error("\(error.localizedDescription)")

        // rollback todos on error.
        allProfiles = oldProfiles
      }
    }
  
//    withErrorReporting {
//      try database.write { db in
//        try User.find(offsets.map { users[$0].id })
//          .delete()
//          .execute(db)
//      }
//    }
//  }
  
  #warning("deleting eventAttendees is not working.")
  func addOrRemoveAsAttendee(for profile: Profile) {
    if eventAttendees.contains(where: { $0.profileID == profile.id }) {
      logger.info("%%% user is already registered for the event. Trying to delete attendee.")
      Task {
        do {
          try await Supabase.shared
            .from("event_attendees")
            .delete()
            .eq("profile_id", value: profile.id)
            .execute()
        } catch {
          logger.error("\(error.localizedDescription)")
        }
      }
//      withErrorReporting {
//        try database.write { db in
//          try EventAttendee
//            .where { $0.userId.eq(user.id)/* && $0.eventId.eq(event.id)*/ }
//            .delete()
//            .execute(db)
//        }
//        logger.info("%%% eventAttendee deleted")
//      }
    } else {
      Task {
        do {
          logger.info("trying to insert new eventAttendee")
          let eventAttendee = EventAttendee(id: UUID(), createdAt: Date.now, updatedAt: Date.now, eventId: event.id, profileID: profile.id, attendanceStatus: 0)
          
          try await Supabase.shared
            .from("event_attendees")
            .insert(eventAttendee)
            .eq("profile_id", value: eventAttendee.profileID)
            .eq("event_id", value: eventAttendee.eventId )
            .execute()
        } catch {
          logger.error("\(error.localizedDescription)")
        }
      }
//      withErrorReporting {
//        try database.write { db in
//          try EventAttendee.insert { EventAttendee.Draft(eventId: event.id, userId: user.id, status: .invited) }
//            .execute(db)
//        }
      }
//      logger.info(">>>>> eventAttendee inserted")
//    }
  }
  
  func saveNewUserButtonTapped() {
//    withErrorReporting {
//      try database.write { db in
//        try User.insert { User.Draft(firstName: newUserFirstName, lastName: newUserLastName)
//        }
//        .execute(db)
//      }
//    }
//    logger.info(">>>>> new User inserted")
  }
  
//  func toggleSortingButtonTapped() {
//    sortForAttendance.toggle()
//  }
  
  func reloadUsersData() async {
    do {
      let allFetchedProfiles: [Profile] =
      try await Supabase.shared
        .from("profiles")
        .select()
//        .eq("profile_id", value: currentUser.id)
        .execute()
        .value
      
      logger.info("AllEventsCount: \(allFetchedProfiles.count)")
      
      allProfiles = allFetchedProfiles
      
    } catch {
      logger.error("\(error)")
    }
    
    do {
      let fetchedEventAttendees: [EventAttendee] =
      try await Supabase.shared
        .from("event_attendees")
        .select()
//        .eq("profile_id", value: $0.id)
        .eq("event_id", value: event.id)
        .execute()
        .value
      
      logger.info("EventAttendeesCount: \(fetchedEventAttendees.count)")
      
      eventAttendees = fetchedEventAttendees
      
    } catch {
      logger.error("\(error)")
    }
//    func reloadCurrentUserData() async {
//      do {
//        let fetchedCurrentProfile = try await Supabase.shared.auth.session.user
//        
//        logger.info("Current user: \(fetchedCurrentProfile.id)")
//        
//        let fetchedProfile: Profile =
//        try await Supabase.shared
//          .from("profiles")
//          .select()
//          .eq("id", value: fetchedCurrentProfile.id)
//          .single()
//          .execute()
//          .value
//        
//        currentProfile = fetchedProfile
//        
//      } catch {
//        logger.error("\(error)")
//      }
//    }
  }
  
  func reloadAttendeeData() async {
    
//    await withErrorReporting {
//      _ = try await $eventAttendees.load(
//        EventAttendee
//          .where { $0.eventId.eq(event.id) }
//        , animation: .default
//      )
//    }
  }
  
  func task() async {
    await reloadUsersData()
//    await reloadAttendeeData()
  }
}

struct AttendeeManagerSheet: View {
  let logger = Logger(subsystem: "amStizzleReboot", category: "AttendeeManagerSheet")
  
  @State var model: AttendeeManagerModel
  init(event: Event) {
    _model = State(wrappedValue: AttendeeManagerModel(event: event))
  }
  
//  @FetchAll
//  var eventAttendees: [EventAttendee]
  
  var body: some View {
    List {
#if DEBUG
      Section("passed Eventtitle and id") {
        Text(model.event.title ?? "EventTitle")
        Text("eventId: \(model.event.id)")
          .font(.footnote )
      }
#endif
      Section {
        if /*!model.$users.isLoading,*/ model.allProfiles.isEmpty {
          ContentUnavailableView {
            Label("No users", systemImage: "person.3.fill")
          } description: {
            Button("Add user") { /*model.addUserButtonTapped()*/ }
          }
        }
        ForEach(model.allProfiles, id: \.id) { profile in
          HStack {
            Text(profile.username ?? "Unknown user")
            Spacer()
            Button {
              model.addOrRemoveAsAttendee(for: profile)
            } label: {
              Image(systemName: model.eventAttendees.contains(where: { $0.profileID == profile.id }) ? "checkmark" : "plus")
            }
          }
        }
        .onDelete { indexSet in
          Task {
            await model.delete(at: indexSet)
          }
        }
        
      } header: {
        HStack {
          Text("Invite users")
          Spacer()
          Button {
#warning("sort for Attendance not yet working")
//            model.toggleSortingButtonTapped()
          } label: {
            Image(systemName: model.sortForAttendance ? "person.checkmark.and.xmark" : "arrow.down")
          }
        }
      }
    }
      .navigationBarTitle("Manage Users")
      .toolbar {
        ToolbarItem {
          Button {
//            model.addUserButtonTapped()
          } label: {
            Image(systemName: "plus")
          }
//          .alert("New User", isPresented: $model.isNewUserAlertPresented) {
//            TextField("First name", text: $model.newUserFirstName)
//            TextField("Last name", text: $model.newUserLastName)
//            Button("Save") { model.saveNewUserButtonTapped() }
//            Button("Cancel", role: .cancel) { }
//          }
        }
      }
      .task {
        await model.task()
      }
  }
}

//#Preview {
//  let event = prepareDependencies {
//    try! $0.bootstrapDatabase()
//    try! $0.defaultDatabase.seed()
//    return try! $0.defaultDatabase.read { db in
//      try Event.fetchOne(db)!
//    }
//  }
//  NavigationStack {
//    AttendeeManagerSheet(event: event)
//  }
//}

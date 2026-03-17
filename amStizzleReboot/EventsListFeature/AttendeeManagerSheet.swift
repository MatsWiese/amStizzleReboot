////
////  AttendeeManagerSheet.swift
////  amStizzleReboot
////
////  Created by Fred Erik on 01.03.26.
////
////
//import os
//import SwiftUI
//import SQLiteData
//
//@Observable class AttendeeManagerModel {
//  @ObservationIgnored @Dependency(\.defaultDatabase) var database
//  let logger = Logger(subsystem: "amStizzleReboot", category: "AttendeeManagerModel")
//  
//  @ObservationIgnored @AppStorage("selectedUserID") var currentUserIDString: String = ""
//
//  private var currentUserUUID: UUID {
//    UUID(uuidString: currentUserIDString)
//    ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
//  }
//  
//  let event: Event
//  var isNewUserAlertPresented = false
//  var newUserFirstName = ""
//  var newUserLastName = ""
//  var sortForAttendance = false {
//    didSet {
//      Task { await reloadUsersData() }
//    }
//  }
//  @ObservationIgnored @FetchAll(User.none) var users
//  @ObservationIgnored @FetchAll(EventAttendee.none) var eventAttendees
//  
//  init(event: Event) {
//    self.event = event
//  }
//  
//  func addUserButtonTapped() {
//    newUserFirstName = ""
//    newUserLastName = ""
//    isNewUserAlertPresented = true
//  }
//  
//  func deleteUsers(at offsets: IndexSet) {
//    withErrorReporting {
//      try database.write { db in
//        try User.find(offsets.map { users[$0].id })
//          .delete()
//          .execute(db)
//      }
//    }
//  }
//  
//  func addOrRemoveAsAttendee(for user: User) {
//    if eventAttendees.contains(where: { $0.userId == user.id }) {
//      logger.info("%%% user is already registered for the event")
//      withErrorReporting {
//        try database.write { db in
//          try EventAttendee
//            .where { $0.userId.eq(user.id)/* && $0.eventId.eq(event.id)*/ }
//            .delete()
//            .execute(db)
//        }
//        logger.info("%%% eventAttendee deleted")
//      }
//    } else {
//      withErrorReporting {
//        try database.write { db in
//          try EventAttendee.insert { EventAttendee.Draft(eventId: event.id, userId: user.id, status: .invited) }
//            .execute(db)
//        }
//      }
//      logger.info(">>>>> eventAttendee inserted")
//    }
//  }
//  
//  func saveNewUserButtonTapped() {
//    withErrorReporting {
//      try database.write { db in
//        try User.insert { User.Draft(firstName: newUserFirstName, lastName: newUserLastName)
//        }
//        .execute(db)
//      }
//    }
//    logger.info(">>>>> new User inserted")
//  }
//  
//  func toggleSortingButtonTapped() {
//    sortForAttendance.toggle()
//  }
//  
//  func reloadUsersData() async {
//    await withErrorReporting {
//      _ = try await $users.load(
//        User
//          .where { $0.id.neq(currentUserUUID) }
//          .order {
//            if sortForAttendance {
//              $0.firstName
//            } else {
//              $0.lastName
//            }
//          },
//        animation: .default
//      )
//    }
//  }
//  
//  func reloadAttendeeData() async {
//    await withErrorReporting {
//      _ = try await $eventAttendees.load(
//        EventAttendee
//          .where { $0.eventId.eq(event.id) }
//        , animation: .default
//      )
//    }
//  }
//  
//  func task() async {
//    await reloadUsersData()
//    await reloadAttendeeData()
//  }
//}
//
//struct AttendeeManagerSheet: View {
//  let logger = Logger(subsystem: "amStizzleReboot", category: "AttendeeManagerSheet")
//  
//  @State var model: AttendeeManagerModel
//  init(event: Event) {
//    _model = State(wrappedValue: AttendeeManagerModel(event: event))
//  }
//  
//  @FetchAll
//  var eventAttendees: [EventAttendee]
//  
//  var body: some View {
//    List {
//#if DEBUG
//      Section("passed Eventtitle and id") {
//        Text(model.event.title)
//        Text("eventId: \(model.event.id)")
//          .font(.footnote )
//      }
//#endif
//      Section {
//        if !model.$users.isLoading, model.users.isEmpty {
//          ContentUnavailableView {
//            Label("No users", systemImage: "person.3.fill")
//          } description: {
//            Button("Add user") { model.addUserButtonTapped() }
//          }
//        }
//        ForEach(model.users, id: \.id) { user in
//          HStack {
//            Text(user.firstName)
//            Text(user.lastName)
//            Spacer()
//            Button {
//              model.addOrRemoveAsAttendee(for: user)
//            } label: {
//              Image(systemName: model.eventAttendees.contains(where: { $0.userId == user.id }) ? "checkmark" : "plus")
//            }
//          }
//        }
//        .onDelete { offsets in model.deleteUsers(at: offsets) }
//      } header: {
//        HStack {
//          Text("Invite users")
//          Spacer()
//          Button {
//#warning("sort for Attendance not yet working")
//            model.toggleSortingButtonTapped()
//          } label: {
//            Image(systemName: model.sortForAttendance ? "person.checkmark.and.xmark" : "arrow.down")
//          }
//        }
//      }
//    }
//      .navigationBarTitle("Manage Users")
//      .toolbar {
//        ToolbarItem {
//          Button {
//            model.addUserButtonTapped()
//          } label: {
//            Image(systemName: "plus")
//          }
//          .alert("New User", isPresented: $model.isNewUserAlertPresented) {
//            TextField("First name", text: $model.newUserFirstName)
//            TextField("Last name", text: $model.newUserLastName)
//            Button("Save") { model.saveNewUserButtonTapped() }
//            Button("Cancel", role: .cancel) { }
//          }
//        }
//      }
//      .task {
//        await model.task()
//      }
//  }
//}
//
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

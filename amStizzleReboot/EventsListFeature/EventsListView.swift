//
//  EventsListView.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 18.12.25.
//

//import SQLiteData
import os
import SwiftUI
import Supabase

struct EventsListView: View {
  let logger = Logger(subsystem: "amStizzleReboot", category: "EventsListView")
  
  @State var avatarImage: AvatarImage?
//  @Selection struct EventRow {
//    let event: Event
//    let attendeeCount: Int
//  }
  
//  @ObservationIgnored @AppStorage("selectedUserID") var currentUserIDString: String = ""
//  
//  private var currentUserUUID: UUID {
//    UUID(uuidString: currentUserIDString)
//    ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
//  }
  
//  @State private var eventRows: [EventRow] = []
    @State private var userEvents: [Event] = []
    @State private var allEvents: [Event] = []
  
//  @ObservationIgnored @FetchAll/*(Event.none)*/ var allEvents: [Event]
  
  @State var isNewEventSheetPresented = false
  
  @State var showAccountSheet = false
  
//  @Dependency(\.defaultDatabase) var database
  
  var body: some View {
    NavigationStack {
      VStack {
        List {
          Section("My Events") {
            ForEach(userEvents, id: \.id) { event in
              NavigationLink {
                EventDetailView(event: event)
              } label: {
                HStack {
                  VStack(alignment: .leading) {
                    Text(event.title ?? "")
                      .font(.headline)
                    HStack {
                      Text(event.startDate!.formatted(date: .abbreviated, time: .omitted))
                      
                      let duration = DateInterval(start: event.startDate!, end: event.endDate!)
                      Text(duration)
                    }
                    Text(event.id.uuidString)
                      .font(.caption2)
                  }
                  Spacer()
                  //                HStack {
                  //                  if row.attendeeCount == 1 {
                  //                    Image(systemName: "person")
                  //                  } else if row.attendeeCount == 2 {
                  //                    Image(systemName: "person.2")
                  //                  } else if row.attendeeCount == 3 {
                  //                    Image(systemName: "person.3")
                  //                  } else if row.attendeeCount > 3 {
                  //                    Text("\(row.attendeeCount)")
                  //                    Image(systemName: "person.3")
                  //                  }
                  //                }
                }
              }
            }
            //          .onDelete { offsets in
            //            withErrorReporting {
            //              try database.write { db in
            //                try Event.find(offsets.map { eventRows[$0].event.id })
            //                  .delete()
            //                  .execute(db)
            //              }
            //            }
            //            loadRows()
            //          }
          }
          Section("All Events") {
            ForEach(allEvents, id: \.id) { event in
              VStack(alignment: .leading) {
                Text(event.title ?? "")
                  .font(.headline)
                HStack {
                  Text(event.startDate!.formatted(date: .abbreviated, time: .omitted))
                  
                  let duration = DateInterval(start: event.startDate ?? Date.now, end: event.endDate ?? Date.now + 60)
                  Text(duration)
                }
                Text(event.id.uuidString)
                  .font(.caption2)
              }
            }
//                    .onDelete { offsets in
//                      withErrorReporting {
//                        try database.write { db in
//                          try Event.find(offsets.map { allEvents[$0].id })
//                            .delete()
//                            .execute(db)
//                        }
//                      }
//                      loadRows()
//                    }
                  }
        }
      }
        .navigationTitle("Events")
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Button {
//              newEventTitle = ""
              isNewEventSheetPresented = true
            } label: {
              Label("Add Event", systemImage: "plus")
            }
          }
          ToolbarItem(placement: .topBarLeading) {
            Button {
              showAccountSheet = true
            } label: {
              if let avatarImage {
                ZStack {
                  avatarImage.image
                    .resizable()
                    .scaledToFit()
                    .clipShape(Circle())
                }
              } else {
                Image(systemName: "person")
              }
            }
          }
        }
        //      .task(id: currentUserIDString) {
        //        loadRows()
        //      }
        .task {
          await initialLoading()
        }
        .sheet(isPresented: $isNewEventSheetPresented) {
          NavigationStack {
            CreateEventSheet()
          }
        }
        .sheet(isPresented: $showAccountSheet) {
          NavigationStack {
            ProfileView()
          }
        }
      
    }
  }
  
  func initialLoading() async {
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
      
      logger.info("First Name: \(profile.firstName!)")
      logger.info("Last Name: \(profile.lastName!)")
      logger.info("Username: \(profile.username!)")
      
      if let avatarURL = profile.avatarURL, !avatarURL.isEmpty {
        try await downloadImage(path: avatarURL)
      }
      
      let fetchedEvents: [Event] =
      try await Supabase.shared
        .from("events")
        .select()
        .eq("creator_id", value: currentUser.id)
        .execute()
        .value
      
      logger.info("MyEventsCount: \(fetchedEvents.count)")
      
      userEvents = fetchedEvents
      
//      let allFetchedEvents: [Event] =
//      try await Supabase.shared
//        .from("events")
//        .select()
//        .neq("profile_id", value: currentUser.id)
//        .execute()
//        .value
//      
//      logger.info("AllEventsCount: \(allFetchedEvents.count)")
//      
//      allEvents = allFetchedEvents
      await loadEvents()
      
    } catch {
      logger.error("\(error)")
    }
  }
  
  private func loadEvents() async {
    do {
    let currentUser = try await Supabase.shared.auth.session.user

      let allFetchedEvents: [Event] =
      try await Supabase.shared
        .from("events")
        .select()
        .neq("creator_id", value: currentUser.id)
        .execute()
        .value
      
      logger.info("AllEventsCount: \(allFetchedEvents.count)")
      
      allEvents = allFetchedEvents
    } catch {
      logger.error("\(error)")
    }
  }
  
  private func downloadImage(path: String) async throws {
    let data = try await Supabase.shared.storage.from("avatars").download(path: path)
    avatarImage = AvatarImage(data: data)
  }
  
//#warning("Doesn't load Users Events after adding a new one.")
//  private func loadRows() {
//    withErrorReporting {
//      try database.read { db in
//        let invitedEventIds = EventAttendee
//          .where { $0.userId.eq(currentUserUUID) }
//          .select { $0.eventId }
//        
//        let query = Event
//          .leftJoin(EventAttendee.all) { event, attendee in
//            event.id.eq(attendee.eventId)
//            && attendee.status.eq(AttandanceStatus.attending)
//          }
//          .where { event, _ in event.id.in(invitedEventIds) }
//          .group(by: { event, _ in event.id })
//          .select { EventRow.Columns(event: $0, attendeeCount: $1.count()) }
//        
//        eventRows = try query.fetchAll(db)
//      }
//    }
//  }
}

#Preview {
//  let _ = prepareDependencies {
//    try! $0.bootstrapDatabase()
//    try! $0.defaultDatabase.seed()
//  }
  NavigationStack {
    EventsListView()
  }
}

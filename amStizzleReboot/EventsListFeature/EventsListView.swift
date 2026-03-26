//
//  EventsListView.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 18.12.25.
//

import os
import SwiftUI
import Supabase

struct EventsListView: View {
  let logger = Logger(subsystem: "amStizzleReboot", category: "EventsListView")
  
  @State var avatarImage: AvatarImage?
  @State private var userEvents: [Event] = []
  @State private var invitedEvents: [Event] = []

#if DEBUG
  @State private var allEvents: [Event] = []
#endif
  
  @State var isNewEventSheetPresented = false
  
  @State var showAccountSheet = false
  
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
            .onDelete { offsets in
              deleteUserEvents(at: offsets)
            }
          }
          
          Section("Invited Events") {
            ForEach(invitedEvents, id: \.id) { event in
              NavigationLink {
                EventDetailView(event: event)
              } label: {
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
            }
          }
         
          #if DEBUG
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
          }
          #endif
        }
        .refreshable {
          await loadEvents()
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
      await loadEvents()
//      await loadInvitedEvents()
      
    } catch {
      logger.error("\(error)")
    }
  }
  
  private func loadEvents() async {
    do {
      let currentUser = try await Supabase.shared.auth.session.user
      
      let usersFetchedEvents: [Event] =
      try await Supabase.shared
        .from("events")
        .select()
        .eq("creator_id", value: currentUser.id)
        .execute()
        .value
      
      logger.info("MyEventsCount: \(usersFetchedEvents.count)")
      
      userEvents = usersFetchedEvents
//      await loadInvitedEvents()
    } catch {
      logger.error("\(error)")
    }
    
    do {
      let currentUser = try await Supabase.shared.auth.session.user
      
      let fetchedInvitedEvents: [Event] =
      try await Supabase.shared
        .from("events")
        .select("*, event_attendees!inner(*)")
        .eq("event_attendees.profile_id", value: currentUser.id)
        .neq("creator_id", value: currentUser.id)
        .execute()
        .value
      
      logger.info("InvitedEventsCount: \(fetchedInvitedEvents.count)")
      
      invitedEvents = fetchedInvitedEvents
    } catch {
      logger.error("\(error)")
    }
    
    #if DEBUG
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
    #endif
  }
  
  private func deleteUserEvents(at offsets: IndexSet) {
    let idsToDelete = offsets.map { userEvents[$0].id }
    Task {
      do {
        try await Supabase.shared
          .from("events")
          .delete()
          .in("id", values: idsToDelete)
          .execute()
        
//        await MainActor.run {
          userEvents.remove(atOffsets: offsets)
//        }
      } catch {
        logger.error("\(error)")
      }
    }
    logger.info("Event with ID \(idsToDelete) deleted")
  }
  
  private func downloadImage(path: String) async throws {
    let data = try await Supabase.shared.storage.from("avatars").download(path: path)
    avatarImage = AvatarImage(data: data)
  }
}

#Preview {
  NavigationStack {
    EventsListView()
  }
}

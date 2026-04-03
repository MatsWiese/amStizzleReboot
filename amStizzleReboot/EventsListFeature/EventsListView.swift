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
  @State var router = AppRouter()
  
  @State var currentUserId: UUID?
  
  @State var avatarImage: AvatarImage?
  @State private var userEvents: [Event] = []
  @State var invitedEvents: [Event] = []
  
#if DEBUG
  @State private var allEvents: [Event] = []
#endif
  
//  @State var isNewEventSheetPresented = false
  
  @State var showAccountSheet = false
  
  var body: some View {
    NavigationStack(path: $router.path) {
      ScrollView {
        if invitedEvents.isEmpty {
          ContentUnavailableView("Events loading...", systemImage: "arrow.2.circlepath.circle.fill")
        } else {
          ForEach(invitedEvents, id: \.id) { event in
            EventRowView(/*model: EventRowModel(), */event: event, currentUserId: currentUserId ?? UUID())
              .padding()
          }
        }
//        .onDelete(perform: deleteUserEvents)
//#warning("Delete doesn't work in ScrollView")
      }
      .refreshable {
        await loadEvents()
      }
      .navigationTitle("Events")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            //              newEventTitle = ""
//            isNewEventSheetPresented = true
            router.push(.createNewEvent)
          } label: {
            Label("Add Event", systemImage: "plus")
          }
        }
        ToolbarItem(placement: .topBarLeading) {
          Button {
            showAccountSheet = true
          } label: {
            //            Group {
            if let avatarImage {
              avatarImage.image
                .resizable()
                .clipShape(Circle())
                .scaledToFill()
            } else {
              Image(systemName: "person")
            }
          }
          .buttonStyle(.plain)
        }
      }
      .task {
        await initialLoading()
      }
      .navigationDestination(for: Destination.self, destination: \.view)
//      ..viewsheet(isPresented: $isNewEventSheetPresented) {
//        NavigationStack {
//          CreateEventSheet()
//        }
//      }
      .sheet(isPresented: $showAccountSheet) {
        NavigationStack {
          ProfileView()
        }
      }
    }
    .environment(router)
  }
  
  func initialLoading() async {
    do {
      let currentUser = try await Supabase.shared.auth.session.user
      logger.info("Current user: \(currentUser.id)")
      currentUserId = currentUser.id
      
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
        .order("start_date", ascending: true)
//        .neq("creator_id", value: currentUser.id)
        .execute()
        .value
      
      logger.info("InvitedEventsCount: \(fetchedInvitedEvents.count)")
      
      invitedEvents = fetchedInvitedEvents
    } catch {
      logger.error("\(error)")
    }
  }
  
//  private func deleteUserEvents(event: Event) {
//    Task {
//          do {
//            try await Supabase.shared
//              .from("events")
//              .delete()
//              .eq("event_id", value: event.id)
//              .eq("creator_id", value: currentUserId)
//              .execute()
//    
//            //        await MainActor.run {
////            userEvents.remove(atOffsets: offsets)
//            //        }
//          } catch {
//            logger.error("\(error)")
//          }
//        }
//    logger.info("Event with ID \(event.id) deleted")
//  }
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
  let events = [
    Event(id: UUID(), title: "1", details: nil, startDate: Date.now, endDate: Date.now + 3600, createdAt: Date.now, updatedAt: Date.now, creatorId: UUID()),
    Event(id: UUID(), title: "2", details: nil, startDate: Date.now, endDate: Date.now + 3600, createdAt: Date.now, updatedAt: Date.now, creatorId: UUID()),
    Event(id: UUID(), title: "3", details: nil, startDate: Date.now, endDate: Date.now + 3600, createdAt: Date.now, updatedAt: Date.now, creatorId: UUID()),
    Event(id: UUID(), title: "4", details: nil, startDate: Date.now, endDate: Date.now + 3600, createdAt: Date.now, updatedAt: Date.now, creatorId: UUID())
  ]
  NavigationStack {
    EventsListView(currentUserId: UUID(), invitedEvents: events)
  }
  .environment(AppRouter())
}

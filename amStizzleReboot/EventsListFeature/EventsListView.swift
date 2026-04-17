//
//  EventsListView.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 18.12.25.
//

import os
import SwiftUI
import Supabase

@Observable
final class EventsListViewModel {
  private let repository: SupabaseRepository
  private let logger = Logger(subsystem: "amStizzleReboot", category: "EventsListViewModel")

  private(set) var events: [Event] = []
  private(set) var avatarImage: AvatarImage?

  var currentUserID: UUID?
  private(set) var eventAttendees: [EventAttendee] = []

  init(repository: SupabaseRepository = .shared) {
    self.repository = repository
  }

  func onAccept(forEventID eventID: Event.ID) {
    Task {
      do {
        try await repository.updateAttendanceStatus(to: 1, forEventID: eventID)
        await loadData()
      } catch {
        logger.error("\(error)")
      }
    }
  }

  func onDecline(forEventID eventID: Event.ID) {
    Task {
      do {
        try await repository.updateAttendanceStatus(to: 2, forEventID: eventID)
        await loadData()
      } catch {
        logger.error("\(error)")
      }
    }
  }

  func loadData() async {
    do {
      let currentUserID = try await repository.getCurrentUserId()
      self.currentUserID = currentUserID
      
      logger.info("ELVM: fn loadData: currentUserID: \(currentUserID)")

      self.events = try await Supabase.shared
        .from("events")
        .select("*, event_attendees!inner(*)")
        .eq("event_attendees.profile_id", value: currentUserID)
        .order("start_date", ascending: true)
        .execute()
        .value

      self.eventAttendees = await repository.getEventAttendeesWithUsernames()
//      self.eventAttendees = try await Supabase.shared
//        .from("event_attendees")
//        .select()
////        .select(
////                  """
////                    id,
////                    event_id,
////                    profile_id,
////                    profiles ( id, username )
////                    attendance_status,
////                    created_at,
////                    updated_at,
////                  
////                  """
////                )
//        //        .eq("profile_id", value: "id")
//        //        .eq("event_id", value: event.id)
//        .execute()
//        .value

//      logger.info("Events: \(self.events)")
      logger.info("EventAttendees: \(self.eventAttendees)")
      logger.info("EventsCount: \(self.events.count)")

      self.avatarImage = try await repository.getCurrentUserAvatarImage()
    } catch {
      logger.error("\(error)")
    }
    logger.info("loadData \(self.currentUserID?.uuidString ?? "No currentUserID")")
  }
}

struct EventsListView: View {
  let logger = Logger(subsystem: "amStizzleReboot", category: "EventsListView")
  @State var router = AppRouter()
  @State private var viewModel = EventsListViewModel()

//  @State var currentUserID: UUID?

  @State var avatarImage: AvatarImage?

#if DEBUG
  @State private var allEvents: [Event] = []
#endif

  @State var showProfileView = false

  var body: some View {
    NavigationStack(path: $router.path) {
      ScrollView {
        if viewModel.events.isEmpty {
          VStack {
            ProgressView()
              .scaleEffect(2)
            Text("loading Events...")
              .padding(.top)
          }
          .frame(height: 200)
        } else {
          ForEach(viewModel.events) { event in
            EventRowView(
              event: event,
              eventAttendees: viewModel.eventAttendees.filter { $0.eventId == event.id },
              currentEventAttendee: viewModel.eventAttendees.first {
                $0.eventId == event.id && $0.profileId == viewModel.currentUserID
              },
              onTapAcceptButton: {
                viewModel.onAccept(forEventID: event.id)
              },
              onTapDeclineButton: {
                viewModel.onDecline(forEventID: event.id)
              }
            )
            .padding()
          }
        }
        //        .onDelete(perform: deleteUserEvents)
        //#warning("Delete doesn't work in ScrollView")
      }
      .task {
        await viewModel.loadData()
      }
      .refreshable {
        await viewModel.loadData()
      }
      .navigationTitle("Events")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            router.push(.createNewEvent)
          } label: {
            Label("Add Event", systemImage: "plus")
          }
        }
        ToolbarItem(placement: .topBarLeading) {
          Button {
            showProfileView = true
          } label: {
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
      .navigationDestination(for: Destination.self, destination: \.view)
      .sheet(isPresented: $showProfileView) {
        NavigationStack {
          ProfileView()
        }
      }
    }
    .environment(router)
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
    //    let idsToDelete = offsets.map { userEvents[$0].id }
    //    Task {
    //      do {
    //        try await Supabase.shared
    //          .from("events")
    //          .delete()
    //          .in("id", values: idsToDelete)
    //          .execute()
    //
    //        userEvents.remove(atOffsets: offsets)
    //      } catch {
    //        logger.error("\(error)")
    //      }
    //    }
    //    logger.info("Event with ID \(idsToDelete) deleted")
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
    EventsListView()
  }
  .environment(AppRouter())
}

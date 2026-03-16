//
//  EventsListView.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 18.12.25.
//

import SQLiteData
import SwiftUI

struct EventsListView: View {
  @Selection struct EventRow {
    let event: Event
    let attendeeCount: Int
  }
  
  @ObservationIgnored @AppStorage("selectedUserID") var currentUserIDString: String = ""
  
  private var currentUserUUID: UUID {
    UUID(uuidString: currentUserIDString)
    ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
  }
  
  @State private var eventRows: [EventRow] = []
  //  @State private var allEvents: [Event] = []
  
  @ObservationIgnored @FetchAll/*(Event.none)*/ var allEvents: [Event]
  
  @State var isNewEventSheetPresented = false
  
  @State var showAccountSheet = false
  
  @Dependency(\.defaultDatabase) var database
  
  var body: some View {
    NavigationStack {
      List {
        Section("Users Events") {
          ForEach(eventRows, id: \.event.id) { row in
            NavigationLink {
              EventDetailView(event: row.event)
            } label: {
              HStack {
                VStack(alignment: .leading) {
                  Text(row.event.title)
                    .font(.headline)
                  HStack {
                    Text(row.event.startDate.formatted(date: .abbreviated, time: .omitted))
                    
                    let duration = DateInterval(start: row.event.startDate, end: row.event.endDate)
                    Text(duration)
                  }
                }
                Spacer()
                HStack {
                  if row.attendeeCount == 1 {
                    Image(systemName: "person")
                  } else if row.attendeeCount == 2 {
                    Image(systemName: "person.2")
                  } else if row.attendeeCount == 3 {
                    Image(systemName: "person.3")
                  } else if row.attendeeCount > 3 {
                    Text("\(row.attendeeCount)")
                    Image(systemName: "person.3")
                  }
                }
              }
            }
          }
          .onDelete { offsets in
            withErrorReporting {
              try database.write { db in
                try Event.find(offsets.map { eventRows[$0].event.id })
                  .delete()
                  .execute(db)
              }
            }
            loadRows()
          }
        }
        Section("All Events") {
          ForEach(allEvents) { event in
            VStack(alignment: .leading) {
              Text(event.title)
                .font(.headline)
            }
          }
          .onDelete { offsets in
            withErrorReporting {
              try database.write { db in
                try Event.find(offsets.map { allEvents[$0].id })
                  .delete()
                  .execute(db)
              }
            }
            loadRows()
          }
        }
      }
      .navigationTitle("Events")
      .task(id: currentUserIDString) {
        loadRows()
      }
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            //          newEventTitle = ""
            isNewEventSheetPresented = true
          } label: {
            Label("Add Event", systemImage: "plus")
          }
        }
        ToolbarItem(placement: .topBarLeading) {
          Button {
            showAccountSheet = true
          } label: {
            Label("ChangeUser", systemImage: "person")
          }
        }
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
  
#warning("Doesn't load Users Events after adding a new one.")
  private func loadRows() {
    withErrorReporting {
      try database.read { db in
        let invitedEventIds = EventAttendee
          .where { $0.userId.eq(currentUserUUID) }
          .select { $0.eventId }
        
        let query = Event
          .leftJoin(EventAttendee.all) { event, attendee in
            event.id.eq(attendee.eventId)
            && attendee.status.eq(AttandanceStatus.attending)
          }
          .where { event, _ in event.id.in(invitedEventIds) }
          .group(by: { event, _ in event.id })
          .select { EventRow.Columns(event: $0, attendeeCount: $1.count()) }
        
        eventRows = try query.fetchAll(db)
      }
    }
  }
}

#Preview {
  let _ = prepareDependencies {
    try! $0.bootstrapDatabase()
    try! $0.defaultDatabase.seed()
  }
  NavigationStack {
    EventsListView()
  }
}

//
//  EventsListView.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 18.12.25.
//

import SQLiteData
import SwiftUI

struct EventsListView: View {
  @Selection struct Row {
    let event: Event
    let attendeeCount: Int
  }
  @AppStorage("selectedUserID") var selectedUserID: String = ""
  
#warning("Fetch only events for the selectedUserID")
  @FetchAll(
    Event
      .group(by: \.id)
      .leftJoin(EventAttendee.all) { $0.id.eq($1.eventId) }
      .select { Row.Columns(event: $0, attendeeCount: $1.count()) },
    animation: .default
  ) var rows/*: [Row]*/
 
  @State var isNewEventSheetPresented = false
  
  @State var changeUserSheet = false
  
  @Dependency(\.defaultDatabase) var database

  var body: some View {
    List {
      ForEach(rows, id: \.event.id) { row in
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
            try Event.find(offsets.map { rows[$0].event.id })
              .delete()
              .execute(db)
          }
        }
      }
    }
    .navigationTitle("Events")
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
          changeUserSheet = true
        } label: {
          Label("ChangeUser", systemImage: "person.fill.and.arrow.left.and.arrow.right.outward")
        }
      }
    }
    .sheet(isPresented: $isNewEventSheetPresented) {
      NavigationStack {
        CreateEventSheet()
      }
    }
    .sheet(isPresented: $changeUserSheet) {
      NavigationStack {
        DebugChangeUserView()
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

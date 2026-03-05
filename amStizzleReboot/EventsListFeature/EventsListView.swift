//
//  EventsListView.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 18.12.25.
//

import SQLiteData
import SwiftUI

struct EventsListView: View {
  @AppStorage("selectedUserID") var selectedUserID: String = ""
#warning("Fetch only events for the selectedUserID")
  @FetchAll(animation: .default) var events: [Event]
 
  @State var isNewEventSheetPresented = false
  @State var changeUserSheet = false
  
  @Dependency(\.defaultDatabase) var database

  var body: some View {
    List {
      ForEach(events) { event in
        NavigationLink(destination: EventDetailView(event: event), label: {
          HStack {
            VStack(alignment: .leading) {
              Text(event.title)
                .font(.headline)
              HStack {
                Text(event.startDate.formatted(date: .abbreviated, time: .omitted))
                
                let duration = DateInterval(start: event.startDate, end: event.endDate)
                Text(duration)
              }
            }
            Spacer()
            HStack {
//              Text(event.attendees.count)
//              if event.attendees == 2 {
//                Image(systemName: "person.2")
//              } else if event.attendees > 2 {
//                Image(systemName: "person.3")
//              } else {
                Image(systemName: "person")
//              }
            }
          }
        }
      )
      }
      .onDelete { offsets in
        withErrorReporting {
          try database.write { db in
            try Event.find(offsets.map { events[$0].id })
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

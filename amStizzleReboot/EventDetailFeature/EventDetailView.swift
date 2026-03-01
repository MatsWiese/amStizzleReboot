
//  EventDetailView.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 18.12.25.


import SwiftUI
import SQLiteData
//import Dependencies

struct EventDetailView: View {
  @Dependency(\.defaultDatabase) var database

  let event: Event
  
    var body: some View {
      VStack {
        
          Text(event.startDate.formatted(date: .abbreviated, time: .shortened))
          Text(event.endDate.formatted(date: .abbreviated, time: .shortened))
        NavigationLink(destination: AttendeeManagerSheet(event: event)) {
          Text("Manage Attendees")
        }
      }
      .navigationTitle(event.title)
    }
}

#Preview {
  let event = prepareDependencies {
    try! $0.bootstrapDatabase()
    try! $0.defaultDatabase.seed()
    return try! $0.defaultDatabase.read { db in
          try Event.fetchOne(db)!
        }
  }
  NavigationStack {
    EventDetailView(event: event)
  }
}

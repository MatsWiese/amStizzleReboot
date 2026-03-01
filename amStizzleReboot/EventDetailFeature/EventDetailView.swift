
//  EventDetailView.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 18.12.25.


import SwiftUI
import Dependencies

struct EventDetailView: View {
//  init(event: Event) {
//  }
  let event: Event
  
    var body: some View {
      VStack {
        
          Text(event.startDate.formatted(date: .abbreviated, time: .shortened))
          Text(event.endDate.formatted(date: .abbreviated, time: .shortened))
      }
      .navigationTitle(event.title)
    }
}

#Preview {
  let event: Event = .init(id: UUID(1), title: "Sample Event", startDate: Date.now, endDate: Date.now + 3600)
  NavigationStack {
    EventDetailView(event: event)
  }
}

//
//  Destination.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 20.03.26.
//

import SwiftUI

enum Destination {
  case createNewEvent
  case attendeeManager(event: Event)
  case eventDetail(event: Event)
  
  @ViewBuilder var view: some View {
    switch self {
    case .createNewEvent:
      CreateEventView()
    case .attendeeManager(event: let event):
      AttendeeManagerView(event: event)
    case .eventDetail(event: let event):
      EventDetailView(event: event)
    }
  }
}

extension Destination: Hashable, Equatable {
  static func == (lhs: Destination, rhs: Destination) -> Bool {
    switch (lhs, rhs) {
    case let (.attendeeManager(lhsEvent), .attendeeManager(rhsEvent)):
      return lhsEvent.id == rhsEvent.id
    case let (.eventDetail(lhsEvent), .eventDetail(rhsEvent)):
      return lhsEvent.id == rhsEvent.id
    case (.createNewEvent, .createNewEvent):
      return true
    default:
      return false
    }
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(self)
  }
}

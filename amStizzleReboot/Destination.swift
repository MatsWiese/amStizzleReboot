//
//  Destination.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 20.03.26.
//

import SwiftUI

enum Destination {
  case createNewEvent
  case attendeeManager(eventID: Event.ID)
  case eventDetail(eventID: Event.ID)
  
  @ViewBuilder var view: some View {
    switch self {
    case .createNewEvent:
      CreateEventView()
    case .attendeeManager(eventID: let eventID):
      AttendeeManagerView(eventID: eventID)
    case .eventDetail(eventID: let eventID):
      EventDetailView(eventID: eventID)
    }
  }
}

extension Destination: Hashable, Equatable {
  static func == (lhs: Destination, rhs: Destination) -> Bool {
    switch (lhs, rhs) {
    case let (.attendeeManager(lhsEventID), .attendeeManager(rhsEventID)):
      return lhsEventID == rhsEventID
    case let (.eventDetail(lhsEventID), .eventDetail(rhsEventID)):
      return lhsEventID == rhsEventID
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

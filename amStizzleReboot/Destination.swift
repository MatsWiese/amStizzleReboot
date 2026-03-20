//
//  Destination.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 20.03.26.
//

import SwiftUI

enum Destination {
//  case createNewEvent
  case attendeeManager(event: Event)
  
  
  var view: some View {
    switch self {
      //    case .createNewEvent:
      //      CreateEventSheet()
    case .attendeeManager(event: let event):
      AttendeeManagerSheet(event: event)
    }
  }
}

extension Destination: Hashable, Equatable {
  static func == (lhs: Destination, rhs: Destination) -> Bool {
    switch (lhs, rhs) {
    case let (.attendeeManager(lhsEvent), .attendeeManager(rhsEvent)):
      return lhsEvent.id == rhsEvent.id
      //    case (.createNewEvent(), .createNewEvent()):
      //      return .createNewEvent()
    }
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(self)
  }
}

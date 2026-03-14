//
//  Schema.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 16.12.25.
//

import StructuredQueries
import Dependencies
import Foundation
import os
import SQLiteData

nonisolated(unsafe) private let logger = Logger(
  subsystem: Bundle.main.bundleIdentifier ?? "",
  category: "persistence"
)

//@Table struct Group: Identifiable {
//  let id: UUID
//  var title = ""
////  var creationDate: Date
////  var modificationDate: Date
//}

@Table struct User: Identifiable {
  let id: UUID
//  let groupId: Group.ID
  var firstName = ""
  var lastName = ""
}

@Table struct Event: Identifiable {
    let id: UUID
//  let groupId: Group.ID
    var title = ""
    var description: String?
    var startDate: Date
    var endDate: Date
    var creatorId: User.ID
//    var attendees: [User]
//  var attendenceDeadline: Date
//  var creationDate: Date
//  var modificationDate: Date
}

struct AttandanceStatus: RawRepresentable, QueryBindable {
  let rawValue: Int
  static let invited = AttandanceStatus(rawValue: 0)
  static let attending = AttandanceStatus(rawValue: 1)
  static let notAttending = AttandanceStatus(rawValue: 2)
  static let unsure = AttandanceStatus(rawValue: 3)
}
 extension AttandanceStatus {
    var displayName: String {
        switch rawValue {
        case Self.invited.rawValue:
            return "Invited"
        case Self.attending.rawValue:
            return "Attending"
        case Self.notAttending.rawValue:
            return "Declined"
        case Self.unsure.rawValue:
            return "Unsure"
        default:
            return "Unknown"
        }
    }
}

@Table struct EventAttendee: Identifiable {
    let id: UUID
    var eventId: Event.ID
    var userId: User.ID
    var status: AttandanceStatus
}

func appDatabase() throws -> any DatabaseWriter {
  @Dependency(\.context) var context
  var configuration = Configuration()
  configuration.prepareDatabase { db in
//    try db.attachMetadatabase()
#if DEBUG
    db.trace(options: .profile) {
      guard
        !$0.expandedDescription.hasPrefix("--")
      else { return }
      switch context {
      case .live:
        logger.debug("\($0.expandedDescription)")
      case .preview:
        print("\($0.expandedDescription)")
      case .test:
        break
      }
    }
#endif
  }

  let database = try SQLiteData.defaultDatabase(configuration: configuration)
  logger.debug("open '\(database.path)'")
  var migrator = DatabaseMigrator()
  
  #if DEBUG
  migrator.eraseDatabaseOnSchemaChange = true
  #endif
  
  migrator.registerMigration("Create 'user', 'group' and 'event' tables") { db in
    try #sql("""
              CREATE TABLE "users" (
                "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                "firstName" TEXT NOT NULL,
                "lastName" TEXT NOT NULL
              )
              """)
    .execute(db)
    
//    try #sql(
//      """
//      CREATE TABLE "groups" (
//        "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
//        "name" TEXT NOT NULL,
//        "description" TEXT
//      )
//      """
//    )
//    .execute(db)
    
    try #sql(
      """
      CREATE TABLE "events" (
        "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
        "title" TEXT NOT NULL DEFAULT '',
        "description" TEXT,
        "startDate" TEXT NOT NULL,
        "endDate" TEXT NOT NULL,
        "creatorId" TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE
      )
      """
    )
    .execute(db)

    try #sql(
      """
      CREATE TABLE "eventAttendees" (
        "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
        "eventId" TEXT NOT NULL REFERENCES events(id) ON DELETE CASCADE,
        "userId" TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        "status" TEXT NOT NULL DEFAULT "invited"
      )
      """
    )
    .execute(db)
  }
  try migrator.migrate(database)
  return database
}

extension DependencyValues {
  mutating func bootstrapDatabase() throws {
    defaultDatabase = try appDatabase()
  }
}

extension DatabaseWriter {
  func seed() throws {
    try write { db in
     try db.seed {
       Event(id: UUID(1), title: "Christmas Eve", startDate: Date.now, endDate: Date.now + 3600, creatorId: UUID(1))
//       Event.Draft(title: "Christmas Eve", startDate: Date.now, endDate: Date.now + 3600)
       Event.Draft(id: UUID(2), title: "Silvester Party", startDate: Date.now, endDate: Date.now + 7200, creatorId: UUID(1))
       Event.Draft(id: UUID(3), title: "Birthday", startDate: Date.now, endDate: Date.now + 1010800, creatorId: UUID(1))
      }
      try db.seed {
        User.Draft(id: UUID(1), firstName: "Arthur", lastName: "Dent")
        User.Draft(id: UUID(2), firstName: "Bruce", lastName: "Wayne")
        User.Draft(id: UUID(3), firstName: "Barbara", lastName: "Gordon")
       }
      try db.seed {
        EventAttendee.Draft(eventId: UUID(2), userId: UUID(1), status: .invited)
        EventAttendee.Draft(eventId: UUID(1), userId: UUID(2), status: .attending)
        EventAttendee.Draft(eventId: UUID(1), userId: UUID(3), status: .notAttending)
       }
    }
  }
}

//
//  Schema.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 16.12.25.
//

import Dependencies
import Foundation
import SQLiteData

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
//    var attendees: [User]
//  var attendenceDeadline: Date
//  var creationDate: Date
//  var modificationDate: Date
}

@Table struct EventAttendee: Identifiable {
    let id: UUID
    var eventId: Event.ID
    var userId: User.ID
}

func appDatabase() throws -> any DatabaseWriter {
  let database = try SQLiteData.defaultDatabase()
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
        "endDate" TEXT NOT NULL
      )
      """
    )
    .execute(db)

    try #sql(
      """
      CREATE TABLE "eventAttendees" (
        "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
        "eventId" TEXT NOT NULL REFERENCES events(id) ON DELETE CASCADE,
        "userId" TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE
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
       Event.Draft(title: "Christmas Eve", startDate: Date.now, endDate: Date.now + 3600)
       Event.Draft(title: "Silvester Party", startDate: Date.now, endDate: Date.now + 7200)
       Event.Draft(title: "Birthday", startDate: Date.now, endDate: Date.now + 1010800)
      }
    }
  }
}

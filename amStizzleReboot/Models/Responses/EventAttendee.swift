//
//  Profile.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 14.03.26.
//

import Foundation

struct EventAttendee: Codable {
  let id: UUID
  let createdAt: Date?
  let updatedAt: Date?
  let eventId: UUID?
  let profileId: UUID?
  let attendanceStatus: Int?

  enum CodingKeys: String, CodingKey {
    case id
    case createdAt = "created_at"
    case updatedAt = "updated_at"
    case eventId = "event_id"
    case profileId = "profile_id"
    case attendanceStatus = "attendance_status"
  }
}

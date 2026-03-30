//
//  Profile.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 14.03.26.
//

import Foundation

struct EventAttendee: Codable, Identifiable {
  let id: UUID
  let eventId: UUID?
  let profileId: UUID?
  let attendanceStatus: Int?
  let createdAt: Date?
  let updatedAt: Date?

  enum CodingKeys: String, CodingKey {
    case id
    case eventId = "event_id"
    case profileId = "profile_id"
    case attendanceStatus = "attendance_status"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }
}

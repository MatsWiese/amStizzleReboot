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
  let username: String?
  let attendanceStatus: Int?
  let createdAt: Date?
  let updatedAt: Date?
  
  init(id: UUID, eventId: UUID?, profileId: UUID, username: String?, attendanceStatus: Int?, createdAt: Date?, updatedAt: Date?) {
    self.id = id
    self.eventId = eventId
    self.profileId = profileId
    self.username = username
    self.attendanceStatus = attendanceStatus
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
  
  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try container.decode(UUID.self, forKey: .id)
    self.eventId = try container.decodeIfPresent(UUID.self, forKey: .eventId)
    self.profileId = try container.decodeIfPresent(UUID.self, forKey: .profileId)
    self.attendanceStatus = try container.decodeIfPresent(Int.self, forKey: .attendanceStatus)
    self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
    self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    self.username = try container.decodeIfPresent(Profile.self, forKey: .profiles)?.username
  }
  
  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(eventId, forKey: .eventId)
    try container.encode(profileId, forKey: .profileId)
    try container.encode(attendanceStatus, forKey: .attendanceStatus)
    try container.encode(createdAt, forKey: .createdAt)
    try container.encode(updatedAt, forKey: .updatedAt)
  }
  
  enum CodingKeys: String, CodingKey {
    case id
    case eventId = "event_id"
    case profileId = "profile_id"
    case username = "username"
    case attendanceStatus = "attendance_status"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
    case profiles = "profiles"
  }
  
  struct Profile: Decodable {
    let username: String
  }
}

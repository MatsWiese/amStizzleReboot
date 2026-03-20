//
//  Event.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 17.03.26.
//

import Foundation

struct Event: Codable {
  let id: UUID
  let title: String?
  let details: String?
  let startDate: Date?
  let endDate: Date?
  let createdAt: Date?
  let updatedAt: Date?
  let creatorId: UUID?
  
  enum CodingKeys: String, CodingKey {
    case id
    case title
    case details
    case startDate = "start_date"
    case endDate = "end_date"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
    case creatorId = "creator_id"
  }
}

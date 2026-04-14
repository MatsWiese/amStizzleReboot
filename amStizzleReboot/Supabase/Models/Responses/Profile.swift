//
//  Profile.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 14.03.26.
//

import Foundation

struct Profile: Codable, Hashable {
  let id: UUID
  let firstName: String?
  let lastName: String?
  let username: String?
  let avatarURL: String?
  let createdAt: Date?
  let updatedAt: Date?

  enum CodingKeys: String, CodingKey {
    case id
    case firstName = "first_name"
    case lastName = "last_name"
    case username
    case avatarURL = "avatar_url"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }
}

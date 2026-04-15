//
//  SupabaseRepository.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 14.04.26.
//

import Foundation
import Supabase
import os

final class SupabaseRepository {
  private let client: SupabaseClient
  private let logger = Logger(subsystem: "amStizzleReboot", category: "SupabaseRepository")
  
  static let shared = SupabaseRepository()
  
  init(client: SupabaseClient = Supabase.shared) {
    self.client = client
  }
  
  func getCurrentEventAttendee(for eventId: Event.ID) async throws -> EventAttendee {
    let userId = try await getCurrentUserId()
    return try await Supabase.shared
      .from("event_attendees")
      .select()
      .eq("profile_id", value: userId)
      .eq("event_id", value: eventId)
      .single()
      .execute()
      .value
  }
  
  func getCurrentUserId() async throws -> UUID {
    let id = try await client.auth.session.user.id
    logger.info("SupabaseRepository: Current user: \(id)")
    return id
  }

  func getCurrentUserAvatarImage() async throws -> AvatarImage? {
    let currentUserID = try await getCurrentUserId()
    let profile: Profile = try await client
      .from("profiles")
      .select()
      .eq("id", value: currentUserID)
      .single()
      .execute()
      .value

    if let avatarURL = profile.avatarURL {
      let data = try await client.storage.from("avatars").download(path: avatarURL)
      return AvatarImage(data: data)
    } else {
      return nil
    }
  }

  func updateAttendanceStatus(to newAttendenceStatus: Int, forEventID eventID: Event.ID) async throws {
    let currentUserID = try await getCurrentUserId()
    try await client.from("event_attendees")
      .update(["attendance_status": newAttendenceStatus])
      .eq("profile_id", value: currentUserID)
      .eq("event_id", value: eventID)
      .execute()
    
    logger.info("Set AttendenceStatus to \(newAttendenceStatus)")
  }
}

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
    logger.info("Current user: \(id)")
    return id
  }
}

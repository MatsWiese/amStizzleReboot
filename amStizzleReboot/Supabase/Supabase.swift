//
//  Supabase.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 14.03.26.
//

import Foundation
import Supabase
import os

class Supabase {
  static let shared = SupabaseClient(
    supabaseURL:
      URL(string: "https://daoohrawakwkbnddvdex.supabase.co")!,
    supabaseKey: "sb_publishable_ttpvGF3soJrysKWT537JJQ_ZwAlM1MI",
    options: .init(
      auth: .init(emitLocalSessionAsInitialSession: true),
      global: .init(logger: ConsoleLogger())
    )
  )
  private init() { }
}

struct ConsoleLogger: SupabaseLogger {
  let logger = Logger(subsystem: "amStizzleReboot", category: "Supabase")
  func log(message: SupabaseLogMessage) {
    logger.info("\(message.description)")
  }
}

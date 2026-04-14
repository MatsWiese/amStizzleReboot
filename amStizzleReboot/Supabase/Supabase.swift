//
//  Supabase.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 14.03.26.
//

import Foundation
import Supabase

class Supabase {
  static let shared = SupabaseClient(
    supabaseURL:
      URL(string: "https://daoohrawakwkbnddvdex.supabase.co")!,
    supabaseKey: "sb_publishable_ttpvGF3soJrysKWT537JJQ_ZwAlM1MI",
    options: .init(auth: .init(emitLocalSessionAsInitialSession: true))
  )
  private init() { }
}

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
      URL(string: "https://urexdmyfiqtievtbpcnx.supabase.co")!,
    supabaseKey: "sb_publishable_BIfX14NlCjhsyjoVJBg2Ag_RcP_IkFY"
  )
  private init() { }
}

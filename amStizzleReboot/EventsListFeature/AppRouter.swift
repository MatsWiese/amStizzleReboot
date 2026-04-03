//
//  AppRouter.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 03.04.26.
//

import Foundation

@Observable class AppRouter {
  var path: [Destination] = []
  
  func push(_ destination: Destination) {
    path.append(destination)
  }
  
  func pop() {
    path.removeLast()
  }
}

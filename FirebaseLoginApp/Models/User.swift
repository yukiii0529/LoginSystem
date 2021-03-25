//
//  User.swift
//  FirebaseLoginApp
//
//  Created by 田中勇輝 on 2020/12/25.
//

import Foundation
import Firebase

// ユーザー情報の保存をするモデル
struct User {
    let name: String
    let createdAt: Timestamp
    let email: String
    
    init(dic: [String: Any]) {
        self.name = dic["name"] as! String
        self.createdAt = dic["createdAt"] as! Timestamp
        self.email = dic["email"] as! String
    }
}

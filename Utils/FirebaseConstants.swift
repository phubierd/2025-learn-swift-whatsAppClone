//
//  FirebaseConstants.swift
//  WhatsAppClone
//
//  Created by Osaretin Uyigue on 3/18/24.
//

import Foundation
import Firebase
import FirebaseStorage

enum FirebaseConstants {
    private static let DatabaseRef = Database.database(url:"https://whatsappclone-8b9b3-default-rtdb.asia-southeast1.firebasedatabase.app/").reference()
    static let UserRef = DatabaseRef.child("users")
    
    static let ChannelsRef = DatabaseRef.child("channels")
    static let MessageRef = DatabaseRef.child("channel-messages")
    static let UserChannelsRef = DatabaseRef.child("user-channels")
    static let UserDirectChannels = DatabaseRef.child("user-direct-channels")
}


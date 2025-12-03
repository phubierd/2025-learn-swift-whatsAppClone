//
//  ChannelItem.swift
//  WhatsAppClone
//
//  Created by Phú Chiêm on 30/11/25.
//

import Foundation
import FirebaseAuth


struct ChannelItem:Identifiable,Hashable{
    var id:String
    var name:String?
    var lastMessage:String
    var creationDate:Date
    var lastMessageTimeStamp:Date
    var membersCount:Int
    var adminUids:[String]
    var memberUids:[String]
    var members:[UserItem] //fetch from BE
    private var thumbnailUrl:String?
    var createdBy:String
    
    
    var isCreatedByMe:Bool{
        return createdBy == Auth.auth().currentUser?.uid ?? ""
    }
    
    var coverImageUrl:String?{
        if let thumbnailUrl = thumbnailUrl {
            return thumbnailUrl
        }
        if isGroupChat == false {
            return membersExcludingMe.first?.profileImageUrl
        }
        return nil
    }
    
    var creatorName:String{
        return members.first{$0.uid == createdBy}?.username ?? "Someone"
    }
    
    var isGroupChat:Bool{
        return membersCount > 2
    }
    
    var membersExcludingMe:[UserItem]{
        guard let currentUid = Auth.auth().currentUser?.uid else {return []}
        return members.filter{$0.uid != currentUid}
    }
    
    var allMembersFetched:Bool{
        return members.count == membersCount
    }
    
    var title:String{
        if let name = name{
            return name
        }
        if isGroupChat{
            return groupMemberNames
        }else{
            return membersExcludingMe.first?.username ?? "Unknown"
        }
    }
    
    private var groupMemberNames:String{
        let membersCount = membersCount - 1
        let fullNames:[String] = membersExcludingMe.map{$0.username}
        
        if membersCount == 2 {
            // username1 and username2
            return fullNames.joined(separator: " and ")
        }else if membersCount > 2 {
            // username1, username2 and 10 others
            let remainingCount = membersCount - 2
            return fullNames.prefix(2).joined(separator: ", ") + ", and \(remainingCount) others"
        }
        return "Unknown"
    }

    static let placeholder = ChannelItem.init(id: "1", lastMessage: "Hello World!", creationDate: Date(), lastMessageTimeStamp: Date(), membersCount: 2, adminUids: [], memberUids: [], members: [],createdBy: "")
    
}

extension ChannelItem {
    init(_ dict:[String:Any]){
        self.id = dict[.id] as? String ?? ""
        self.name = dict[.name] as? String? ?? nil
        self.lastMessage = dict[.lastMessage] as? String ?? ""
        let creationInterval = dict[.creationDate] as? Double ?? 0
        self.creationDate = Date(timeIntervalSince1970: creationInterval)
        let lastMsgTimeStampInterval = dict[.lastMessageTimeStamp] as? Double ?? 0
        self.lastMessageTimeStamp = Date(timeIntervalSince1970: lastMsgTimeStampInterval)
        self.membersCount = dict[.membersCount] as? Int ?? 0
        self.adminUids = dict[.adminUids] as? [String] ?? []
        self.thumbnailUrl = dict[.thumbnailUrl] as? String ?? nil
        self.memberUids = dict[.memberUids] as? [String] ?? []
        self.members = dict[.members] as? [UserItem] ?? []
        self.createdBy = dict[.createdBy] as? String ?? ""
    }
}

extension String {
    static let id = "id"
    static let name = "name"
    static let lastMessage = "lastMessage"
    static let creationDate = "creationDate"
    static let lastMessageTimeStamp = "lastMessageTimeStamp"
    static let membersCount = "membersCount"
    static let adminUids = "adminUids"
    static let memberUids = "memberUids"
    static let members = "members"
    static let thumbnailUrl = "thumbnailUrl"
    static let createdBy = "createdBy"
}

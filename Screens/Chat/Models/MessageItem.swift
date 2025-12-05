//
//  MessageItem.swift
//  WhatsAppClone
//
//  Created by Osaretin Uyigue on 3/14/24.
//

import SwiftUI
import FirebaseAuth

struct MessageItem: Identifiable {
    let id:String
    let isGroupChat:Bool
    let text: String
    let type: MessageType
    let ownerUid:String
    let timeStamp:Date
    var sender:UserItem?
    
    private let horizontalPadding:CGFloat = 25
    
    var direction: MessageDirection {
        return ownerUid == Auth.auth().currentUser?.uid ? .sent : .received
    }

    var alignment: Alignment {
        return direction == .received ? .leading : .trailing
    }
    
    var horizontalAlignment: HorizontalAlignment {
        return direction == .received ? .leading : .trailing
    }
    
    var backgroundColor: Color {
        return direction == .sent ? .bubbleGreen : .bubbleWhite
    }
    
    var showGroupPartnerInfo :Bool{
        return isGroupChat && direction == .received
    }
    
    var leadingPadding:CGFloat {
        return direction == .received ? 0 : horizontalPadding
    }
    
    var trailingPadding:CGFloat {
        return direction == .received ? horizontalPadding : 0
    }
    
   
    
    static let sentPlaceholder = MessageItem(id:UUID().uuidString,isGroupChat: true,text: "Holy Spagetti", type: .text,ownerUid: "1",timeStamp: Date())
    static let receivedPlaceholder = MessageItem(id:UUID().uuidString,isGroupChat: false,text: "Hey Dude whats up ", type: .text,ownerUid: "2",timeStamp: Date())
    
    static let stubMessages: [MessageItem] = [
        MessageItem(id:UUID().uuidString,isGroupChat: false,text: "Hi There", type: .text, ownerUid: "3",timeStamp: Date()),
        MessageItem(id:UUID().uuidString,isGroupChat: true,text: "Check out this Photo", type: .photo, ownerUid: "4",timeStamp: Date()),
        MessageItem(id:UUID().uuidString,isGroupChat: false,text: "Play out this Video", type: .video, ownerUid: "5",timeStamp: Date()),
        MessageItem(id:UUID().uuidString,isGroupChat: false,text: "", type: .audio, ownerUid: "6",timeStamp: Date())
    ]
}

extension MessageItem {
    init (id:String, isGroupChat:Bool,dict:[String:Any]){
        self.id = id
        self.isGroupChat = isGroupChat
        self.text = dict[.text] as? String ?? ""
        let type = dict[.type] as? String ?? "text"
        self.type = MessageType(type) ?? .text
        self.ownerUid = dict[.ownerUid] as? String ?? ""
        let timeInterval = dict[.timeStamp] as? TimeInterval ?? 0
        self.timeStamp = Date(timeIntervalSince1970: timeInterval)
    }
}


extension String{
    static let `type` = "type"
    static let timeStamp = "timeStamp"
    static let ownerUid = "ownerUid"
    static let text = "text"
}

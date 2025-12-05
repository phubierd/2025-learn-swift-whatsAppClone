//
//  MessageService.swift
//  WhatsAppClone
//
//  Created by Phú Chiêm on 2/12/25.
//

import Foundation

// MARK: handles sending and fetching messages and setting reactions
struct MessageService{
    
    static func sendTextMessages(to channel:ChannelItem, from currentUser:UserItem, _ textMessage:String, onComplete:()->Void){
        
        let timeStamp = Date().timeIntervalSince1970
        guard let messageId = FirebaseConstants.MessageRef.childByAutoId().key else {return}
        let channelDict:[String:Any] = [
            .lastMessage:textMessage,
            .lastMessageTimeStamp:timeStamp,
        ]
        let messageDict:[String:Any] = [
            .text:textMessage,
            .type:MessageType.text.title,
            .timeStamp:timeStamp,
            .ownerUid:currentUser.uid,
        ]
        
        FirebaseConstants.ChannelsRef.child(channel.id).updateChildValues(channelDict)
        FirebaseConstants.MessageRef.child(channel.id).child(messageId).setValue(messageDict)
        
        onComplete()
    }
    
    static func getMessages(for channel:ChannelItem,completion: @escaping ([MessageItem])->Void){
        FirebaseConstants.MessageRef.child(channel.id).observe(.value){ snapshot in
            // => snapshot.key = channelID
            guard let dict = snapshot.value as? [String:Any] else {return}
            
            var messages:[MessageItem] = []
            
            dict.forEach{key, value in
                // key = messageID
                let messageDict = value as? [String:Any] ?? [:]
                let message = MessageItem(id:key,isGroupChat: channel.isGroupChat,dict: messageDict)
                messages.append(message)
                if messages.count == snapshot.childrenCount{
                    messages.sort{$0.timeStamp < $1.timeStamp}
                    completion(messages)
                }
                
            }
            
          
        }withCancel: { error in
            print("Failed to get message for \(error.localizedDescription)")
        }
    }
}

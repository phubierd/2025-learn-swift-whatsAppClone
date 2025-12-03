//
//  ChatRoomViewModel.swift
//  WhatsAppClone
//
//  Created by Phú Chiêm on 1/12/25.
//

import Foundation
import Combine

final class ChatRoomViewModel:ObservableObject {
    @Published var textMessage = ""
    @Published var messages = [MessageItem]()
    
    private(set) var channel:ChannelItem
    private var subscriptions = Set<AnyCancellable>()
    private var currentUser:UserItem?
    
    init(_ channel:ChannelItem){
        self.channel = channel
        listenToAuthStates()
    }
    
    deinit{
        subscriptions.forEach{$0.cancel()}
        subscriptions.removeAll()
        currentUser = nil
    }
    
    private func listenToAuthStates(){
        AuthManager.shared.authState.receive(on:DispatchQueue.main).sink {[weak self] authState in
            guard let self = self else {return}
            switch authState{
            case .loggedIn(let currentUser):
                self.currentUser = currentUser
                
                if self.channel.allMembersFetched{
                    self.getMessage()
                    print("allMembersFetched -> true, channel members: \(channel.members.map{$0.username})")
                }else{
                    self.getAllChannelMembers()
                    print("allMembersFetched -> false")
                }
            default:
                break
            }
        }.store(in: &subscriptions)
    }
    
    func sendMessage(){
        guard let currentUser else {return}
        MessageService.sendTextMessages(to: channel, from: currentUser, textMessage){ [weak self] in
            self?.textMessage = ""
            
        }
    }
    
    private func getMessage(){
        MessageService.getMessages(for: channel){[weak self] messages in
            self?.messages = messages
            print("messages: \(messages.map{$0.text})")
        }
    }
    
    private func getAllChannelMembers(){
        //i aldready have current user, and potentially 2 other members so no need to refetch those
        
        guard let currentUser = currentUser else {return}
        let memebersAldreadyFetched = channel.members.compactMap{$0.uid}
        var memberUidsToFetch = channel.memberUids.filter{ !memebersAldreadyFetched.contains($0)}
        memberUidsToFetch = memberUidsToFetch.filter{$0 != currentUser.uid}
        
        UserService.getUsers(with: memberUidsToFetch){[weak self] userNode in
            guard let self = self else {return}
            self.channel.members.append(contentsOf: userNode.users)
            self.channel.members.append(currentUser)
            self.getMessage()
            print("getAllChannelMembers :\(channel.members.map{$0.username})")
        }
    }
}

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
            switch authState{
            case .loggedIn(let currentUser):
                self?.currentUser = currentUser
                self?.getMessage()
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
}

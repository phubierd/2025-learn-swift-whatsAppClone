//
//  ChatPartnerPickerViewModel.swift
//  WhatsAppClone
//
//  Created by Phú Chiêm on 27/11/25.
//

import Foundation

enum ChannelCreationRoute {
    case groupPartnerPicker
    case setUpGroupChat
}

enum ChannelConstants {
    static let maxGroupParticipants = 12
}

final class ChatPartnerPickerViewModel:ObservableObject{
    @Published var navStack = [ChannelCreationRoute]()
    @Published var selectedChatPartner = [UserItem]()
    
    var showSelectedUsers:Bool{
        return !selectedChatPartner.isEmpty
    }
    
    var disableNextButton : Bool{
        return selectedChatPartner.isEmpty
    }
    
    // MARK: - public methods
    
    func handleItemSelection(_ item:UserItem){
        if isUserSelected(item) {
            // de-select
            guard let index = selectedChatPartner.firstIndex(where: {$0.uid == item.uid}) else {return}
            selectedChatPartner.remove(at: index)
        }else{
            // select
            selectedChatPartner.append(item)
        }
    }
    
    func isUserSelected(_ user:UserItem)->Bool{
        let isSelected = selectedChatPartner.contains{$0.uid == user.uid}
        return isSelected
    }
}

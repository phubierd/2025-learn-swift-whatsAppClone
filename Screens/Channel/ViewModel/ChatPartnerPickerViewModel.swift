//
//  ChatPartnerPickerViewModel.swift
//  WhatsAppClone
//
//  Created by Osaretin Uyigue on 3/19/24.
//

import Foundation
import FirebaseAuth
import Combine

enum ChannelCreationRoute {
    case groupPartnerPicker
    case setUpGroupChat
}

enum ChannelContants {
    static let maxGroupParticipants = 12
}

enum ChannelCreationError:Error{
    case noChatPartner
    case failedToCreateUniqueIds
}

final class ChatPartnerPickerViewModel: ObservableObject {
    @Published var navStack = [ChannelCreationRoute]()
    @Published var selectedChatPartners = [UserItem]()
    @Published private(set) var users = [UserItem]()
    @Published var errorState:(showError:Bool,errorMessage:String) = (false,"Uh Oh")
    private var subscription:AnyCancellable?
    
    private var lastCursor:String?
    private var currentUser:UserItem?
    
    var showSelectedUsers: Bool {
        return !selectedChatPartners.isEmpty
    }
    
    var disableNextButton: Bool {
        return selectedChatPartners.isEmpty
    }
    
    var isPaginatable:Bool{
        return !users.isEmpty
    }
    
    private var isDirectChannel:Bool{
        return selectedChatPartners.count == 1
    }
    
    init(){
        listenForAuthState()
    }
    
    deinit{
        subscription?.cancel()
        subscription = nil
    }
    
    private func listenForAuthState(){
        subscription = AuthManager.shared.authState.receive(on:DispatchQueue.main).sink{[weak self] authState in
            switch authState{
            case .loggedIn(let loggedInUser):
                self?.currentUser = loggedInUser
                
                Task {
                    await self?.fetchUsers()
                }
            default:
                break
            }
        }
    }
    
    
    // MARK: - Public Methods
    func fetchUsers() async {
        do{
            let userNode = try await UserService.paginateUsers(lastCursor: lastCursor, pageSize: 5)
            var fetchedUsers = userNode.users
            guard let currentUid = Auth.auth().currentUser?.uid else {return}
            fetchedUsers = fetchedUsers.filter{$0.uid != currentUid}
            self.users.append(contentsOf: fetchedUsers)
            self.lastCursor = userNode.currentCursor
            
            print("last cursor:\(lastCursor), \(users.count)")
            
        }catch{
            print("😩 Failed to fetch users in ChatPartnerPickerViewModel,\(error.localizedDescription)")
        }
    }
    
    func deSelectAllChatPartners () {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
            self.selectedChatPartners.removeAll()
        }
    }
    
    func handleItemSelection(_ item: UserItem) {
        if isUserSelected(item) {
            guard let index = selectedChatPartners.firstIndex(where: { $0.uid == item.uid }) else { return }
            selectedChatPartners.remove(at: index)
        } else {
            guard selectedChatPartners.count < ChannelContants.maxGroupParticipants else {
                let errorMessage = "Sorry, We only allow a maximum of \(ChannelContants.maxGroupParticipants) participants in a group chat."
                showError(errorMessage)
                return
            }
            selectedChatPartners.append(item)
        }
    }
    
    func isUserSelected(_ user: UserItem) -> Bool {
        let isSelected = selectedChatPartners.contains { $0.uid == user.uid }
        return isSelected
    }
    
    func createDirectChannel (_ chatPartner:UserItem,completion:@escaping (_ newChannel:ChannelItem)-> Void){
        selectedChatPartners.append(chatPartner)
        
        Task {
            // if existing DM, get the channel info
            if let channelId = await verifyDirectChannelExist(with: chatPartner.uid){
                let snapshot = try await FirebaseConstants.ChannelsRef.child(channelId).getData()
                var channelDict = snapshot.value as! [String:Any]
                var directChannel = ChannelItem(channelDict)
                directChannel.members = selectedChatPartners
                if let currentUser {
                    directChannel.members.append(currentUser)
                }
                
                completion(directChannel)
            }else{
                
                //create a new DM with the user
                let channelCreation = createChannel(nil)
                
                switch channelCreation{
                case .success(let channel):
                    completion(channel)
                case .failure(let failure):
                    print("Failed to create a direct channel in ChatPartnerPickerViewModel,\(failure.localizedDescription)")
                    showError("Sorry! Something went wrong while we were trying to setup your chat")
                }
            }
            
            
        }
        
        
    }
    
    typealias ChannelId = String
    private func verifyDirectChannelExist(with chatPartnerId:String) async -> ChannelId?{
        guard let currentUid = Auth.auth().currentUser?.uid,
              let snapshot = try? await FirebaseConstants.UserDirectChannels.child(currentUid).child(chatPartnerId).getData(),
              snapshot.exists()
        else{
            return nil
        }
        
        let directMessageDict = snapshot.value as! [String:Bool] // channel ID exist !!!
        let channelId = directMessageDict.compactMap{$0.key}.first
        return channelId
    }
    
    private func showError(_ errorMessage:String){
        errorState.errorMessage = errorMessage
        errorState.showError = true
    }
    
    func createGroupChannel (_ groupName:String?, completion:@escaping (_ newChannel:ChannelItem)-> Void){
        let channelCreation = createChannel(groupName)
        
        switch channelCreation{
        case .success(let channel):
            completion(channel)
        case .failure(let failure):
            print("😩 Failed to create a group channel in ChatPartnerPickerViewModel,\(failure.localizedDescription)")
            showError("Sorry! Something went wrong while we were trying to setup your chat")
        }
    }
    
    private func createChannel(_ channelName:String?) -> Result<ChannelItem,Error>{
        guard !selectedChatPartners.isEmpty else {
            return .failure(ChannelCreationError.noChatPartner)
        }
        
        guard let channelId = FirebaseConstants.ChannelsRef.childByAutoId().key,
              let currentUid = Auth.auth().currentUser?.uid,
              let messageId = FirebaseConstants.MessageRef.childByAutoId().key
        else {return .failure(ChannelCreationError.failedToCreateUniqueIds)}
        
        let timeStamp = Date().timeIntervalSince1970
        var membersUid = selectedChatPartners.compactMap{$0.uid}
        membersUid.append(currentUid)
        
        let newChannelBroadcast = AdminMessageType.channelCreation.rawValue
        
        var channelIdDict:[String:Any] = [
            .id:channelId,
            .lastMessage:newChannelBroadcast,
            .creationDate:timeStamp,
            .lastMessageTimeStamp:timeStamp,
            .memberUids:membersUid,
            .membersCount:membersUid.count,
            .adminUids:[currentUid],
            .createdBy:currentUid
        ]
        
        if let channelName = channelName, !channelName.isEmptyOrWhiteSpace{
            channelIdDict[.name] = channelName
        }
        
        let messageDict:[String:Any] = [.type:newChannelBroadcast,.timeStamp:timeStamp,.ownerUid:currentUid]
        
        FirebaseConstants.ChannelsRef.child(channelId).setValue(channelIdDict)
        FirebaseConstants.MessageRef.child(channelId).child(messageId).setValue(messageDict)
        
        
        membersUid.forEach{ userId in
            //keeping an index of the channel that a specific user belongs to
            FirebaseConstants.UserChannelsRef.child(userId).child(channelId).setValue(true)
        }
        
        //makes sure that a direct channel is unique
        if isDirectChannel {
            let chatPartner = selectedChatPartners[0]
            // user-direct-channels/uid/uid/channelId
            FirebaseConstants.UserDirectChannels.child(currentUid).child(chatPartner.uid).setValue([channelId:true])
            FirebaseConstants.UserDirectChannels.child(chatPartner.uid).child(currentUid).setValue([channelId:true])
        }
        
        var newChannelItem = ChannelItem(channelIdDict)
        newChannelItem.members = selectedChatPartners
        if let currentUser {
            newChannelItem.members.append(currentUser)
        }
        return .success(newChannelItem)
    }
}

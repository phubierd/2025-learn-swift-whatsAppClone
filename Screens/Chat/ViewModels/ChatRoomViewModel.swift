//
//  ChatRoomViewModel.swift
//  WhatsAppClone
//
//  Created by Phú Chiêm on 1/12/25.
//

import Foundation
import Combine
import PhotosUI
import SwiftUI

final class ChatRoomViewModel:ObservableObject {
    @Published var textMessage = ""
    @Published var messages = [MessageItem]()
    @Published var showPhotoPicker = false
    // this array of photo picker lib
    @Published var photoPickerItems:[PhotosPickerItem] = []
    // this array of preview on chat screen
    @Published var mediaAttachments:[MediaAttachment] = []
    @Published var videoPlayerState:(show:Bool,player:AVPlayer?) = (false,nil)
    @Published var isRecordingVoiceMessage = false
    @Published var elaspedVoiceMessageTime:TimeInterval = 0
    
    private(set) var channel:ChannelItem
    private var subscriptions = Set<AnyCancellable>()
    private var currentUser:UserItem?
    
    private let voiceRecorderService = VoiceRecorderService()
    
    var showPhotoPickerPreview :Bool {
        return !mediaAttachments.isEmpty || !photoPickerItems.isEmpty
    }
    
    init(_ channel:ChannelItem){
        self.channel = channel
        listenToAuthStates()
        onPhotoPickerSelection()
        setUpVoiceRecorderListener()
    }
    
    deinit{
        subscriptions.forEach{$0.cancel()}
        subscriptions.removeAll()
        currentUser = nil
        voiceRecorderService.tearDown()
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
            self.getMessage()
            print("getAllChannelMembers :\(channel.members.map{$0.username})")
        }
    }
    
    func handleTextInputArea(_ action:TextInputArea.UserAction) {
        switch action{
        case .presentPhotoPicker:
            showPhotoPicker = true
        case .sendMessage:
            sendMessage()
        case .recordAudio:
            toggleAudioRecorder()
        }
    }
    
    private func toggleAudioRecorder(){
        if voiceRecorderService.isRecording {
            // stop recording
            voiceRecorderService.stopRecording {[weak self] audioURL, audioDuration in
                self?.createAudioAttachment(from: audioURL, audioDuration)
            }
        }else {
            // start recording
            voiceRecorderService.startRecording()
        }
    }
    
    private func createAudioAttachment(from audioURL:URL?,_ audioDuration:TimeInterval){
        guard let audioURL = audioURL else {return}
        let id = UUID().uuidString
        let audioAttachment = MediaAttachment(id: id, type: .audio(audioURL,audioDuration))
        mediaAttachments.insert(audioAttachment, at: 0)
    }
    
    private func onPhotoPickerSelection () {
        $photoPickerItems.sink{[weak self] photoItems in
            guard let self = self else {return}
            
            // remove old array, avoid duplicate photo/video on mediaAttachments
//            self.mediaAttachments.removeAll()
            
            // remove old array photo picker but not include audio file
            let audioRecordings = mediaAttachments.filter({ $0.type == .audio(.stubURL,.stubTimeInterval) })
            self.mediaAttachments = audioRecordings
            
            Task {
               await self.parsePhotoPickerItems(photoItems)
            }
        }.store(in: &subscriptions)
    }
    
    private func parsePhotoPickerItems(_ photoPickerItems:[PhotosPickerItem])async {
        for photoItem in photoPickerItems {
            if photoItem.isVideo {
                if let movie = try? await photoItem.loadTransferable(type: VideoPickerTransferable.self),
                   let thumbnail = try? await movie.url.generateVideoThumbnail(),
                   let itemIdentifier = photoItem.itemIdentifier {
                    
                    let videoAttachment = MediaAttachment(id: itemIdentifier, type: .video(thumbnail, movie.url))
                    self.mediaAttachments.insert(videoAttachment,at:0)
                }
            }else {
                guard
                let data = try? await photoItem.loadTransferable(type: Data.self),
                let thumbnail = UIImage(data:data),
                let itemIdentifier = photoItem.itemIdentifier
                else {return}
    
                let photoAttachment = MediaAttachment(id: itemIdentifier,type: .photo(thumbnail))
                self.mediaAttachments.insert(photoAttachment,at:0)
            }
        }
        
    }
    
    func dismissMediaPlayer(){
        videoPlayerState.player?.replaceCurrentItem(with: nil)
        videoPlayerState.player = nil
        videoPlayerState.show = false
    }
    
    func showMediaPlayer(_ fileURL:URL){
        videoPlayerState.show = true
        videoPlayerState.player = AVPlayer(url: fileURL)
    }
    
    func handleMediaAttachmentPreview(_ action:MediaAttachmentPreview.UserAction){
        switch action{
        case .play(let attachment):
            guard let fileURL = attachment.fileURL else {return}
            showMediaPlayer(fileURL)
        case .remove(let attachment):
            remove(attachment)
            guard let fileURL = attachment.fileURL else {return}
            if attachment.type == .audio(.stubURL,.stubTimeInterval){
                voiceRecorderService.deleteRecording(at:fileURL)
            }
        }
    }

    private func remove(_ item:MediaAttachment){
        guard let attachmentIndex = mediaAttachments.firstIndex(where: { attachment in
            item.id == attachment.id
        }) else {return}
        mediaAttachments.remove(at: attachmentIndex)
        
        guard let photoIndex = photoPickerItems.firstIndex(where: { photo in
            item.id == photo.itemIdentifier
        }) else {return}
        photoPickerItems.remove(at: photoIndex)
    }
    
    private func setUpVoiceRecorderListener(){
        voiceRecorderService.$isRecording.receive(on: DispatchQueue.main)
            .sink{ [weak self] isRecording in
                self?.isRecordingVoiceMessage = isRecording
            }.store(in: &subscriptions)
        
        voiceRecorderService.$elaspedTime.receive(on: DispatchQueue.main)
            .sink { [weak self]elaspedTime in
                self?.elaspedVoiceMessageTime = elaspedTime
            }.store(in: &subscriptions)
    }
}

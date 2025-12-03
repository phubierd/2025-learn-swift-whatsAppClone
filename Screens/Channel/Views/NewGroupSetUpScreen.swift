//
//  NewGroupSetUpScreen.swift
//  WhatsAppClone
//
//  Created by Osaretin Uyigue on 3/20/24.
//

import SwiftUI

struct NewGroupSetUpScreen: View {
    @State private var channelName = ""
    @ObservedObject var viewModel: ChatPartnerPickerViewModel
    
    var onCreate:(_ newChannel:ChannelItem) -> Void
    
    var body: some View {
        List {
            Section {
                channelSetUpHeaderView()
            }
            
            Section {
                Text("Disappearing Messages")
                Text("Group Permissions")
            }
            
            Section {
                SelectedChatPartnerView(users: viewModel.selectedChatPartners) { user in
                    viewModel.handleItemSelection(user)
                }
            } header: {
                
                let count = viewModel.selectedChatPartners.count
                let maxCount = ChannelContants.maxGroupParticipants
                Text("Participants: \(count) OF \(maxCount)")
                    .bold()
            }
            .listRowBackground(Color.clear)

        }
        .navigationTitle("New Group")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            trailNavItem()
        }
    }
    
    private func channelSetUpHeaderView() -> some View {
        HStack {
            profileImageView()
            
            TextField(
                "",
                text: $channelName,
                prompt: Text("Group Name (optional)"),
                axis: .vertical
            )
        }
    }
    
    private func profileImageView() -> some View {
        Button {
            
        }label: {
            ZStack{
                Image(systemName: "camera.fill")
                    .imageScale(.large)
            }
            .frame(width: 60,height: 60)
            .background(Color(.systemGray5))
            .clipShape(Circle())
        }
    }
    
    @ToolbarContentBuilder
    private func trailNavItem() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Create") {
                viewModel.createGroupChannel(channelName, completion: onCreate)
            }
            .bold()
            .disabled(viewModel.disableNextButton)
        }
    }
}

#Preview {
    NavigationStack {
        NewGroupSetUpScreen(viewModel: ChatPartnerPickerViewModel()){
            channel in
            
        }
    }
}

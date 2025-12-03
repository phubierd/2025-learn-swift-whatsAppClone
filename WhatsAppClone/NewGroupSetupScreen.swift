//
//  NewGroupSetupScreen.swift
//  WhatsAppClone
//
//  Created by Phú Chiêm on 29/11/25.
//

import SwiftUI

struct NewGroupSetupScreen: View {
    @State private var channelName = ""
    
    @ObservedObject var viewModel:ChatPartnerPickerViewModel
    
    var body: some View {
            List{
                Section{
                    channelSetupHeaderView()
                }
                
                Section{
                    Text("Disappearing Messages")
                    Text("Group Permissions")
                }
                
                Section{
                    SelectedChatPartnerView(users: viewModel.selectedChatPartner){
                        user in
                        viewModel.handleItemSelection(user)
                    }
                }header: {
                    let count = viewModel.selectedChatPartner.count
                    let maxCount = ChannelConstants.maxGroupParticipants
                    
                    Text("Participants: \(count) OF \(maxCount)")
                        .bold()
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                trailingNavItem()
            }
        }
        
    
    
    private func channelSetupHeaderView () -> some View {
        HStack{
            profileImageView()
                
            TextField(
                "",
                text:$channelName,
                prompt: Text("Group Name (optional)"),
                axis: .vertical
            )
        }
    }
    
    private func profileImageView() -> some View {
        Button {
            
        }label:{
            ZStack{
                Image(systemName: "camera.fill")
                    .imageScale(.large)
            }
            .frame(width:60,height:60)
            .background(Color(.systemGray5))
            .clipShape(Circle())
            
        }
    }
    
    @ToolbarContentBuilder
    private func trailingNavItem() -> some ToolbarContent{
        ToolbarItem(placement:.topBarTrailing){
            Button("Create"){
                
            }
            .bold()
            .disabled(viewModel.disableNextButton)
        }
    }
}

extension NewGroupSetupScreen {
    
}

#Preview {
    NavigationStack{
        NewGroupSetupScreen(viewModel: ChatPartnerPickerViewModel())
    }
}

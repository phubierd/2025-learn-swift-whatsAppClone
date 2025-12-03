//
//  GroupPartnersPickerScreen.swift
//  WhatsAppClone
//
//  Created by Phú Chiêm on 27/11/25.
//

import SwiftUI

struct GroupPartnersPickerScreen: View {
    @ObservedObject var viewModel:ChatPartnerPickerViewModel
    
    @State private var searchText: String = ""
    
    var body: some View {
            List{
                if viewModel.showSelectedUsers {
                    SelectedChatPartnerView(users:viewModel.selectedChatPartner){ user in
                        viewModel.handleItemSelection(user)
                    }
                }
                
                Section{
                    ForEach(UserItem.placeholders){item in
                        Button{
                            viewModel.handleItemSelection(item)
                        }label:{
                            chatPartnerRowView(item)
                        }
                    }
                }
            }
//            .navigationTitle("Add Participants")
            .navigationBarTitleDisplayMode(.inline)
            .animation(.easeInOut,value:viewModel.showSelectedUsers)
            .searchable(text: $searchText,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search name or number"
            )
            .toolbar{
                titleView()
                trailingNavItem()
            }
        
    }
    
    private func chatPartnerRowView(_ user:UserItem) -> some View{
        ChatPartnerRowView(user: user){
           Spacer()
            let isSelected = viewModel.isUserSelected(user)
            let imageName = isSelected ? "checkmark.circle.fill" : "circle"
            let foregroundStyle = isSelected ? Color.blue : Color(.systemGray4)
            Image(systemName: imageName)
                .foregroundStyle(foregroundStyle)
                .imageScale(.large)
        }
    }
}

extension GroupPartnersPickerScreen{
    @ToolbarContentBuilder
    private func titleView() -> some ToolbarContent{
        ToolbarItem(placement:.principal ){
            VStack{
                Text("Add Participants")
                    .bold()
                
                let count = viewModel.selectedChatPartner.count
                let maxCount = ChannelConstants.maxGroupParticipants
                
                Text("\(count)/\(maxCount)")
                    .foregroundStyle(.gray)
                    .font(.footnote)
            }
        }
    }
    
    @ToolbarContentBuilder
    private func trailingNavItem () -> some ToolbarContent{
        ToolbarItem(placement:.topBarTrailing){
            Button {
                viewModel.navStack.append(.setUpGroupChat)
            }label: {
                Text("Next")
                    .bold()
            }
            .disabled(viewModel.disableNextButton)
        }
    }
}


#Preview {
    NavigationStack(){
        GroupPartnersPickerScreen(viewModel: ChatPartnerPickerViewModel())
    }
}

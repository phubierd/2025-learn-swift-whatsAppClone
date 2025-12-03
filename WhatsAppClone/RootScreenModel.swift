//
//  RootScreenModel.swift
//  WhatsAppClone
//
//  Created by Phú Chiêm on 27/11/25.
//

import Foundation
import Combine

final class RootScreenModel:ObservableObject {
    
    @Published private(set) var authState = AuthState.pending
    
    private var cancallable:AnyCancellable?
    
    init(){
        cancallable = AuthManager.shared.authState.receive(on:DispatchQueue.main)
            .sink{
                [weak self] lastestAuthState in
                print("lastest auth state:\(lastestAuthState)")
                self?.authState = lastestAuthState
            }
        
//        AuthManager.testAccounts.forEach{ email in
//            registerTestAccount(with:email)
//        }
    }
    
//    private func registerTestAccount(with email:String){
//        Task{
//            let username = email.replacingOccurrences(of: "@test.com", with: "")
//            try? await AuthManager.shared.createAcount(for: username, with: email, and: "123123")
//        }
//    }
}


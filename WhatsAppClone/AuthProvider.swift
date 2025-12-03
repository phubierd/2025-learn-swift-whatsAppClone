//
//  AuthProvider.swift
//  WhatsAppClone
//
//  Created by Phú Chiêm on 27/11/25.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseDatabase

enum AuthState{
    case pending,loggedIn(UserItem),loggedOut
}

protocol AuthProvider{
    
    static var shared:AuthProvider { get }
    
    var authState: CurrentValueSubject<AuthState,Never>{get}
    
    func autoLogin() async
    func login (with email:String, and password:String) async throws
    func createAcount(for username:String, with email:String, and password:String) async throws
    func logOut() async throws
}

enum AuthError:Error{
    case accountCreationFailed(_ description:String)
    case failedToSaveUserInfo(_ description:String)
    case failedToLogin(_ description:String)
}

extension AuthError:LocalizedError{
    var errorDescription: String?{
        switch self {
        case .accountCreationFailed(let description):
            return description
        case .failedToSaveUserInfo(let description):
            return description
        case .failedToLogin(let description):
            return description
        }
    }
}

final class AuthManager:AuthProvider {
    
    private init(){
        Task {
            await autoLogin()
        }
    }
    
    static let shared: AuthProvider = AuthManager()
    
    var authState = CurrentValueSubject<AuthState, Never>(.pending)
    
    func autoLogin() async {
        if Auth.auth().currentUser == nil {
            authState.send(.loggedOut)
        }else{
            fetchCurrentUserInfo()
        }
    }
    
    func login(with email: String, and password: String) async throws {
        do{
            let authResult = try await Auth.auth().signIn(withEmail: email,password: password)
            
            fetchCurrentUserInfo()
            
            print("🔐 Successfully login user (authResult):\(authResult)")
        }catch{
          print("🔐 Failed to Login user: \(error.localizedDescription)")
            throw AuthError.failedToLogin(error.localizedDescription)
        }
            
    }
    
    func createAcount(for username: String, with email: String, and password: String) async throws {
        // invoke firebase create account method
        // store the new user info in our database
        do{
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            let uid = authResult.user.uid
            let newUser = UserItem(uid: uid, username: username, email: email)
            
            try await saveUserInfoDatabase(user: newUser)
            
            self.authState.send(.loggedIn(newUser))
        }catch{
            print("🔐 Failed to Create an account: \(error.localizedDescription)")
            throw AuthError.accountCreationFailed(error.localizedDescription)
        }
    }
    
    func logOut() async throws {
        do{
            try Auth.auth().signOut()
            authState.send(.loggedOut)
            print("🔐 successfully logged out")
        }catch{
            print("🔐 Failed to Logged out current user: \(error.localizedDescription)")
        }
    }
    
    
    
}

extension AuthManager{
    private func saveUserInfoDatabase(user:UserItem) async throws{
        do{
            let userDictionary:[String:Any] = [.uid : user.uid, .username : user.username,.email : user.email]
            
            try await FirebaseConstants.UserRef.child(user.uid).setValue(userDictionary)
        }catch{
            print("🔐 Failed to save user info: \(error.localizedDescription)")
            throw AuthError.failedToSaveUserInfo(error.localizedDescription)
        }
        
    }
    
    private func fetchCurrentUserInfo() {
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        print("currentUID:\(currentUid)")
        FirebaseConstants.UserRef.child(currentUid).observe(.value){ [weak self] snapshot in
            print("snapshot:\(snapshot)")
            guard let userDict = snapshot.value as? [String:Any] else {return}
            print("userDictionary:\(userDict)")
            let loggedInUser = UserItem(dictionary: userDict)
            self?.authState.send(.loggedIn(loggedInUser))
            print("🔐 \(loggedInUser.username) is logged in" )
        }withCancel: { error in
            print("Failed to get current user info")
        }
    }
}

extension AuthManager {
    static let testAccounts:[String] = [
        "QaUser1@test.com",
        "QaUser2@test.com",
        "QaUser3@test.com",
        "QaUser4@test.com",
        "QaUser5@test.com",
        "QaUser6@test.com",
        "QaUser7@test.com",
        "QaUser8@test.com",
        "QaUser9@test.com",
        "QaUser10@test.com",
        "QaUser11@test.com",
        "QaUser12@test.com",
        "QaUser13@test.com",
        "QaUser14@test.com",
        "QaUser15@test.com",
        "QaUser16@test.com",
        "QaUser17@test.com",
        "QaUser18@test.com",
        "QaUser19@test.com",
        "QaUser20@test.com",
        "QaUser21@test.com",
        "QaUser22@test.com",
        "QaUser23@test.com",
        "QaUser24@test.com",
        "QaUser25@test.com",
        "QaUser26@test.com",
        "QaUser27@test.com",
        "QaUser28@test.com",
        "QaUser29@test.com",
        "QaUser30@test.com",
        "QaUser31@test.com",
        "QaUser32@test.com",
        "QaUser33@test.com",
        "QaUser34@test.com",
        "QaUser35@test.com",
        "QaUser36@test.com",
        "QaUser37@test.com",
        "QaUser38@test.com",
        "QaUser39@test.com",
        "QaUser40@test.com",
        "QaedaUser41@test.com",
        "QaUser42@test.com",
        "QaUser43@test.com",
        "QaUser44@test.com",
        "QaUser45@test.com",
        "QaUser46@test.com",
        "QaUser47@test.com",
        "QaUser48@test.com",
        "QaUser49@test.com",
        "QaUser50@test.com"
    ]
}



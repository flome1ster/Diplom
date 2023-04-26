//
//  MainMessagesViewModel.swift
//  Diplom
//
//  Created by Yaroslav Derbyshev on 04.05.2023.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift
class MainMessagesViewModel: ObservableObject{
    @Published var errorMessage = ""
    @Published var chatUser: ChatUser?
    
    @Published var isUserCurrentlyLoggedOut = false
    @Published var recentMessages = [RecentMessage]()
    init(){
        DispatchQueue.main.async {
            self.isUserCurrentlyLoggedOut = FirebaseManager.shared.auth.currentUser?.uid == nil
        }
        fetchCurrentUser()
        
        fetchRecentMessages()
    }
    
    private var firestoreListener: ListenerRegistration?
    
    func fetchRecentMessages(){ //Вывод последнего сообщения на главный экран
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {return}
        firestoreListener?.remove()
        self.recentMessages.removeAll()
        firestoreListener = FirebaseManager.shared.firestore
            .collection(FirebaseConstants.recentMessages)
            .document(uid)
            .collection(FirebaseConstants.messages)
            .order(by: FirebaseConstants.timestamp)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    self.errorMessage = "Не удалось получить последние сообщения: \(error)"
                    print(error)
                    return
                }
                querySnapshot?.documentChanges.forEach({ change in
                 
                        let docId = change.document.documentID
                    if let index = self.recentMessages.firstIndex(where: { rm in
                        return rm.id == docId
                    }) {
                        self.recentMessages.remove(at: index)
                    }
                    do {
                        let rm = try change.document.data(as: RecentMessage.self)
                        self.recentMessages.insert(rm, at: 0)
                        print("Successed with fetching recent messages")
                    } catch {
                        print(error)
                        print("Failed to fetch recent messages")
                    }

                })
            }
    }
    func fetchCurrentUser() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            self.errorMessage = "Could not find firebase uid"
            return
        }
        
        FirebaseManager.shared.firestore.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                self.errorMessage = "Failed to fetch current user: \(error)"
                print("Failed to fetch current user:", error)
                return
            }
            
            guard let data = snapshot?.data() else {
                self.errorMessage = "No data found"
                return
                
            }
            
            self.chatUser = .init(data: data)
            FirebaseManager.shared.currentUser = self.chatUser
        }
    }
    func handleSignOut(){
        isUserCurrentlyLoggedOut.toggle()
        try? FirebaseManager.shared.auth.signOut()
    }
}

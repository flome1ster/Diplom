//
//  ChatLogViewModel.swift
//  Diplom
//
//  Created by Yaroslav Derbyshev on 26.05.2023.
//

import Foundation
import SwiftUI
import Firebase

class ChatLogViewModel: ObservableObject{ //Move to ViewModel
    @Published var chatText = ""
    @Published var errorMessage = ""
    @Published var chatMessages = [ChatMessage]()
    var chatUser: ChatUser?
    init(chatUser: ChatUser?){
        self.chatUser = chatUser
        fetchMessages()
    }
    var firestoreListener: ListenerRegistration?
    func fetchMessages(){
        
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else {return}
        guard let toId = chatUser?.uid else {return}
        firestoreListener?.remove()
        chatMessages.removeAll()
       firestoreListener = FirebaseManager.shared.firestore
            .collection(FirebaseConstants.messages)
            .document(fromId)
            .collection(toId)
            .order(by: FirebaseConstants.timestamp)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    self.errorMessage = "Не удалось захватить сообщения: \(error)"
                    print(error)
                    return
                }
                querySnapshot?.documentChanges.forEach({ change in
                    if change.type == .added {
                        do {
                            let cm = try change.document.data(as: ChatMessage.self)
                                self.chatMessages.append(cm)
                                print("Appending chatMessage in ChatLogView: \(Date())")
                            
                        } catch {
                            print("Failed to decode message: \(error)")
                        }
                    }
                })
                DispatchQueue.main.async {
                    self.count += 1
                }
                
            }
    }
    func handleSend(){
        print(chatText)
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else {return}
        guard let toId = chatUser?.uid else {return}
        let document = FirebaseManager.shared.firestore
            .collection("messages")
            .document(fromId)
            .collection(toId)
            .document()
        let messageData = [FirebaseConstants.fromId : fromId, FirebaseConstants.toId : toId, FirebaseConstants.text: self.chatText, "timestamp": Timestamp()] as [String : Any]
        document.setData(messageData){error in
            if let error = error{
                print(error)
                self.errorMessage = "Не удалось отправить сообщение в Firestore \(error)"
                return
            }
            print("Успешное сохранение отправленного сообщения")
            self.persistRecentMessage()
            self.chatText = ""
            self.count += 1
        }
        let recipientMessageDocument = FirebaseManager.shared.firestore
            .collection("messages")
            .document(toId)
            .collection(fromId)
            .document()
        recipientMessageDocument.setData(messageData){error in
            if let error = error{
                print(error)
                self.errorMessage = "Не удалось отправить сообщение в Firestore \(error)"
                return
            }
            print("Получатель сохранил сообщение")
        }
        
    }
    func persistRecentMessage() {
        guard let chatUser = chatUser else { return }
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {return}
        guard let toId = self.chatUser?.uid else {return}
        let document = FirebaseManager.shared.firestore
            .collection(FirebaseConstants.recentMessages)
            .document(uid)
            .collection(FirebaseConstants.messages)
            .document(toId)
        let data = [
            FirebaseConstants.timestamp: Timestamp(),
            FirebaseConstants.text: self.chatText,
            FirebaseConstants.fromId: uid,
            FirebaseConstants.toId: toId,
            FirebaseConstants.profileImageUrl: chatUser.profileImageUrl,
            FirebaseConstants.email: chatUser.email
        ] as [String : Any]
        //Poluchatel dalee
        document.setData(data) { error in
            if let error = error {
                self.errorMessage = "Не удалось сохранить ваше последнее сообщение: \(error)"
                print("Не удалось сохранить последнее сообщение: \(error)")
                return
            }
        }
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        let recipientRecentMessageDictionary = [
            FirebaseConstants.timestamp: Timestamp(),
            FirebaseConstants.text: self.chatText,
            FirebaseConstants.fromId: uid,
            FirebaseConstants.toId: toId,
            FirebaseConstants.profileImageUrl: currentUser.profileImageUrl,
            FirebaseConstants.email: currentUser.email
        ] as [String : Any]
        
        FirebaseManager.shared.firestore
            .collection(FirebaseConstants.recentMessages)
            .document(toId)
            .collection(FirebaseConstants.messages)
            .document(currentUser.uid)
            .setData(recipientRecentMessageDictionary) { error in
                if let error = error {
                    print("Не удалось сохранить последнее сообщение партнера диалога: \(error)")
                    return
                }
            }
    }
    @Published var count = 0
}

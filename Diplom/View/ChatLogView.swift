//
//  ChatLogView.swift
//  Diplom
//
//  Created by Yaroslav Derbyshev on 04.05.2023.
// lesson 11?

import SwiftUI
import Firebase

struct ChatLogView: View {
    @ObservedObject var vm: ChatLogViewModel
    var body: some View {
        ZStack{
            ZStack{
                messagesView
                Text(vm.errorMessage)
            }
            VStack(spacing: 0){
                Spacer()
                Divider()
                    .offset(y: -5)
                chatBottomBar
                    .background(Color.white)
            }
        }
        .navigationTitle(vm.chatUser?.email ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear{
                vm.firestoreListener?.remove()
            }

    }
    static let emptyScrollToString = "Empty"
    private var messagesView: some View{
        ScrollView {
            ScrollViewReader { scrollViewProxy in
                VStack{
                    ForEach(vm.chatMessages) { message in
                        MessageView(message: message)
                        
                    }
                    HStack{
                        Spacer()
                    }.id(Self.emptyScrollToString)
                }
                    .onReceive(vm.$count) { _ in
                        withAnimation(.easeOut(duration: 0.5)) {
                            scrollViewProxy.scrollTo(Self.emptyScrollToString, anchor: .bottom)
                        }
                        
                    }
            }

        }
        .background(Color(.init(white: 0.95, alpha: 1)))
        .padding(.bottom, 65)
        .clipped()
    }
    private var chatBottomBar: some View{
        HStack(spacing: 16){
//            Image(systemName: "photo.on.rectangle.angled")
//                .font(.system(size: 25))
//                .foregroundColor(Color(.darkGray))
            ZStack{
            DescriptionPlaceholder()
                TextEditor(text: $vm.chatText)
                    .opacity(vm.chatText.isEmpty ? 0.5: 1)
            }
            .frame(height: 40)
            Button {
                vm.handleSend()
            } label: {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 25))
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .frame(width: 48, height: 48)
            .background(Color.blue)
            .cornerRadius(24)

        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}
struct MessageView: View{
    let message: ChatMessage
    var body: some View{
        VStack{
            if message.fromId == FirebaseManager.shared.auth.currentUser?.uid {
                HStack{
                    Spacer()
                    HStack{
                        Text(message.text)
                            .foregroundColor(.white)
                    }.padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            else {
                HStack{
                    
                    HStack{
                        Text(message.text)
                            .foregroundColor(.black)
                    }.padding()
                        .background(Color.white)
                        .cornerRadius(8)
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}
private struct DescriptionPlaceholder: View {
    var body: some View {
        HStack {
            Text("Введите сообщение...")
                .foregroundColor(Color(.gray))
                .font(.system(size: 17))
                .padding(.leading, 5)
                .padding(.top, -5)
            Spacer()
        }
    }
}
struct ChatLogView_Previews: PreviewProvider {
    static var previews: some View {
        MainMessagesView()
    }
}

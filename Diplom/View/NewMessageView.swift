//
//  NewMessageView.swift
//  Diplom
//
//  Created by Yaroslav Derbyshev on 04.05.2023.
//

import SwiftUI
import SDWebImageSwiftUI

struct NewMessageView: View {
    let didSelectNewUser: (ChatUser) -> ()
    
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var vm = CreateNewMessageViewModel()
    var body: some View {
        NavigationView{
            ScrollView{
                Text(vm.errorMessage)
                ForEach(vm.users) { user in
                    Button {
                        didSelectNewUser(user)
                    } label: {
                        HStack{
                            WebImage(url: URL(string: user.profileImageUrl))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipped()
                                .cornerRadius(50)
                                .overlay(RoundedRectangle(cornerRadius: 50)
                                    .stroke(Color(.label), lineWidth: 1))
                            Text(user.email)
                                .foregroundColor(.black)
                            Spacer()
                        }.padding(.horizontal)
                        
                    }
                    Divider()
                        .padding(.vertical, 2)
                    
                    
                }
            } .navigationTitle(Text("Новое сообщение"))
                .toolbar{
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Text("Отмена")
                        }

                    }
                }
           
        }
    }
}

struct NewMessageView_Previews: PreviewProvider {
    static var previews: some View {
        //NewMessageView(didSelectNewUser: {user in print (user.email)})
        MainMessagesView()
    }
}

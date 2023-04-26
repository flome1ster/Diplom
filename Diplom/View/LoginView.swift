//
//  ContentView.swift
//  Diplom
//
//  Created by Yaroslav Derbyshev on 26.04.2023.
//

import SwiftUI
import Firebase
import FirebaseStorage
struct LoginView: View {
    let didCompleteLoginProcess: () -> ()
    @State private var isLoginMode = false
    @State private var email = ""
    @State private var password = ""
    @State var loginStatusMessage = ""
    @State private var shouldShowImagePicker = false
    @State var image: UIImage?
    var body: some View {
        NavigationView{
            ScrollView{
                VStack(spacing: 16){
                    Picker(
                        selection: $isLoginMode,
                        label: Text("Picker here")
                    ){
                        Text("Войти")
                            .tag(true)
                        Text("Создать аккаунт")
                            .tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    if !isLoginMode{
                        Button{
                            shouldShowImagePicker.toggle()
                        } label: {
                            VStack{
                                if let image = self.image{
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 128, height: 128)
                                        .cornerRadius(64)
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 64))
                                        .foregroundColor(.black)
                                        .padding()
                                }
                            }
                            .overlay(RoundedRectangle(cornerRadius: 64)
                                .stroke(Color.black, lineWidth: 3)
                            )
                            .padding()
                            
                        }
                    }
                    Group{
                        TextField("E-Mail", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        SecureField("Пароль", text: $password)
                    }
                    .padding(12)
                    .background(Color.white)
                    
                    Button{
                        handleAction()
                    }
                label:{
                    HStack{
                        Spacer()
                        Text(isLoginMode ? "Войти " : "Создать аккаунт")
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.vertical, 10)
                        Spacer()
                    }.background(Color.blue)
                }
                    Text(self.loginStatusMessage)
                        .foregroundColor(.red)
                }
                .padding()
                
            }
            .navigationTitle(isLoginMode ? "Войти" : "Создать аккаунт")
            .background(Color(.init(white: 0, alpha: 0.05))
                .ignoresSafeArea(.all))
            
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: nil){
            ImagePicker(image: $image)
        }
    }
    private func handleAction(){
        if isLoginMode{
            loginFunction()
        }
        else{
            createNewAccount()
            
        }
    }
    private func loginFunction(){
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) { result, err in
            if let err = err {
                print("Failed to login:", err)
                self.loginStatusMessage = "Не удалось авторизоваться: \(err)"
                return
            }
            print("Successfully logged in: \(result?.user.uid ?? "")")
            self.loginStatusMessage = "Успешная авторизация: \(result?.user.uid ?? "")"
            self.didCompleteLoginProcess()
        }
    }
    
    private func createNewAccount(){
        if self.image == nil {
            self.loginStatusMessage = "Вы должны загрузить фото профиля"
            return
        }
        FirebaseManager.shared.auth.createUser(withEmail: email, password: password) {
            result, err in
            if let err = err {
                print("Failed to create user:", err)
                self.loginStatusMessage = "Не удалось создать пользователя: \(err)"
                return
            }
            print("Successfully created user: \(result?.user.uid ?? "")")
            self.loginStatusMessage = "Успешная регистрация пользователя: \(result?.user.uid ?? "")"
            self.persistImageToStorage()
        }
    }
    private func persistImageToStorage(){
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid
        else { return }
        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else {return}
        ref.putData(imageData, metadata: nil) { metadata, err in
            if let err = err {
                self.loginStatusMessage = "Не удалось загрузить изображение: \(err)"
                return
            }
            ref.downloadURL{ url, err in
                if let err = err {
                    self.loginStatusMessage = "Не удалось получить url: \(err)"
                    return
                }
                self.loginStatusMessage = "Успешно сохранило изображение с адресом: \(url?.absoluteString ?? "")"
                print(url?.absoluteString ?? "")
                guard let url = url else {return}
                self.storeUserInformation(imageProfileUrl: url)
            }
        }
    }
    private func storeUserInformation(imageProfileUrl: URL){
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let userData = [FirebaseConstants.email: self.email, FirebaseConstants.uid: uid, FirebaseConstants.profileImageUrl: imageProfileUrl.absoluteString]
        FirebaseManager.shared.firestore.collection("users")
            .document(uid).setData(userData){ err in
                if let err = err {
                    print(err)
                    self.loginStatusMessage = "\(err)"
                    return
                }
                print("Success")
                self.didCompleteLoginProcess()
            }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(didCompleteLoginProcess: {
            
        })
    }
}

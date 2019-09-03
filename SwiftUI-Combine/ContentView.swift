//
//  ContentView.swift
//  SwiftUI-Combine
//
//  Created by Peter Friese on 02/09/2019.
//  Copyright © 2019 Google LLC. All rights reserved.
//

import SwiftUI
import Combine

class UserModel: ObservableObject {
  @Published var userName = ""
  @Published var password = ""
  @Published var passwordAgain = ""
  @Published var valid = false
}

struct ContentView: View {
  
  @ObservedObject private var userModel = UserModel()
  
  var body: some View {
    Form {
      Section {
        TextField("Username", text: $userModel.userName)
          .autocapitalization(.none)
      }
      Section {
        SecureField("Password", text: $userModel.password)
        SecureField("Password again", text: $userModel.passwordAgain)
      }
      Section {
        Button(action: { }) {
          Text("Sign up")
        }.disabled(!userModel.valid)
      }
    }
  }
  
}
  
struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

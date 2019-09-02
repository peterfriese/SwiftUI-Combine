//
//  ContentView.swift
//  SwiftUI-Combine
//
//  Created by Peter Friese on 02/09/2019.
//  Copyright © 2019 Google LLC. All rights reserved.
//

import SwiftUI

struct ContentView: View {
  @State private var userName = ""
  @State private var password = ""
  @State private var passwordAgain = ""
  @State private var valid = false
  
  var body: some View {
    Form {
      Section {
        TextField("Username", text: $userName)
          .autocapitalization(.none)
      }
      Section {
        SecureField("Password", text: $password)
        SecureField("Password again", text: $passwordAgain)
      }
      Section {
        Button(action: { }) {
          Text("Sign up")
        }.disabled(!valid)
      }
    }
  }
  
}
  
struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

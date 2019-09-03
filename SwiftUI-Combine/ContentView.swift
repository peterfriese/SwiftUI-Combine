//
//  ContentView.swift
//  SwiftUI-Combine
//
//  Created by Peter Friese on 02/09/2019.
//  Copyright © 2019 Google LLC. All rights reserved.
//

import SwiftUI
import Combine
import Navajo_Swift

class UserModel: ObservableObject {
  // input
  @Published var userName = ""
  @Published var password = ""
  @Published var passwordAgain = ""
  
  // output
  @Published var userNameMessage = ""
  @Published var passwordMessage = ""
  @Published var valid = false

  private var cancellableSet: Set<AnyCancellable> = []
  
  private var isUserNameValidPublisher: AnyPublisher<Bool, Never> {
    $userName
      .debounce(for: 0.8, scheduler: RunLoop.main)
      .removeDuplicates()
      .map { input in
        return input.count >= 3
      }
      .eraseToAnyPublisher()
  }
  
  private var isPasswordEmptyPublisher: AnyPublisher<Bool, Never> {
    $password
      .debounce(for: 0.8, scheduler: RunLoop.main)
      .removeDuplicates()
      .map { password in
        return password == ""
      }
      .eraseToAnyPublisher()
  }

  private var isPasswordsEqualPublisher: AnyPublisher<Bool, Never> {
    Publishers.CombineLatest($password, $passwordAgain)
      .debounce(for: 0.2, scheduler: RunLoop.main)
      .map { password, passwordAgain in
        return password == passwordAgain
      }
      .eraseToAnyPublisher()
  }
  
  private var passwordStrengthPublisher: AnyPublisher<PasswordStrength, Never> {
    $password
      .debounce(for: 0.2, scheduler: RunLoop.main)
      .removeDuplicates()
      .map { input in
        return Navajo.strength(ofPassword: input)
      }
      .eraseToAnyPublisher()
  }
  
  private var isPasswordStrongEnoughPublisher: AnyPublisher<Bool, Never> {
    passwordStrengthPublisher
      .map { strength in
        print(Navajo.localizedString(forStrength: strength))
        switch strength {
        case .reasonable, .strong, .veryStrong:
          return true
        default:
          return false
        }
      }
      .eraseToAnyPublisher()
  }
  
  enum PasswordCheck {
    case valid
    case empty
    case noMatch
    case notStrongEnough
  }
  
  private var isPasswordValidPublisher: AnyPublisher<PasswordCheck, Never> {
    Publishers.CombineLatest3(isPasswordEmptyPublisher, isPasswordsEqualPublisher, isPasswordStrongEnoughPublisher)
      .map { passwordIsEmpty, passwordsAreEqual, passwordIsStrongEnough in
        if (passwordIsEmpty) {
          return .empty
        }
        else if (!passwordsAreEqual) {
          return .noMatch
        }
        else if (!passwordIsStrongEnough) {
          return .notStrongEnough
        }
        else {
          return .valid
        }
      }
      .eraseToAnyPublisher()
  }
  
  private var isFormValidPublisher: AnyPublisher<Bool, Never> {
    Publishers.CombineLatest(isUserNameValidPublisher, isPasswordValidPublisher)
      .map { userNameIsValid, passwordIsValid in
        return userNameIsValid && (passwordIsValid == .valid)
      }
    .eraseToAnyPublisher()
  }
  
  init() {
    isUserNameValidPublisher
      .receive(on: RunLoop.main)
      .map { valid in
        valid ? "" : "User name must at leat have 3 characters"
      }
      .assign(to: \.userNameMessage, on: self)
      .store(in: &cancellableSet)
    
    isPasswordValidPublisher
      .receive(on: RunLoop.main)
      .map { passwordCheck in
        switch passwordCheck {
        case .empty:
          return "Password must not be empty"
        case .noMatch:
          return "Passwords don't match"
        case .notStrongEnough:
          return "Password not strong enough"
        default:
          return ""
        }
      }
      .assign(to: \.passwordMessage, on: self)
      .store(in: &cancellableSet)

    isFormValidPublisher
      .receive(on: RunLoop.main)
      .assign(to: \.valid, on: self)
      .store(in: &cancellableSet)
  }

}

struct ContentView: View {
  
  @ObservedObject private var userModel = UserModel()
  
  var body: some View {
    Form {
      Section(footer: Text(userModel.userNameMessage).foregroundColor(.red)) {
        TextField("Username", text: $userModel.userName)
          .autocapitalization(.none)
      }
      Section(footer: Text(userModel.passwordMessage).foregroundColor(.red)) {
        SecureField("Password", text: $userModel.password)
        SecureField("Password again", text: $userModel.passwordAgain)
      }
      Section {
        Button(action: { }) {
          Text("Login")
        }.disabled(!self.userModel.valid)
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

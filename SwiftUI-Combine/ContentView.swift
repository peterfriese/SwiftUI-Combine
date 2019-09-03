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
  @Published var userName = ""
  @Published var password = ""
  @Published var passwordAgain = ""
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

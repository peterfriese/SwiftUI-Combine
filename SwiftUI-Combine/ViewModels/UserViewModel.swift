//
//  UserViewModel.swift
//  SwiftUI-Combine
//
//  Created by Peter Friese on 11/09/2019.
//  Copyright © 2019 Google LLC. All rights reserved.
//

import Foundation
import Combine
import Navajo_Swift

class UserViewModel: ObservableObject {
  // input
  @Published var username = ""
  @Published var password = ""
  @Published var passwordAgain = ""
  
  // output
  @Published var usernameMessage = ""
  @Published var passwordMessage = ""
  @Published var isValid = false

  private var cancellableSet: Set<AnyCancellable> = []
  
  private var isUsernameValidPublisher: AnyPublisher<Bool, Never> {
    $username
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

  private var arePasswordsEqualPublisher: AnyPublisher<Bool, Never> {
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
    Publishers.CombineLatest3(isPasswordEmptyPublisher, arePasswordsEqualPublisher, isPasswordStrongEnoughPublisher)
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
    Publishers.CombineLatest(isUsernameValidPublisher, isPasswordValidPublisher)
      .map { userNameIsValid, passwordIsValid in
        return userNameIsValid && (passwordIsValid == .valid)
      }
    .eraseToAnyPublisher()
  }
  
  init() {
    isUsernameValidPublisher
      .receive(on: RunLoop.main)
      .map { valid in
        valid ? "" : "User name must at least have 3 characters"
      }
      .assign(to: \.usernameMessage, on: self)
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
      .assign(to: \.isValid, on: self)
      .store(in: &cancellableSet)
  }

}

//
//  InputView.swift
//  NotificationsDemo
//
//  Created by Luc Rieffel on 4/5/25.
//

import SwiftUI

struct InputView: View {
    @Binding var text: String
    var type: UserFormType

    var body: some View {
        VStack (alignment: .leading, spacing:5){
            Text("\(type.title)")
                .foregroundColor(Color(.darkGray))
                .fontWeight(.semibold)
                .font(.callout)
            
            if type.isSecureField {
                VStack(alignment: .leading) {
                    //if isSecure {
                        SecureField("\(type.title)", text: $text)
                            //.focused($focusedField, equals: .maskedPassword)
                           
                   // } else {
//                        TextField("\(type.title)", text: $text)
//                            .focused($focusedField, equals: .unmaskedPassword)
//                    }
                }
                .font(.system(size: 14))
                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .overlay {
//                    HStack {
//                        Spacer()
//                        Button("", systemImage: isSecure ? "eye.fill" : "eye.slash.fill") {
//                            isSecure.toggle()
//                        }
//                        .padding(.trailing)
//                        .tint(.gray)
//                        .contentTransition(.symbolEffect(.replace))
//                    }
//                }


            } else {
                TextField(type.placeholder, text: $text)
                    .font(.system(size: 14))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
        }
        //.padding()
        //.frame(maxHeight: 90)
    }
}


#Preview {
    InputView(text: .constant(""), type: .repeatPassword)
}

enum UserFormType {
    case email, fullname, password, repeatPassword, phone
    
    var title: String {
        switch self {
        case .email:
            return "Email Address"
        case .fullname:
            return "Full Name"
        case .password:
            return "Password"
        case .repeatPassword:
            return "Repeat Password"
        case .phone:
            return "Phone Number"
        }
    }
    
    var isSecureField: Bool {
        switch self {
        case .password:
            return true
        case .repeatPassword:
            return true
        default:
            return false
        }
    }
    
    var placeholder: String  {
        switch self {
        case .email:
            return "name@example.com"
        case .fullname:
            return "Enter your name"
        case .password:
            return "Password"
        case .repeatPassword:
            return "Repeat Password"
        case .phone:
            return "Phone Number"
        }
        
    }
}

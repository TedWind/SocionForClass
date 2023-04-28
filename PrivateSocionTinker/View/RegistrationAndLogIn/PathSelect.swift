//
//  PathSelect.swift
//  PrivateSocionTinker
//
//  Created by Ted Wind on 4/1/23.
//

import SwiftUI

struct PathSelect: View {
    @Binding var registered : Bool
    @Binding var selected : Bool
    @Binding var agencyRegistration : Bool

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color("GradientStart"), Color("GradientEnd")]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                Spacer()
                
                Image("SocionCircle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)
                    .padding(.bottom, 20)
                    .shadow(color: .black, radius: 10, x: 0.0, y: 0.0)
                
                Text("Welcome to Socion")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                VStack(spacing: 20) {
                    Button(action: {
                        withAnimation {
                            registered = true
                            selected = true
                        }
                    }) {
                        Text("Sign In")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color("ButtonColor"))
                            .cornerRadius(15.0)
                            .overlay(RoundedRectangle(cornerRadius: 15.0).stroke(Color.white, lineWidth: 2))
                            .padding(.horizontal)
                    }
                    
                    Button(action: {
                        withAnimation {
                            registered = false
                            selected = true
                        }
                    }) {
                        Text("Register Account")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color("ButtonColor"))
                            .cornerRadius(15.0)
                            .overlay(RoundedRectangle(cornerRadius: 15.0).stroke(Color.white, lineWidth: 2))
                            .padding(.horizontal)
                    }
                    
                    Button(action: {
                        withAnimation {
                            registered = true
                            selected = true
                            agencyRegistration = true
                        }
                    }) {
                        Text("Create your Agency")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color("ButtonColor"))
                            .cornerRadius(15.0)
                            .overlay(RoundedRectangle(cornerRadius: 15.0).stroke(Color.white, lineWidth: 2))
                            .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
        }
    }
}


//struct PathSelect_Previews: PreviewProvider {
//    static var previews: some View {
//        PathSelect()
//    }
//}

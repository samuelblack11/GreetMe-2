//
//  EnlargeECard.swift
//  GreetMe-2
//
//  Created by Sam Black on 5/7/22.
//

import Foundation
import SwiftUI
import ConfettiSwiftUI


struct EnlargeECardView: View {
    @Binding var chosenCard: Card!
    @State private var counter = 1
    @State private var emojiDict: [String: String] = ["Birthday": "🎈", "Christmas": "🎄", "Hanukkah": "🕎"]
    
    var eCardView: some View {
        VStack(spacing:1) {
            Image(uiImage: UIImage(data: chosenCard.coverImage!)!)
                .resizable()
                .frame(maxWidth: (UIScreen.screenWidth/1.5), maxHeight: (UIScreen.screenHeight/3.7))
            Text(chosenCard.message!)
                .font(Font.custom(chosenCard.font!, size: 500))
                .minimumScaleFactor(0.01)
                .frame(maxWidth: (UIScreen.screenWidth/1.5), maxHeight: (UIScreen.screenHeight/5.5))
            
            VStack(spacing:0) {
                Image(uiImage: UIImage(data: chosenCard.collage!)!)
                    .resizable()
                    .frame(maxWidth: (UIScreen.screenWidth/1.5), maxHeight: (UIScreen.screenHeight/3.7))
                
                HStack(spacing: 0) {
                    
                    VStack(spacing: 0) {
                        Text(chosenCard.an1!)
                            .font(.system(size: 8))
                        Link(chosenCard.an2!, destination: URL(string: chosenCard.an2URL!)!)
                            .font(.system(size: 8))
                        HStack(spacing: 0) {
                            Text(chosenCard.an3!).font(.system(size: 8))
                            Link(chosenCard.an4!, destination: URL(string: "https://unsplash.com")!).font(.system(size: 8))
                            }
                        }.padding(.bottom,10)
                    Spacer()
                    Image(systemName: "greetingcard.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 24))
                        .padding(.bottom,10)
                    Spacer()
                    VStack(spacing:0) {
                    Text("Greeting Card by").font(.system(size: 8))
                    Text("GreetMe Inc.").font(.system(size: 8))
                    }
                }.frame(maxWidth: (UIScreen.screenWidth/1.5), maxHeight: (UIScreen.screenHeight/12))
            }
        }.frame(height: (UIScreen.screenHeight/1.1))
    }
       
    func addToCounter() {
        counter += 1
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    var body: some View {
        eCardView.confettiCannon(counter: $counter, num: 1, confettis: [ .text("🎈")], colors: [.red], confettiSize: 20.0, rainHeight: 600, fadesOut: true, opacity: 1, openingAngle: Angle.degrees(60), closingAngle: Angle.degrees(120), radius: 300, repetitions: 50, repetitionInterval: 0.05).onAppear(perform: addToCounter)
        }
    }

//
//  PhotoOptionsView.swift
//  Saloo
//
//  Created by Sam Black on 6/27/23.
//

import Foundation
import SwiftUI
import UIKit
import CoreData


struct PhotoOptionsView: View {
    @EnvironmentObject var chosenOccassion: Occassion
    @EnvironmentObject var chosenObject: ChosenCoverImageObject
    @EnvironmentObject var collageImage: CollageImage
    @State private var showImagePicker = false
    @State private var transitionVariable = false
    @ObservedObject var gettingRecord = GettingRecord.shared
    @ObservedObject var alertVars = AlertVars.shared
    @State private var hasShownLaunchView: Bool = true
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var cardProgress: CardProgress

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    Text("Saloo has curated professional photos for each holiday and special occassion. One of these will serve as your card's primary photo.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .padding(.top, 15)
                    Text("This photo will display separately from your collage")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .textCase(.none)
                        .multilineTextAlignment(.center)
                    Spacer()
                    Text("You'll also make a collage of personal photos.\nWhich of the below options would you like to use?")
                        .multilineTextAlignment(.center)
                    MiniCollageMenu()
                        .padding(.bottom, 5)
                    Button(action: {
                        cardProgress.currentStep = 1
                        appState.currentScreen = .buildCard([.occasionsMenu])
                    }) {
                        Text("Confirm Selection")
                            .frame(height: 24)
                            .padding(.top, 15)
                    }
                }
                LoadingOverlay(hasShownLaunchView: $hasShownLaunchView)
            }
            .onAppear {chosenObject.frontCoverIsPersonalPhoto = 0}
            .environmentObject(collageImage)
            .modifier(AlertViewMod(showAlert: alertVars.activateAlertBinding, activeAlert: alertVars.alertType))
            .navigationBarItems(leading:Button {cardProgress.currentStep = 1; cardProgress.maxStep = 1; appState.currentScreen = .startMenu} label: {Image(systemName: "chevron.left").foregroundColor(.blue); Text("Back")})
        }

    }
}








struct RadioButtonGroup: View {
    let items: [String]
    @Binding var selectedId: Int
    var body: some View {
        VStack {
            ForEach(0..<items.count) { index in
                HStack {
                    Text(items[index])
                    RadioButton(id: index, selectedId: $selectedId)
                }
                .contentShape(Rectangle())
                .onTapGesture {selectedId = index}
            }
        }
    }
}

struct RadioButton: View {
    let id: Int
    @Binding var selectedId: Int

    var body: some View {
        Circle()
            .fill(id == selectedId ? Color.blue : Color.clear)
            .frame(width: 20, height: 20)
            .overlay(Circle().stroke(Color.gray, lineWidth: 2))
    }
}

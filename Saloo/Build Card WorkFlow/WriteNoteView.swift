//
//  WriteNoteView.swift
//  GreetMe-2
//
//  Created by Sam Black on 5/1/22.
//
import Foundation
import SwiftUI

// https://www.hackingwithswift.com/quick-start/swiftui/how-to-read-text-from-a-textfield
// https://www.hackingwithswift.com/quick-start/swiftui/how-to-create-multi-line-editable-text-with-texteditor
// https://www.hackingwithswift.com/quick-start/swiftui/what-is-the-focusstate-property-wrapper

struct WriteNoteView: View {
    @State private var showMusic = false
    @State private var showFinalize = false
    @State private var showCollageBuilder = false
    
    //@State private var message: String = "Write Your Note Here"
    @ObservedObject var message = TextLimiter(limit: 225, value: "Write Your Note Here")
    @ObservedObject var recipient = TextLimiter(limit: 20, value: "To:")
    @ObservedObject var sender = TextLimiter(limit: 20, value: "From:")
    @ObservedObject var cardName = TextLimiter(limit: 20, value: "Name Your Card")
    
    
    
    //@State private var recipient: String = ""
    //@State private var sender: String = ""
    //@State private var cardName: String = ""
    @State private var tappedTextEditor = false
    @State private var namesNotEntered = false
    @State private var addMusicPrompt = false
    @State private var handWrite2 = false
    @StateObject var addMusic = AddMusic()
    @Binding var frontCoverIsPersonalPhoto: Int
    @StateObject var chosenSong = ChosenSong()
    @ObservedObject var chosenObject: ChosenCoverImageObject
    @ObservedObject var collageImage: CollageImage
    @StateObject var noteField = NoteField()
    @State private var selectedFont = "Papyrus"
    @State var text1: String = ""
    @State var text2: String = ""
    @State var text2URL: URL = URL(string: "https://google.com")!
    @State var text3: String = ""
    @State var text4: String = ""
    @FocusState private var isNoteFieldFocused: Bool
    @Binding var eCardText: String
    @Binding var printCardText: String
    @ObservedObject var chosenOccassion: Occassion
    @ObservedObject var chosenStyle: ChosenCollageStyle
    
    var fonts = ["Zapfino","Papyrus","American-Typewriter-Bold"]
    var fontMenu: some View {
        HStack {
            Text("Choose Font Here:  ")
                .padding(.leading, 5)
                .font(Font.custom(selectedFont, size: 12))
            Picker("", selection: $selectedFont) {
                ForEach(fonts, id:\.self) { fontType in
                    Text(fontType).font(Font.custom(fontType, size: 12))
                }
            }
            Spacer()
        }
    }

    
    var body: some View {
        NavigationView {
            ScrollView {
        TextEditor(text: $message.value)
            .border(Color.red, width: $message.hasReachedLimit.wrappedValue ? 1 : 0 )
            .frame(minHeight: 150)
            .font(Font.custom(selectedFont, size: 14))
            .onTapGesture {
                if message.value == "Write Your Note Here" {message.value = ""}
                //isNoteFieldFocused.toggle()
                tappedTextEditor = true
            }
        HStack {
        Text("\(225 - message.value.count) Characters Remaining").font(Font.custom(selectedFont, size: 10))
        Image(uiImage: collageImage.collageImage)
                .resizable()
                .frame(width: (UIScreen.screenWidth/5)-10, height: (UIScreen.screenWidth/5),alignment: .center)
        }
        //Spacer()
        fontMenu.frame(height: 65)
        TextField("To:", text: $recipient.value)
            .border(Color.red, width: $recipient.hasReachedLimit.wrappedValue ? 1 : 0 )
            .onTapGesture {if recipient.value == "To:" {recipient.value = ""}}
        TextField("From:", text: $sender.value)
            .border(Color.red, width: $sender.hasReachedLimit.wrappedValue ? 1 : 0 )
            .onTapGesture {if sender.value == "From:" {sender.value = ""}}
        TextField("Name Your Card", text: $cardName.value)
            .border(Color.red, width: $cardName.hasReachedLimit.wrappedValue ? 1 : 0 )
            .onTapGesture {if cardName.value == "Name Your Card" {cardName.value = ""}}
        Button("Confirm Note") {
            cardName.value = cardName.value.components(separatedBy: CharacterSet.punctuationCharacters).joined()
            addMusicPrompt = true
            }
        .alert("Please Enter Values for All Fields!", isPresented: $namesNotEntered) {Button("Ok", role: .cancel) {}}
        .alert("Add Song to Card?", isPresented: $addMusicPrompt) {            
            Button("Hell Yea"){addMusic.addMusic = true; checkRequiredFields(); annotateIfNeeded()}
            Button("No Thanks") {checkRequiredFields(); annotateIfNeeded()}
            }
        .alert("Your typed message will only appear in your eCard", isPresented: $handWrite2) {Button("Ok", role: .cancel) {}}
        .padding(.bottom, 30)
        .fullScreenCover(isPresented: $showMusic) {MusicView(chosenSong: chosenSong, chosenOccassion: chosenOccassion, chosenObject: chosenObject, collageImage: collageImage, noteField: noteField, addMusic: addMusic, frontCoverIsPersonalPhoto: frontCoverIsPersonalPhoto, eCardText: eCardText, text1: text1, text2: text2, text2URL: text2URL, text3: text3, text4: text4)}
        .fullScreenCover(isPresented: $showFinalize) {FinalizeCardView(chosenObject: chosenObject, collageImage: collageImage, noteField: noteField, frontCoverIsPersonalPhoto: frontCoverIsPersonalPhoto, text1: $text1, text2: $text2, text2URL: $text2URL, text3: $text3, text4: $text4, addMusic: addMusic, eCardText: $eCardText, chosenOccassion: chosenOccassion, chosenSong: chosenSong)}
        .fullScreenCover(isPresented: $showCollageBuilder) {CollageBuilder(showImagePicker: false, chosenObject: chosenObject, chosenOccassion: chosenOccassion, frontCoverIsPersonalPhoto: $frontCoverIsPersonalPhoto, chosenCollageStyle: chosenStyle)}
        }
            .navigationBarItems(leading:Button {showCollageBuilder = true} label: {Image(systemName: "chevron.left").foregroundColor(.blue); Text("Back")})
        }
        .onAppear{print("called writeNoteView....//"); print(collageImage.collageImage)}
    }
}


extension WriteNoteView {
    
    func annotateIfNeeded() {
        print("annotateIfNeeded was Called")
        print(frontCoverIsPersonalPhoto)
        if frontCoverIsPersonalPhoto == 0 {
            text1 = "Front Cover By "
            text2 = String(chosenObject.coverImagePhotographer)
            text2URL = URL(string: "https://unsplash.com/@\(chosenObject.coverImageUserName)")!
            text3 = "On "
            text4 = "Unsplash"
        }
        else {text2URL = URL(string: "https://google.com")!}
    }
    
    func checkRequiredFields() {
        if recipient.value != "" && cardName.value != "" {
            namesNotEntered = false
            if addMusic.addMusic {showMusic = true}
            else {showFinalize = true}
            noteField.noteText = message.value
            noteField.recipient = recipient.value
            noteField.cardName = cardName.value
            noteField.font = selectedFont
            noteField.sender = sender.value
        }
        else {namesNotEntered = true}
    }
    
    
    
}

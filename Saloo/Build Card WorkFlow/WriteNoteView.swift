//
//  WriteNoteView.swift
//  GreetMe-2
//
//  Created by Sam Black on 5/1/22.
//
import Foundation
import SwiftUI



struct WriteNoteView: View {
    @EnvironmentObject var chosenObject: ChosenCoverImageObject
    @EnvironmentObject var collageImage: CollageImage
    @EnvironmentObject var chosenOccassion: Occassion
    @EnvironmentObject var appDelegate: AppDelegate
    @StateObject var addMusic = AddMusic()
    @StateObject var chosenSong = ChosenSong()
    @StateObject var giftCard = GiftCard()

    @StateObject var noteField = NoteField()
    @StateObject var annotation = Annotation()
    
    @State private var showMusic = false
    @State private var showFinalize = false
    @State private var showCollageBuilder = false
    
    @ObservedObject var message = MaximumText(limit: 225, value: "Write Your Note Here")
    @ObservedObject var recipient = MaximumText(limit: 20, value: "To:")
    @ObservedObject var sender = MaximumText(limit: 20, value: "From:")
    @ObservedObject var cardName = MaximumText(limit: 20, value: "Name Your Card")
    @State private var tappedTextEditor = false
    @State private var namesNotEntered = false
    @State private var addMusicPrompt = false
    @State private var skipMusicPrompt = false
    @State private var handWrite2 = false
    @State private var selectedFont = "Papyrus"
    @FocusState private var isNoteFieldFocused: Bool
    @ObservedObject var gettingRecord = GettingRecord.shared

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

    func determineCardType() -> String {
        var cardType2 = String()
        if chosenSong.id != "" && giftCard.id != ""  {cardType2 = "musicAndGift"}
        else if chosenSong.id != "" && giftCard.id == ""  {cardType2 = "musicNoGift"}
        else if chosenSong.id == "" && giftCard.id != ""  {cardType2 = "giftNoMusic"}
        else{cardType2 = "noMusicNoGift"}
        
        return cardType2
        
    }
    
    var body: some View {
        NavigationView {
            ZStack {
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
                        //Image(uiImage: UIImage(data: collageImage.image1)!)
                        //.resizable()
                        //.frame(width: (UIScreen.screenWidth/5)-10, height: (UIScreen.screenWidth/5),alignment: .center)
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
                        if appDelegate.musicSub.type == .Apple {addMusicPrompt = true}
                        if appDelegate.musicSub.type == .Spotify {addMusicPrompt = true}
                        if appDelegate.musicSub.type == .Neither {showFinalize = true}
                        let fullTextDetails = message.value + " " + recipient.value + " " + sender.value + " " + cardName.value
                        WriteNoteView.checkTextForOffensiveContent(text: fullTextDetails) { (textIsOffensive, error) in
                            print("....")
                            print(textIsOffensive)
                        }
                    }
                    .alert("Please Enter Values for All Fields!", isPresented: $namesNotEntered) {Button("Ok", role: .cancel) {}}
                    .alert("A Subscription to Spotify or Apple Music is Required to Add a Song. We'll skip that Step", isPresented: $skipMusicPrompt) {
                        Button("Ok"){showFinalize = true}
                    }
                    .alert("Add Song to Card?", isPresented: $addMusicPrompt) {
                        Button("Hell Yea"){addMusic.addMusic = true; appDelegate.musicSub.timeToAddMusic = true; checkRequiredFields(); annotateIfNeeded()}
                        Button("No Thanks") {checkRequiredFields(); annotateIfNeeded(); addMusic.addMusic = false; showFinalize = true}
                    }
                    .alert("Your typed message will only appear in your eCard", isPresented: $handWrite2) {Button("Ok", role: .cancel) {}}
                    .padding(.bottom, 30)
                    .fullScreenCover(isPresented: $showMusic) {MusicSearchView().environmentObject(appDelegate)}
                    .fullScreenCover(isPresented: $showFinalize) {FinalizeCardView(cardType: determineCardType())}
                    .fullScreenCover(isPresented: $showCollageBuilder) {CollageBuilder(showImagePicker: false)}
                }
                LoadingOverlay()
            }
            .navigationBarItems(leading:Button {showCollageBuilder = true} label: {Image(systemName: "chevron.left").foregroundColor(.blue); Text("Back")}.disabled(gettingRecord.isShowingActivityIndicator))
        }
        .modifier(GettingRecordAlert())
        //.environmentObject(appDelegate)
        .environmentObject(noteField)
        .environmentObject(annotation)
        .environmentObject(addMusic)
        .environmentObject(chosenSong)
        .environmentObject(giftCard)


    }
}


extension WriteNoteView {
    
    
    func checkForBannedContent(inputString: String) {
        print("Checking for banned content...")
    }
    
    func annotateIfNeeded() {
        print("annotateIfNeeded was Called")
        print(chosenObject.frontCoverIsPersonalPhoto)
        if chosenObject.frontCoverIsPersonalPhoto == 0 {
            annotation.text1 = "Front Cover By "
            annotation.text2 = String(chosenObject.coverImagePhotographer)
            annotation.text2URL = URL(string: "https://unsplash.com/@\(chosenObject.coverImageUserName)")!
            annotation.text3 = "On "
            annotation.text4 = "Unsplash"
        }
        else {annotation.text2URL = URL(string: "https://google.com")!}
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
    
    
    static let subscriptionKey = "644c31910b4c473e9117a5127ceb3895"
    static let endpoint = "https://saloocontentmoderator2.cognitiveservices.azure.com/"
    static let textModerationEndpoint = "https://eastus.api.cognitive.microsoft.com/contentmoderator/moderate/v1.0/ProcessText/Screen"
    static let textBase = endpoint + "contentmoderator/moderate/v1.0/ProcessText/Screen"
    
    static func checkTextForOffensiveContent(text: String, completion: @escaping (Bool?, Error?) -> Void) {
        // Endpoint for Microsoft's Content Moderator API (text moderation)
        guard let url = URL(string: textBase) else { return }
        // Prepare the request body
        let requestBody = ["text": text]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create request body"])
            completion(nil, error)
            return
        }
        // Prepare the URL request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.addValue(subscriptionKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        // Make the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil, error)
                return
            }
            
            do {
                if let responseData = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let status = responseData["Status"] as? [String: Any],
                   let description = status["Description"] as? String {
                    // Access the extracted description
                    if description == "OK" {completion(false, nil)}
                    else {completion(true, nil)}
                } else {
                    let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON or extract description"])
                    completion(nil, error)
                }
            } catch {
                completion(nil, error)
            }
        }
        task.resume()
    }
    
    
    
}



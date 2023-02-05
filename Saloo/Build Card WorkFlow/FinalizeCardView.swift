//
//  FinalizeCardView.swift
//  GreetMe-2
//
//  Created by Sam Black on 5/1/22.
//

import Foundation
import SwiftUI
import CoreData
import CloudKit


struct FinalizeCardView: View {
    
    @EnvironmentObject var chosenOccassion: Occassion
    @EnvironmentObject var chosenObject: ChosenCoverImageObject
    @EnvironmentObject var collageImage: CollageImage
    @EnvironmentObject var noteField: NoteField
    @EnvironmentObject var addMusic: AddMusic
    @EnvironmentObject var annotation: Annotation
    
    @State private var showOccassions = false
    @State private var showUCV = false
    @State private var showCollageMenu = false
    @State private var showCollageBuilder = false
    @State private var showWriteNote = false
    
    @State var coreCard: CoreCard!
    @State var cardRecord: CKRecord!
    //@Binding var cardForExport: Data!
    @State private var showActivityController = false
    @State var activityItemsArray: [Any] = []
    @State var saveAndShareIsActive = false
    @State private var showCompleteAlert = false
    var field1: String!
    var field2: String!
    @State var string1: String!
    @State var string2: String!
    @State private var showShareSheet = false
    @State var share: CKShare?
    @State private var isAddingCard = false
    @State private var isSharing = false
    @State private var isProcessingShare = false
    @State private var activeShare: CKShare?
    @State private var activeContainer: CKContainer?

    @EnvironmentObject var chosenSong: ChosenSong
    
    var saveButton: some View {
        Button("Save eCard") {
            Task {saveCard(noteField: noteField, chosenOccassion: chosenOccassion, an1: annotation.text1, an2: annotation.text2, an2URL: annotation.text2URL.absoluteString, an3: annotation.text3, an4: annotation.text4, chosenObject: chosenObject, collageImage: collageImage, songID: chosenSong.id, songName: chosenSong.name, songArtistName: chosenSong.artistName, songArtImageData: chosenSong.artwork, songPreviewURL: chosenSong.songPreviewURL, songDuration: String(chosenSong.durationInSeconds), inclMusic: addMusic.addMusic)}
            showCompleteAlert = true
            }
            .fullScreenCover(isPresented: $showOccassions) {OccassionsMenu()}
            .fullScreenCover(isPresented: $showCollageMenu) {CollageStyleMenu()}
            .fullScreenCover(isPresented: $showUCV) {UnsplashCollectionView()}
            .disabled(saveAndShareIsActive)
            .alert("Save Complete", isPresented: $showCompleteAlert) {
                Button("Ok", role: .cancel) {showCollageBuilder = false; showWriteNote = false; showCollageMenu = false; showUCV = false;showOccassions = true; let rootViewController = UIApplication.shared.connectedScenes
                            .filter {$0.activationState == .foregroundActive }
                            .map {$0 as? UIWindowScene }
                            .compactMap { $0 }
                            .first?.windows
                            .filter({ $0.isKeyWindow }).first?.rootViewController
                       rootViewController?.dismiss(animated: true)
                }
            }
            //.fullScreenCover(isPresented: $isSharing, content: {shareView(coreCard: coreCard)})
    }
    
    
    
    
    var body: some View {
        NavigationView {
        VStack(spacing: 0) {
            eCardView(eCardText: noteField.eCardText, font: noteField.font, coverImage: chosenObject.coverImage, collageImage: collageImage.collageImage.pngData()!, text1: annotation.text1, text2: annotation.text2, text2URL: annotation.text2URL, text3: annotation.text3, text4: annotation.text4, songID: chosenSong.id, songName: chosenSong.name, songArtistName: chosenSong.artistName, songArtImageData: chosenSong.artwork, songDuration: chosenSong.durationInSeconds, songPreviewURL: chosenSong.songPreviewURL, inclMusic: addMusic.addMusic)
            saveButton
                //.frame(height: UIScreen.screenHeight/1)
        }
        .navigationBarItems(
            leading:Button {}
            label: {Image(systemName: "chevron.left").foregroundColor(.blue)
            Text("Back")},
            trailing: Button {showOccassions = true} label: {Image(systemName: "menucard.fill").foregroundColor(.blue)
            Text("Menu")})
        .fullScreenCover(isPresented: $showOccassions) {OccassionsMenu()}
        .fullScreenCover(isPresented: $showShareSheet, content: {if let share = share {}})
        .fullScreenCover(isPresented: $showActivityController) {ActivityView(activityItems: $activityItemsArray, applicationActivities: nil)}
        }
    }
}

extension FinalizeCardView {
    
    private func saveCard(noteField: NoteField, chosenOccassion: Occassion, an1: String, an2: String, an2URL: String, an3: String, an4: String, chosenObject: ChosenCoverImageObject, collageImage: CollageImage, songID: String?, songName: String?, songArtistName: String?, songArtImageData: Data?, songPreviewURL: String?, songDuration: String?, inclMusic: Bool ) {
        let controller = PersistenceController.shared
        let taskContext = controller.persistentContainer.newTaskContext()
        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        controller.addCoreCard(noteField: noteField, chosenOccassion: chosenOccassion, an1: an1, an2: an2, an2URL: an2URL, an3: an3, an4: an4, chosenObject: chosenObject, collageImage: collageImage,context: taskContext, songID: songID, songName: songName, songArtistName: songArtistName, songArtImageData: songArtImageData, songPreviewURL: songPreviewURL, songDuration: songDuration, inclMusic: inclMusic)
    }
}

extension UIScreen{
   static let screenWidth = UIScreen.main.bounds.size.width
   static let screenHeight = UIScreen.main.bounds.size.height
   static let screenSize = UIScreen.main.bounds.size
}
    
    struct ActivityView: UIViewControllerRepresentable {
       @Binding var activityItems: [Any]
       let applicationActivities: [UIActivity]?
       func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityView>) -> UIActivityViewController {
          UIActivityViewController(activityItems: activityItems,
                                applicationActivities: applicationActivities)
       }
       func updateUIViewController(_ uiViewController: UIActivityViewController,
                                   context: UIViewControllerRepresentableContext<ActivityView>) {}
       }
    
// https://medium.com/swiftui-made-easy/activity-view-controller-in-swiftui-593fddadee79
// https://www.hackingwithswift.com/example-code/uikit/how-to-render-pdfs-using-uigraphicspdfrenderer
// https://stackoverflow.com/questions/1134289/cocoa-core-data-efficient-way-to-count-entities
// https://www.advancedswift.com/resize-uiimage-no-stretching-swift/
// https://www.hackingwithswift.com/articles/103/seven-useful-methods-from-cgrect
// https://stackoverflow.com/questions/57727107/how-to-get-the-iphones-screen-width-in-swiftui
// https://www.hackingwithswift.com/read/33/4/writing-to-icloud-with-cloudkit-ckrecord-and-ckasset
// https://swiftwithmajid.com/2022/03/29/zone-sharing-in-cloudkit/
// https://swiftwithmajid.com/2022/03/29/zone-sharing-in-cloudkit/
// https://www.techotopia.com/index.php/An_Introduction_to_CloudKit_Data_Storage_on_iOS_8#Record_Zones
// https://github.com/apple/sample-cloudkit-sharing
// https://stackoverflow.com/questions/66313845/swiftui-dismiss-all-active-sheet-views

//
//  OccassionsMenu.swift
//  LearningSwiftUI
//
//  Created by Sam Black on 4/28/22.
//
// https://www.hackingwithswift.com/quick-start/swiftui/how-to-make-a-view-dismiss-itself
// https://www.hackingwithswift.com/books/ios-swiftui/building-a-list-we-can-delete-from
// https://stackoverflow.com/questions/66283978/swiftui-open-a-specific-view-when-user-opens-a-push-notification/66284621#66284621
import Foundation
import SwiftUI
import UIKit
import FSCalendar
import CoreData

struct OccassionsMenu: View {
    @EnvironmentObject var musicSub: MusicSubscription
    @State private var showStartMenu = false
    //@State private var showSentCards = false
    //@State private var showReceivedCards = false
    @State private var showGridOfCards = false
    @State private var showCameraCapture = false
    @State private var showImagePicker = false
    @State private var showCollageMenu = false
    @State private var showUCV = false
    

    // Collection Variables. Use @State private for variables owned by this view and not accessible by external views
    @State private var collections: [CollectionPair] = []
    @State private var yearRoundCollection: [CollectionPair] = []
    @State private var winterCollection: [CollectionPair] = []
    @State private var springCollection: [CollectionPair] = []
    @State private var summerCollection: [CollectionPair] = []
    @State private var fallCollection: [CollectionPair] = []
    @State private var otherCollection: [CollectionPair] = []
    // Use @ObservedObject for complex properties shared across multiple views
    @ObservedObject var calViewModel: CalViewModel
    @ObservedObject var showDetailView: ShowDetailView
    // Object to pass to Collage Menu if photo not selcted from UCV
    @StateObject var chosenObject = ChosenCoverImageObject()
    // Cover Image Variables used dependent on the image's source
    @State private var coverImage: UIImage?
    @State private var coverImageFromLibrary: UIImage?
    @State private var coverImageFromCamera: UIImage?
    // 0 or 1 Int used as bool to define whether front cover comes from Unsplash or not
    @State var frontCoverIsPersonalPhoto = 0
    // Variables for text field where user does custom photo search. Initialized as blank String
    @State private var customSearch: String = ""
    // Defines page number to be used when displaying photo results on UCV
    @State private var pageCount = 1
    //
    @State var loadedImagefromLibraryOrCamera: Bool?
    @StateObject var chosenOccassion = Occassion()
    
    
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    var body: some View {
        // NavigationView combines display styling of UINavigationBar and VC stack behavior of UINavigationController.
        // Hold cmd + ctrl, then click space bar to show emoji menu
        NavigationView {
        List {
            Section(header: Text("Personal & Search")) {
                Text("Select from Photo Library ").onTapGesture {self.showCameraCapture = false; self.showImagePicker = true}
                    .fullScreenCover(isPresented: $showImagePicker){ImagePicker(image: $coverImageFromLibrary)}
                    .onChange(of: coverImageFromLibrary) { _ in loadImage(pic: coverImageFromLibrary!)
                        handlePersonalPhotoSelection()
                        showCollageMenu = true; frontCoverIsPersonalPhoto = 1
                        chosenOccassion.occassion = "None"; chosenOccassion.collectionID = "None"
                        }
                    .fullScreenCover(isPresented: $showCollageMenu){
                        CollageStyleMenu(chosenObject: chosenObject, chosenOccassion: chosenOccassion, frontCoverIsPersonalPhoto: $frontCoverIsPersonalPhoto)
                    }
                Text("Take Photo with Camera 📸 ").onTapGesture {
                    self.showImagePicker = false
                    self.showCameraCapture = true
                }
                .fullScreenCover(isPresented: $showCameraCapture)
                {CameraCapture(image: self.$coverImageFromCamera, isPresented: self.$showCameraCapture, sourceType: .camera)}
                .onChange(of: coverImageFromCamera) { _ in loadImage(pic: coverImageFromCamera!)
                    handlePersonalPhotoSelection()
                    showCollageMenu = true; frontCoverIsPersonalPhoto = 1
                    chosenOccassion.occassion = "None"; chosenOccassion.collectionID = "None"
                    }
                .fullScreenCover(isPresented: $showCollageMenu){
                    CollageStyleMenu(chosenObject: chosenObject, chosenOccassion: chosenOccassion, frontCoverIsPersonalPhoto: $frontCoverIsPersonalPhoto)}
                HStack {
                    TextField("Custom Search", text: $customSearch)
                        .padding(.leading, 5)
                        .frame(height:35)
                    Button {showUCV = true; frontCoverIsPersonalPhoto = 0
                        chosenOccassion.occassion = "None"
                        chosenOccassion.collectionID = customSearch
                    }
                    label: {Image(systemName: "magnifyingglass.circle.fill")}
                        .fullScreenCover(isPresented: $showUCV) {
                            UnsplashCollectionView(chosenOccassion: chosenOccassion, pageCount: pageCount, chosenObject: chosenObject, frontCoverIsPersonalPhoto: $frontCoverIsPersonalPhoto)
                    }
                }
            }
            Section(header: Text("Year-Round Occassions")) {ForEach(yearRoundCollection) {menuSection(for: $0, shareable: false)}}
            Section(header: Text("Winter Holidays")) {ForEach(winterCollection) {menuSection(for: $0, shareable: false)}}
            Section(header: Text("Spring Holidays")) {ForEach(springCollection) {menuSection(for: $0, shareable: false)}}
            Section(header: Text("Summer Holidays")) {ForEach(summerCollection) {menuSection(for: $0, shareable: false)}}
            Section(header: Text("Fall Holidays")) {ForEach(fallCollection) {menuSection(for: $0, shareable: false)}}
            Section(header: Text("Other Collections")) {ForEach(otherCollection) {menuSection(for: $0, shareable: false)}}
        }
        .navigationBarItems(leading:Button {showStartMenu.toggle()} label: {Image(systemName: "chevron.left").foregroundColor(.blue); Text("Back")})
        .font(.headline)
        .listStyle(GroupedListStyle())
        .onAppear {createOccassionsFromUserCollections()}
        }
        .fullScreenCover(isPresented: $showStartMenu) {StartMenu(calViewModel: CalViewModel(), showDetailView: ShowDetailView())}
    }
}

extension OccassionsMenu {
                
    func loadCoreCards() -> [CoreCard] {
        let request = CoreCard.createFetchRequest()
        let sort = NSSortDescriptor(key: "date", ascending: false)
        request.sortDescriptors = [sort]
        var cardsFromCore: [CoreCard] = []
        do {
            cardsFromCore = try PersistenceController.shared.persistentContainer.viewContext.fetch(request)
            print("Got \(cardsFromCore.count) Cards From Core")
        }
        catch {print("Fetch failed")}
        return cardsFromCore
    }
    
    private func menuSection(for collection: CollectionPair, shareable: Bool = true) -> some View {
            Text(collection.title).onTapGesture {
                frontCoverIsPersonalPhoto = 0
                self.chosenOccassion.occassion = collection.title
                self.chosenOccassion.collectionID = collection.id
                showUCV.toggle()
            }.fullScreenCover(isPresented: $showUCV) {
                UnsplashCollectionView(chosenOccassion: chosenOccassion, pageCount: pageCount, chosenObject: chosenObject, frontCoverIsPersonalPhoto: $frontCoverIsPersonalPhoto)
                }
    }
    
    func groupCollections(collections: [CollectionPair]) {
        let yearRoundOccassions = ["Birthday 🎈", "Postcard ✈️", "Anniversary 💒", "Graduation 🎓"]
        let winterOccassions = ["Christmas 🎄", "Hanukkah 🕎", "New Years Eve 🎆"]
        let springOccassions = ["Mother's Day 🌸"]
        let summerOccassions = ["4th of July 🎇", "Father's Day 🍻"]
        let fallOccassions = ["Thanksgiving 🍁","Rosh Hashanah 🔯"]
        let otherOccassions = ["Animals 🐼"]
        
        for collection in collections {
            if yearRoundOccassions.contains(collection.title) {yearRoundCollection.append(collection)}
            if winterOccassions.contains(collection.title) {winterCollection.append(collection)}
            if springOccassions.contains(collection.title) {springCollection.append(collection)}
            if summerOccassions.contains(collection.title) {summerCollection.append(collection)}
            if fallOccassions.contains(collection.title) {fallCollection.append(collection)}
            if otherOccassions.contains(collection.title) {otherCollection.append(collection)}
        }
    }
    
    func createOccassionsFromUserCollections() {
            PhotoAPI.getUserCollections(username: "samuelblack11", completionHandler: { (response, error) in
                if response != nil {
                    DispatchQueue.main.async {
                        for collection in response! {collections.append(CollectionPair(title: collection.title, id: collection.id))
                            }
                        groupCollections(collections: collections)
                    }
                }
                if response != nil {print("No Response!")}
                else {debugPrint(error?.localizedDescription)}
            })
    }
    
    func loadImage(pic: UIImage) {
        coverImage = pic
        if showImagePicker  {loadedImagefromLibraryOrCamera = true}
    }
    
    func handlePersonalPhotoSelection() {
        chosenObject.smallImageURLString = "https://google.com"
        chosenObject.coverImage = coverImage!.jpegData(compressionQuality: 1)!
        chosenObject.coverImagePhotographer = ""
        chosenObject.coverImageUserName = ""
        chosenObject.downloadLocation = ""
        chosenObject.index = 1
    }
    
}

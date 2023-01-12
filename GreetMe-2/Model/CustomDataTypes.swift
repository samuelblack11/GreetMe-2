//
//  CustomDataTypes.swift
//  GreetMe-2
//
//  Created by Sam Black on 12/24/22.
//

import Foundation
import UIKit
import SwiftUI
import CloudKit

struct ChosenCollection {@State var occassion: String!; @State var collectionID: String!}
class ChosenCoreCard: ObservableObject {@Published var chosenCard = CoreCard()}
class Occassion: ObservableObject {@Published var occassion = String(); @Published var collectionID = String()}
public class ShowDetailView: ObservableObject {@Published public var showDetailView: Bool = false}

class ChosenCoverImageObject: ObservableObject {
    @Published var id = UUID()
    @Published var coverImage = Data()
    @Published var smallImageURLString = String()
    @Published var coverImagePhotographer = String()
    @Published var coverImageUserName = String()
    @Published var downloadLocation = String()
    @Published var index = Int()
    //func hash(into hasher: inout Hasher) {
    //    hasher.combine(downloadLocation)
    //}
}

class NoteField: ObservableObject  {
    @Published var noteText = String()
    @Published var recipient =  String()
    @Published var sender =  String()
    @Published var cardName = String()
    @Published var font = String()
    @Published var willHandWrite = Bool()
    @Published var eCardText = String()
    @Published var printCardText = String()
}


struct CoverImageObject: Identifiable, Hashable {
    let id = UUID()
    let coverImage: Data?
    let smallImageURL: URL
    let coverImagePhotographer: String
    let coverImageUserName: String
    let downloadLocation: String
    let index: Int
    func hash(into hasher: inout Hasher) {
        hasher.combine(downloadLocation)
    }
}

class CollageImage: ObservableObject {@Published var collageImage = UIImage()}
class HandWrite: ObservableObject { @Published var willHandWrite: Bool = false}

// https://programmingwithswift.com/swiftui-textfield-character-limit/

class TextLimiter: ObservableObject {
    // variable for character limit
    private let limit: Int
    init(limit: Int, value: String) {self.limit = limit; self.value = value}
    // value that text field displays
    @Published var value: String {
        didSet {
            if value.count > self.limit {
                value = String(value.prefix(self.limit))
                self.hasReachedLimit = true
            } else {self.hasReachedLimit = false}
        }
    }
    @Published var hasReachedLimit = false
}

public class ChosenImages: ObservableObject {
    @Published var imagePlaceHolder: Image?
    @Published var chosenImageA: UIImage?
    @Published var chosenImageB: UIImage?
    @Published var chosenImageC: UIImage?
    @Published var chosenImageD: UIImage?
}

class InOut: ObservableObject {
    enum SendReceive {
        case inbox
        case outbox
    }
}

class ChosenCollageStyle: ObservableObject {@Published var chosenStyle: Int?}

class CollageBlocksAndViews {

    func blockForStyle() -> some View {return GeometryReader {geometry in HStack(spacing: 0) {Rectangle().fill(Color.gray).border(Color.black)}}}
    
    func onePhotoView(block: some View) -> some View {return block}
    func twoPhotoWide(block: some View) -> some View {return VStack(spacing:0){block; block}}
    func twoPhotoLong(block: some View) -> some View {return HStack(spacing:0){block; block}}
    func twoShortOneLong(block: some View) -> some View {return HStack(spacing:0){VStack(spacing:0){block; block}; block}}
    func twoNarrowOneWide(block: some View) -> some View {return VStack(spacing:0){HStack(spacing:0){block; block}; block}}
    func fourPhoto(block: some View) -> some View {return VStack(spacing:0){HStack(spacing:0){block; block}; HStack(spacing:0){block; block}}}
    
}

enum ActiveSheet: Identifiable, Equatable {
    #if os(iOS)
    case photoPicker // Unavailable in watchOS.
    #elseif os(watchOS)
    case photoContextMenu(CoreCard) // .contextMenu is deprecated in watchOS, so use action list instead.
    #endif
    case cloudSharingSheet(CKShare)
    case managingSharesView
    case sharePicker(CoreCard)
    case taggingView(CoreCard)
    case ratingView(CoreCard)
    case participantView(CKShare)
    /**
     Use the enumeration member name string as the identifier for Identifiable.
     In the case where an enumeration has an associated value, use the label, which is equal to the member name string.
     */
    var id: String {
        let mirror = Mirror(reflecting: self)
        if let label = mirror.children.first?.label {
            return label
        } else {
            return "\(self)"
        }
    }
    
    
    

}


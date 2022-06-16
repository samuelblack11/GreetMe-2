//
//  CollageTwoView.swift
//  LearningSwiftUI
//
//  Created by Sam Black on 4/29/22.
//

import Foundation
import SwiftUI

struct CollageTwoView: View {
    @Environment(\.presentationMode) var presentationMode

    @State private var showingImagePicker = false
    @State private var imageA: Image?
    @State private var imageB: Image?
    @State private var imageNumber: Int?
    @State private var chosenImageA: UIImage?
    @State private var chosenImageB: UIImage?
    @State private var segueToWriteNote = false
    @Binding var collageImage: CollageImage!
    @Binding var chosenObject: CoverImageObject!
    @Binding var noteField: NoteField!
    @Binding var frontCoverIsPersonalPhoto: Int

    
    var collageTwoView: some View {
        VStack(spacing:0 ) {
        ZStack {
            Rectangle().fill(.secondary)
            Text("Tap to select a picture").foregroundColor(.white).font(.headline)
            imageA?.resizable()
        }
            .onTapGesture {showingImagePicker = true; imageNumber = 1}
            .frame(width: 250, height: 150)
            .onChange(of: chosenImageA) { _ in loadImage(chosenImage: chosenImageA)}
            .sheet(isPresented: $showingImagePicker) { ImagePicker(image: $chosenImageA)}
        Divider().frame(width: 250)
        ZStack {
            Rectangle().fill(.secondary)
            Text("Tap to select a picture").foregroundColor(.white).font(.headline)
            imageB?.resizable()
        }
            .onTapGesture {showingImagePicker = true; imageNumber = 2}
            .frame(width: 250, height: 150)
            .navigationTitle("Select 2 Photos")
            .navigationBarItems(leading:
                                    Button {presentationMode.wrappedValue.dismiss()} label: {
                                    Image(systemName: "chevron.left").foregroundColor(.blue)
                                    Text("Back")
                                    })
            .onChange(of: chosenImageB) { _ in loadImage(chosenImage: chosenImageB)}
            .sheet(isPresented: $showingImagePicker) {ImagePicker(image: $chosenImageB)}
            }
        }

    var body: some View {
        NavigationView {
        VStack(spacing: 0) {
        collageTwoView
        Spacer()
        Button("Confirm Collage for Inside Cover") {
            segueToWriteNote  = true
            let theSnapShot = collageTwoView.snapshot()
            print("********")
            print(theSnapShot)
            collageImage = CollageImage.init(collageImage: theSnapShot)
        }.padding(.bottom, 30).sheet(isPresented: $segueToWriteNote ) {WriteNoteView(frontCoverIsPersonalPhoto: $frontCoverIsPersonalPhoto, chosenObject: $chosenObject, collageImage: $collageImage, noteField: $noteField)}
        }
        }
    }
    
    func loadImage(chosenImage: UIImage?) {
        guard let chosenImage = chosenImage else {return print("loadImage() failed....")}
        if imageNumber == 1 {imageA = Image(uiImage: chosenImage)}
        if imageNumber == 2 {imageB = Image(uiImage: chosenImage)}
        }
    }


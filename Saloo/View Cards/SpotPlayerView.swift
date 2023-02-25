//
//  SpotPlayerView.swift
//  Saloo
//
//  Created by Sam Black on 2/16/23.
//

import Foundation

// https://santoshkumarjm.medium.com/how-to-design-a-custom-avplayer-to-play-audio-using-url-in-ios-swift-439f0dbf2ff2

import Foundation
import Foundation
import SwiftUI
import CoreData
import CloudKit
import StoreKit
import MediaPlayer

struct SpotPlayerView: View {
    @State var songID: String?
    @State var songName: String?
    @State var songArtistName: String?
    @State var songArtImageData: Data?
    @State var songDuration: Double?
    @State var songPreviewURL: String?
    @State private var songProgress = 0.0
    @State private var isPlaying = true
    @State var confirmButton: Bool
    @Binding var showFCV: Bool
    @EnvironmentObject var appDelegate: AppDelegate
    @EnvironmentObject var sceneDelegate: SceneDelegate
    @EnvironmentObject var spotifyAuth: SpotifyAuth
    @State private var addSongCounter = 0
    @State private var showProgressView = true
    let defaults = UserDefaults.standard
    var config = SPTConfiguration(clientID: "d15f76f932ce4a7c94c2ecb0dfb69f4b", redirectURL: URL(string: "saloo://")!)
    var appRemote2: SPTAppRemote

    var body: some View {NavigationStack {SpotPlayerView()}.environmentObject(appDelegate)}
    
    @ViewBuilder var selectButton: some View {
        if confirmButton == true {Button {appRemote2.playerAPI?.pause();showFCV = true; spotifyAuth.songID = songID!} label: {Text("Select Song For Card").foregroundColor(.blue)}}
        else {Text("")}
    }

    func convertToMinutes(seconds: Int) -> String {
        let m = seconds / 60
        let s = String(format: "%02d", seconds % 60)
        let completeTime = String("\(m):\(s)")
        return completeTime
    }
    
    func SpotPlayerView() -> some View {
        let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        return VStack {
                   if showProgressView {ProgressView().progressViewStyle(.circular) .tint(.green)}
                    Image(uiImage: UIImage(data: songArtImageData!)!)
                    Text(songName!)
                        .font(.headline)
                    Text(songArtistName!)
                    HStack {
                        Button {
                            songProgress = 0.0
                            appRemote2.playerAPI?.skip(toPrevious: defaultCallback)
                            isPlaying = true
                        } label: {
                            ZStack {
                                Circle()
                                    .accentColor(.green)
                                    .shadow(radius: 8)
                                Image(systemName: "arrow.uturn.backward" )
                                    .foregroundColor(.white)
                                    .font(.system(.title))
                            }
                        }
                        .frame(maxWidth: UIScreen.screenHeight/12, maxHeight: UIScreen.screenHeight/12)
                        Button {
                            if isPlaying {appRemote2.playerAPI?.pause()}
                            else {appRemote2.playerAPI?.resume()}
                            isPlaying.toggle()
                        } label: {
                            ZStack {
                                Circle()
                                    .accentColor(.green)
                                    .shadow(radius: 8)
                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                    .foregroundColor(.white)
                                    .font(.system(.title))
                            }
                        }
                        .frame(maxWidth: UIScreen.screenHeight/12, maxHeight: UIScreen.screenHeight/12)
                    }
                    ProgressView(value: songProgress, total: songDuration!)
                        .onReceive(timer) {_ in
                            if songProgress < songDuration! && isPlaying {songProgress += 1}
                            if songProgress == songDuration{appRemote2.playerAPI?.pause()}
                        }
                    HStack{
                        Text(convertToMinutes(seconds:Int(songProgress)))
                        Spacer()
                        Text(convertToMinutes(seconds: Int(songDuration!)-Int(songProgress)))
                            .padding(.trailing, 10)
                    }
                selectButton
                }
            .onAppear{playSong()}
            .onDisappear{appRemote2.playerAPI?.pause()}
    }
    
    func playSong() {
        print("Playlsit & Song IDs....")
        print(songID)
        appRemote2.playerAPI?.pause(defaultCallback)
        appRemote2.playerAPI?.enqueueTrackUri("spotify:track:\(songID!)", callback: defaultCallback)
        appRemote2.playerAPI?.play("spotify:track:\(songID!)", callback: defaultCallback)
        isPlaying = true
    }

        
    var defaultCallback: SPTAppRemoteCallback {
        get {
            return {[self] _, error in
                print("defaultCallBack Running...")
                print("started playing playlist")
                showProgressView = false
                if let error = error {
                    print(error.localizedDescription)
                }
            }
        }
    }
}

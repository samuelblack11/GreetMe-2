//
//  MusicView.swift
//  GreetMe-2
//
//  Created by Sam Black on 1/9/23.
//

import Foundation
import SwiftUI
import CoreData
import CloudKit
import StoreKit
import MediaPlayer
import WebKit
struct MusicSearchView: View {
    @EnvironmentObject var addMusic: AddMusic
    @EnvironmentObject var musicSub: MusicSubscription
    @EnvironmentObject var chosenSong: ChosenSong
    @EnvironmentObject var appDelegate: AppDelegate
    @State var spotDeviceID: String = ""
    @State private var songSearch = ""
    @State private var storeFrontID = "us"
    @State private var userToken = ""
    @State private var searchResults: [SongForList] = []
    //@State private var musicPlayer = MPMusicPlayerController.applicationMusicPlayer
    @State private var player: AVPlayer?
    @State var showFCV: Bool = false
    @State private var showSPV = false
    @State private var showWebView = false
    @State private var isPlaying = false
    @State private var songProgress = 0.0
    @State private var connectToSpot = false
    @EnvironmentObject var sceneDelegate: SceneDelegate
    var appRemote: SPTAppRemote? {get {return (sceneDelegate.appRemote)}}
    @StateObject var spotifyAuth = SpotifyAuth()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var tokenCounter = 0
    @State private var devIDCounter = 0
    @State private var authCode: String? = ""
    let defaults = UserDefaults.standard

    var body: some View {
        NavigationStack {
            TextField("Search Songs", text: $songSearch, onCommit: {
                UIApplication.shared.resignFirstResponder()
                if self.songSearch.isEmpty {
                    self.searchResults = []
                } else {
                    switch appDelegate.musicSub.type {
                    case .Apple:
                        return searchWithAM()
                    case .Neither:
                        return searchWithAM()
                    case .Spotify:
                        return searchWithSpotify(authTokenMain: spotifyAuth.access_Token)
                    }
                }}).padding(.top, 15)
            NavigationView {
                List {
                    ForEach(searchResults, id: \.self) { song in
                        HStack {
                            Image(uiImage: UIImage(data: song.artImageData)!)
                            VStack{
                                Text(song.name)
                                    .font(.headline)
                                    .lineLimit(2)
                                Text(song.artistName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                        }
                        .frame(width: UIScreen.screenWidth, height: (UIScreen.screenHeight/7))
                        .onTapGesture {
                            print("Playing \(song.name)")
                            createChosenSong(song: song)
                        }
                    }
                }
            }
            .onAppear{
                if appDelegate.musicSub.type == .Spotify {requestSpotAuth();runGetToken();runGetDevID()}
            }
            .popover(isPresented: $showSPV) {SmallPlayerView(songID: chosenSong.id, songName: chosenSong.name, songArtistName: chosenSong.artistName, songArtImageData: chosenSong.artwork, songDuration: chosenSong.durationInSeconds, songPreviewURL: chosenSong.songPreviewURL, confirmButton: true, showFCV: $showFCV, spotDeviceID: spotifyAuth.deviceID)
                    .presentationDetents([.fraction(0.4)])
                    .fullScreenCover(isPresented: $showFCV) {FinalizeCardView()}
            }
            .environmentObject(spotifyAuth)
            .sheet(isPresented: $connectToSpot){SpotPlayer().frame(height: 100)}
            .sheet(isPresented: $showWebView){WebVCView(authURLForView: spotifyAuth.authForRedirect, authCode: $authCode)}
        }
        .environmentObject(spotifyAuth)
    }

}
extension MusicSearchView {
    
    func runGetToken() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            //print("Running runGetToken....")
            if tokenCounter == 0 {if authCode != "" {getSpotToken()}}
        }
    }
    
    func runGetDevID() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            //print("Running runGetDevID....")
            if devIDCounter == 0 {if spotifyAuth.access_Token != "" {getSpotDevices()}}
        }
    }

    func spotRequestLogic() {
        // unsure wheter auth code expires
        //if defaults.object(forKey: "SpotifyAuthCode") != nil {
            // access token valid for one hour (3600 seconds)
         //   print("check1")
         //   print((defaults.object(forKey: "SpotifyAuthCode") as? String))
          //  if defaults.object(forKey: "SpotifyAccessToken") != nil {
          //      print("check2")
           //     if defaults.object(forKey: "SpotifyDeviceID") != nil {}
          //      else {print("check3");getSpotDevices()}
           // }
           // else {print("check4");
           //     do{try getSpotToken()}
           //     catch {requestSpotAuth(); getSpotToken()}
                //getSpotDevices
          //  }
        //}
        //do {print("check1"); try getSpotToken1();
            //getSpotDevices()
            
        //}
        //catch {print("check2"); requestSpotAuth(); getSpotToken2();
            //getSpotDevices()
        //}
        //determineSpotifyAction()
        //determineSpotifyAction()
    }
    
    func requestSpotAuth() {
        SpotifyAPI().requestAuth(completionHandler: {(response, error) in
            if response != nil {
                DispatchQueue.main.async {
                    print(response!)
                    spotifyAuth.authForRedirect = response!
                    showWebView = true
                    //getSpotToken()
                }
            }})
        
    }
    
    //searchWithSpotify(authTokenMain: spotifyAuth.access_Token)
    func getSpotToken() {
        tokenCounter = 1
        print(authCode!)
        spotifyAuth.auth_code = authCode!
        SpotifyAPI().getToken(authCode: authCode!, completionHandler: {(response, error) in
            if response != nil {
                DispatchQueue.main.async {
                    spotifyAuth.access_Token = response!.access_token
                    spotifyAuth.refresh_Token = response!.refresh_token
                    defaults.set(response!.access_token, forKey: "SpotifyAccessToken")
                    defaults.set(response!.refresh_token, forKey: "SpotifyRefreshToken")
                    print("Access Values3....")
                    print(spotifyAuth.auth_code)
                    print(spotifyAuth.access_Token)
                    print(spotifyAuth.refresh_Token)
                }
                if error != nil {
                    print("Error... \(error?.localizedDescription)")
                    
                }
            }
        })
    }
    
    //searchWithSpotify(authTokenMain: spotifyAuth.access_Token)
    func getSpotDevices() {
        print("Running getSpotDevices().....")
        devIDCounter = 1
        appRemote?.authorizeAndPlayURI("")
        appRemote?.playerAPI?.getPlayerState()
        appRemote?.playerAPI?.pause()
        SpotifyAPI().getSpotDevices(authToken: spotifyAuth.access_Token, completionHandler: {(response, error) in
            if response != nil {
                DispatchQueue.main.async {
                    print("#####")
                    print("Running getSpotDevices()...")
                    print(response!)
                    for device in response!.devices {
                        print(device)
                        if device.type == "smartphone" {
                            print("Device ID...\(device.id)")
                            spotifyAuth.deviceID = device.id
                            defaults.set(device.id, forKey: "SpotifyDeviceID")
                        }
                        break
                    }
                }
            }})
    }
    
    func createChosenSong(song: SongForList) {
        if appDelegate.musicSub.type == .Spotify {chosenSong.spotID = song.id}
        if appDelegate.musicSub.type == .Apple {chosenSong.id = song.id; chosenSong.songPreviewURL = song.previewURL}
        chosenSong.name = song.name
        chosenSong.artistName = song.artistName; chosenSong.artwork = song.artImageData
        chosenSong.durationInSeconds = Double(song.durationInMillis/1000)
        songProgress = 0.0; isPlaying = true; showSPV = true
    }
    
    func searchWithSpotify(authTokenMain: String) {
        SpotifyAPI().searchSpotify(self.songSearch, authToken: spotifyAuth.access_Token, completionHandler: {(response, error) in
            if response != nil {
                DispatchQueue.main.async {
                    for song in response! {
                        print("BBBBB")
                        print(song)
                        let artURL = URL(string:song.album.images[2].url)
                        let _ = getURLData(url: artURL!, completionHandler: {(artResponse, error2) in
                            let songForList = SongForList(id: song.id, name: song.name, artistName: song.artists[0].name, artImageData: artResponse!, durationInMillis: song.duration_ms, isPlaying: false, previewURL: "")
                            searchResults.append(songForList)})
                    }}}; if response != nil {print("No Response!")}
                        else{debugPrint(error?.localizedDescription)}
        })
    }
    

    func searchWithAM() {
        SKCloudServiceController.requestAuthorization {(status) in if status == .authorized {
            self.userToken = AppleMusicAPI().getUserToken()
            //self.storeFrontID = AppleMusicAPI().fetchStorefrontID(userToken: userToken)
            self.searchResults = AppleMusicAPI().searchAppleMusic(self.songSearch, storeFrontID: storeFrontID, userToken: userToken, completionHandler: { (response, error) in
                if response != nil {
                    DispatchQueue.main.async {
                        for song in response! {
                            let artURL = URL(string:song.attributes.artwork.url.replacingOccurrences(of: "{w}", with: "80").replacingOccurrences(of: "{h}", with: "80"))
                            let _ = getURLData(url: artURL!, completionHandler: { (artResponse, error2) in
                                let songForList = SongForList(id: song.attributes.playParams.id, name: song.attributes.name, artistName: song.attributes.artistName, artImageData: artResponse!, durationInMillis: song.attributes.durationInMillis, isPlaying: false, previewURL: song.attributes.previews[0].url)
                                searchResults.append(songForList)
                            })}}}; if response != nil {print("No Response!")}
                else {debugPrint(error?.localizedDescription)}}
            )}}
    }
    
    func getSongDetailsFromOtherService() {}
        
    func getURLData(url: URL, completionHandler: @escaping (Data?,Error?) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("v1", forHTTPHeaderField: "Accept-Version")
        let dataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {return}
            DispatchQueue.main.async {completionHandler(data, nil)}
        }
        dataTask.resume()
    }
    
}
            

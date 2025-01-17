//
//  SongPreviewPlayer.swift
//  Saloo
//
//  Created by Sam Black on 2/26/23.
//

import Foundation
import Foundation
import SwiftUI
import CoreData
import CloudKit
import StoreKit
import MediaPlayer
import AVFoundation
import AVFAudio
// 
class PlayerWrapper: NSObject, ObservableObject {
    static let shared = PlayerWrapper()
    @Published var player: AVPlayer?
    
    override init() {
        super.init()
        self.player = AVPlayer()
    }
    
    func play(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        player?.replaceCurrentItem(with: playerItem)
        player?.play()
    }
    
    func pause() {
        player?.pause()
    }
    
    func seek(to time: CMTime) {
        player?.seek(to: time)
    }
}


class AudioSessionManager: ObservableObject {
    static let shared = AudioSessionManager()
    let audioSession = AVAudioSession.sharedInstance()

    init() {
        // configure audio session settings
        do {
            try audioSession.setCategory(.playback)
            try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
        }
    }

    func activateAudioSession() {
        do {try audioSession.setActive(true)} catch {print("Failed to activate audio session: \(error.localizedDescription)")}
    }

    func deactivateAudioSession() {
        do {
            
            try audioSession.setActive(false)
            print("Deactivated Audio Session..")
            
        }
        catch {print("Failed to deactivate audio session: \(error.localizedDescription)")}
    }
}

struct SongPreviewPlayer: View {
    @State var songID: String?
    @State var songName: String?
    @State var songArtistName: String?
    @State var songArtImageData: Data?
    @State var songDuration: Double?
    @State var songPreviewURL: String?
    @State var songURL: String?
    @State private var songProgress = 0.0
    @State private var isPlaying = true
    @State var confirmButton: Bool
    @EnvironmentObject var appDelegate: AppDelegate
    @State var songAddedUsing: String
    @State var color: Color?
    @EnvironmentObject var audioManager: AudioSessionManager
    @EnvironmentObject var avPlayer: PlayerWrapper
    @Binding var chosenCard: CoreCard?
    @ObservedObject var gettingRecord = GettingRecord.shared
    @EnvironmentObject var appState: AppState
    @State private var showLoginView = false

    var body: some View {
        PreviewPlayerView()
            .onAppear {
                if songPreviewURL == nil || songPreviewURL!.isEmpty {chosenCard?.cardType = "noMusicNoGift"}
                startCheckingPlaybackState()
                if !appDelegate.isPlayerCreated {
                    createPlayer()
                    appDelegate.isPlayerCreated = true
                }
                else {
                    audioManager.activateAudioSession()
                    let playerItem = AVPlayerItem(url: URL(string: songPreviewURL!)!)
                    avPlayer.player = AVPlayer.init(playerItem: playerItem)
                    avPlayer.player!.play()
                }
            }
            .navigationBarItems(leading:Button {
                avPlayer.player! .pause();avPlayer.player!.replaceCurrentItem(with: nil)
                if UserSession.shared.isSignedIn == false {showLoginView = true}
                else{chosenCard = nil}
            } label: {Image(systemName: "chevron.left").foregroundColor(.blue); Text("Back")}.disabled(gettingRecord.isShowingActivityIndicator))
            .fullScreenCover(isPresented: $showLoginView) {LaunchView(isFirstLaunch: true, isPresentedFromECardView: $showLoginView, cardFromShare: $chosenCard)}
            .onDisappear{
                AudioSessionManager.shared.deactivateAudioSession()
                avPlayer.player!.pause();avPlayer.player!.replaceCurrentItem(with: nil);
                avPlayer.player!.currentItem?.cancelPendingSeeks()
                avPlayer.player!.currentItem?.asset.cancelLoading()
                avPlayer.player  = nil
            }
        
    }
        
    
    @ViewBuilder var selectButtonPreview: some View {
        Button {appState.currentScreen = .buildCard([.finalizeCardView]); avPlayer.player!.pause(); songProgress = 0.0} label: {Text("Select Song For Card").foregroundColor(.blue)}
    }
    
    func createPlayer() {
        do {
            try audioManager.activateAudioSession()
            let playerItem = AVPlayerItem(url: URL(string: songPreviewURL!)!)
            avPlayer.player  = AVPlayer.init(playerItem: playerItem)
            avPlayer.player!.play()
        }
        catch { print(error.localizedDescription) }
    }
    
    func startCheckingPlaybackState() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let player = self.avPlayer.player {
                switch player.timeControlStatus {
                case .playing:
                    self.isPlaying = true
                case .paused, .waitingToPlayAtSpecifiedRate:
                    self.isPlaying = false
                @unknown default:
                    print("Unknown AVPlayer timeControlStatus.")
                }
            } else {self.isPlaying = false}
        }
    }
    
    func PreviewPlayerView() -> some View {
        let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        return  VStack(alignment: .center) {
            Image(uiImage: UIImage(data: songArtImageData!)!)
            Link(songName!, destination: URL(string: songURL!)!)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            Text(songArtistName!)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            HStack {
                Button {
                    avPlayer.player!.seek(to: .zero)
                    avPlayer.player!.play()
                    songProgress = 0.0
                    isPlaying = true
                } label: {
                    ZStack {
                        Circle()
                            .accentColor(color)
                            .shadow(radius: 10)
                        Image(systemName: "arrow.uturn.backward" )
                            .foregroundColor(.white)
                            .font(.system(.title))
                    }
                }
                .frame(maxWidth: UIScreen.screenHeight/12, maxHeight: UIScreen.screenHeight/12)
                Button {
                    isPlaying.toggle()
                    if avPlayer.player!.timeControlStatus.rawValue == 2 {avPlayer.player!.pause()}
                    else if songProgress == Double(30) {avPlayer.player!.seek(to: .zero); avPlayer.player!.play()}
                    else {avPlayer.player!.play()}
                } label: {
                    ZStack {
                        Circle()
                            .accentColor(color)
                            .shadow(radius: 10)
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .foregroundColor(.white)
                            .font(.system(.title))
                    }
                }
                .frame(maxWidth: UIScreen.screenHeight/12, maxHeight: UIScreen.screenHeight/12)
            }
            ProgressView(value: songProgress, total: Double(30))
                .onReceive(timer) {_ in
                    songProgress = CMTimeGetSeconds(avPlayer.player!.currentItem?.currentTime() ?? .zero) + 1
                }
            HStack{
                Text(convertToMinutes(seconds:Int(songProgress)))
                Spacer()
                Text(convertToMinutes(seconds: 30 - Int(songProgress)))
                    .padding(.trailing, 10)
            }
            if confirmButton == true {selectButtonPreview}
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .onAppear{
            if songAddedUsing == "Spotify" {color = .green}
            else {color = .pink}
        }
    }
    
    func convertToMinutes(seconds: Int) -> String {
        let m = seconds / 60
        let s = String(format: "%02d", seconds % 60)
        let completeTime = String("\(m):\(s)")
        return completeTime
    }
}

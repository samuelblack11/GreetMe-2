//
//  GreetMe_2App.swift
//  GreetMe-2
//
//  Created by Sam Black on 4/30/22.

import SwiftUI
import CloudKit

@main
struct Saloo_App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate3
    @StateObject var appDelegate = AppDelegate()
    @StateObject var sceneDelegate = SceneDelegate()
    
    @ObservedObject var alertVars = AlertVars.shared
    let persistenceController = PersistenceController.shared
    @State private var isCountdownShown: Bool = false
    @State private var isSignedIn = UserDefaults.standard.string(forKey: "SalooUserID") != nil
    @State private var userID = UserDefaults.standard.object(forKey: "SalooUserID") as? String
    @StateObject var appState = AppState.shared
    @Environment(\.scenePhase) private var scenePhase
    let defaults = UserDefaults.standard

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    if let musicSub = (defaults.object(forKey: "MusicSubType") as? String) {
                        if musicSub == "Spotify"{APIManager.shared.initializeSpotifyManager(){}}
                        if musicSub == "Apple Music"{APIManager.shared.initializeAM(){}}
                    }
                    print(";;;")
                    print(appState.currentScreen)
                    
                }
                .environment(\.managedObjectContext, persistenceController.persistentContainer.viewContext)
                .environmentObject(SpotifyManager.shared)
                .environmentObject(NetworkMonitor.shared)
                .environmentObject(sceneDelegate)
                .environmentObject(MusicSubscription.shared)
                .environmentObject(ShowDetailView.shared)
                .environmentObject(GettingRecord.shared)
                .environmentObject(appDelegate)
                .environmentObject(appState)
                .environmentObject(ChosenCoverImageObject.shared)
                .environmentObject(Occassion.shared)
                .environmentObject(CollageImage.shared)
                .environmentObject(ChosenImages.shared)
                .environmentObject(ChosenSong.shared)
                .environmentObject(NoteField.shared)
                .environmentObject(Annotation.shared)
                .environmentObject(AddMusic.shared)
                .environmentObject(CardsForDisplay.shared)
                .environmentObject(UserSession.shared)
                .environmentObject(CollectionManager.shared)
                .environmentObject(ScreenManager.shared)
                .environmentObject(APIManager.shared)
                .environmentObject(PersistenceController.shared)
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .active {
                        if UserSession.shared.isSignedIn{CardsForDisplay.shared.loadCoreCards{}}
                        else {appState.currentScreen = .login}
                        // Check if user is banned when the app comes to foreground
                        if let salooUserID = (UserDefaults.standard.object(forKey: "SalooUserID") as? String) {
                            checkUserBanned(userId: salooUserID) { (isBanned, error) in
                                print("Checking banned status...isBanned = \(isBanned)")
                                if isBanned == true {alertVars.alertType = .userBanned; alertVars.activateAlert = true}
                                // Other error handling goes here
                            }
                        }
                        else{print("no salooUserID due to first launch")}
                    }
                }
        }
    }
    func checkUserBanned(userId: String, completion: @escaping (Bool, Error?) -> Void) {
        guard let url = URL(string: "https://saloouserstatus.azurewebsites.net/is_banned?user_id=\(userId)") else {
            // Handle invalid URL error
            print("Invalid URL")
            completion(false, nil)
            return
        }

        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                // Handle error
                completion(false, error)
                return
            }

            if let data = data {
                do {
                    if let responseDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        let value: Optional<Any> = responseDict["is_banned"]
                        if let stringValue = value as? String {
                            let stringValue2 = stringValue.lowercased()
                            if let isBanned = Bool(stringValue2) {
                                completion(isBanned, nil)
                                return
                            }
                        }
                    }
                }
                catch {
                    // Handle JSON parsing error
                    completion(false, error)
                    return
                }
            }

            // Invalid response or data
            completion(false, nil)
        }

        task.resume()
    }
}

extension View {
    func alertView(alertVars: AlertVars) -> some View {
        self.modifier(AlertViewMod(showAlert: alertVars.activateAlertBinding, activeAlert: alertVars.alertType))
    }
}

enum ActiveAlert {
    case failedConnection, signInFailure, explicitPhoto, offensiveText, namesNotEntered, showCardComplete, showFailedToShare, addMusicPrompt, spotAuthFailed, amAuthFailed, AMSongNotAvailable, gettingRecord, userBanned, reportComplete, deleteCard, mustSelectPic, musicAuthSuccessful, spotNeedPremium
}

struct AlertViewMod: ViewModifier {
    @ObservedObject var gettingRecord = GettingRecord.shared
    @Binding var showAlert: Bool
    var activeAlert: ActiveAlert
    var alertDismissAction: (() -> Void)?    
    var secondDismissAction: (() -> Void)?
    @State var cardToDelete: CoreCard?
    
    func body(content: Content) -> some View {
        content
            .alert(isPresented: $showAlert) {
                switch activeAlert {
                case .musicAuthSuccessful:
                    return Alert(title: Text("You're All Set 🎶"), dismissButton: .default(Text("Ok")))
                case .mustSelectPic:
                    return Alert(title: Text("Please select a Picture!"), dismissButton: .default(Text("Ok")))
                case .deleteCard:
                    return Alert(
                        title: Text("Are you sure you want to delete this card?."),
                        message: Text("This will delete it for all of the card's participants."),
                        primaryButton: .default(Text("Yes, delete it"), action: {alertDismissAction?()}),
                        secondaryButton: .default(Text("No, I'll keep it"), action: {})
                    )
                case .failedConnection:
                    return Alert(title: Text("Network Error"), message: Text("Sorry, we weren't able to connect to the internet. Please reconnect and try again."), dismissButton: .default(Text("OK")))
                case .signInFailure:
                    return Alert(title: Text("Login Failed"), message: Text("Please Try Again"), dismissButton: .default(Text("Dismiss")))
                case .explicitPhoto:
                    return Alert(title: Text("Error"), message: Text("The selected image contains explicit content and cannot be used."), dismissButton: .default(Text("OK")))
                case .offensiveText:
                    return Alert(title: Text("Take it easy!"),message: Text("Tone down the rhetoric and write something else."),dismissButton: .default(Text("Ok")) {})
                case .namesNotEntered:
                    return Alert(title: Text("Please Enter Values for All Fields!"), dismissButton: .default(Text("Ok")))
                case .spotAuthFailed:
                    return Alert(title: Text("Spotify Authorization Failed. If you have a Spotify Subscription, please try authorizing again"), dismissButton: .default(Text("OK"), action: {alertDismissAction?()}))
                case .spotNeedPremium:
                    return Alert(title: Text("Sorry, Saloo Requires a Spotify Premium Membership in order to Connect."), message: Text("Spotify Premium lets you play any track, ad-free and with better audio quality."), primaryButton: .default(Text("Ok ☹️"), action: {alertDismissAction?()}), secondaryButton: .default(Text("Try Spotify Premium for Free"), action: {
                        UIApplication.shared.open(URL(string: "https://spotify.com/premium")!)}
                    ))
                case .amAuthFailed:
                    return Alert(title: Text("Apple Music Authorization Failed. If you have a Apple Music Subscription, please try authorizing again"), dismissButton: .default(Text("OK"), action: {alertDismissAction?()}))
                case .gettingRecord:
                    return Alert(
                        title: Text("We're Saving Your Card to the Cloud."),
                        message: Text("It'll Be Ready In Just a Minute."),
                        primaryButton: .default(Text("OK, I'll Wait"), action: {
                            gettingRecord.showLoadingRecordAlert = false
                            gettingRecord.didDismissRecordAlert = true
                            gettingRecord.isShowingActivityIndicator = true
                        }),
                        secondaryButton: .default(Text("I'll Open My Card Later"), action: {
                            gettingRecord.showLoadingRecordAlert = false
                            gettingRecord.willTryAgainLater = true
                        })
                    )
                case .showFailedToShare:
                    return Alert(title: Text("Network Error"), message: Text("Sorry, we weren't able to connect to the internet. We've saved this card to drafts, where you can share from once you reconnect."), dismissButton: .default(Text("OK")))
                case .userBanned:
                    return Alert(
                        title: Text("User Banned"),
                        message: Text("You have been banned from using this app."),
                        dismissButton: .default(Text("OK"), action: {exit(0)})
                        )
                case .showCardComplete:
                    return Alert(
                        title: Text("Save Complete"),
                        message: nil,
                        dismissButton: .default(Text("Ok"), action: { alertDismissAction?() })
                    )
                case .addMusicPrompt:
                    return Alert(title: Text("Add Song to Card?"),
                                 primaryButton: .default(Text("Hell Yea"), action: {alertDismissAction?()}),
                                 secondaryButton: .default(Text("No Thanks"), action: {secondDismissAction?()}))
                case .AMSongNotAvailable:
                    return Alert(title: Text("Song Not Available"), message: Text("Sorry, this song isn't available. Please select a different one."), dismissButton: .default(Text("OK")){alertDismissAction?()})
                case .reportComplete:
                    return Alert(
                        title: Text("Feedback Received"),
                        message: Text("Thanks for your feedback. We will review these details along with the card itself and will be in touch about your concern."),
                        dismissButton: .default(Text("Ok")) {}
                    )
            }
        }
    }
}

class GettingRecord: ObservableObject {
    static let shared = GettingRecord()
    @Published var isLoadingAlert: Bool = false
    @Published var showLoadingRecordAlert: Bool = false
    @Published var didDismissRecordAlert: Bool = false
    @Published var isShowingActivityIndicator: Bool = false
    @Published var willTryAgainLater: Bool = false
    private init() {} // Ensures no other instances can be created
}

class ShareMD: ObservableObject {
    static let shared = ShareMD()
    @Published var metaData: CKShare.Metadata? = nil
    private init() {} // Ensures no other instances can be created
}

struct LoadingOverlay: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var hasShownLaunchView: Bool
    @EnvironmentObject var gettingRecord: GettingRecord
    @EnvironmentObject var cardsForDisplay: CardsForDisplay
    @EnvironmentObject var appDelegate: AppDelegate
    @State private var remainingTime: Int
    
    init(hasShownLaunchView: Bool? = nil, startTime: Int = 60) {
        _hasShownLaunchView = State(initialValue: hasShownLaunchView ?? false)
        _remainingTime = State(initialValue: startTime)
    }
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var backgroundTime = Date()
    var body: some View {
        if gettingRecord.isLoadingAlert == true && hasShownLaunchView {
            ZStack {
                ProgressView() // This is the built-in iOS activity indicator
                    .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .dark ? .white : appDelegate.appColor))
                    .scaleEffect(2)
            }
        }
        if gettingRecord.isShowingActivityIndicator == true {
            ZStack {
                Color.black.opacity(0.7)
                    .ignoresSafeArea() // This will make the semi-transparent view cover the entire screen
                VStack {
                    if remainingTime > 0 {
                        Text("We're Still Saving Your Card to the Cloud. It'll Be Ready In Just a Minute")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        Text("Time Remaining: \(remainingTime)")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .onReceive(timer) { _ in if remainingTime > 0 {remainingTime -= 1}}
                            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                                backgroundTime = Date()
                            }
                            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                                let elapsedSeconds = Int(Date().timeIntervalSince(backgroundTime))
                                remainingTime = max(remainingTime - elapsedSeconds, 0)
                            }
                    } else {
                        Text("Hold On...This is Taking Longer Than Expected")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    ProgressView() // This is the built-in iOS activity indicator
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2)
                }
            }
            .opacity(gettingRecord.isShowingActivityIndicator ? 1 : 0)
            .allowsHitTesting(gettingRecord.isShowingActivityIndicator) // This will block interaction when the activity indicator is showing
            }
        if !(gettingRecord.isLoadingAlert == true && hasShownLaunchView) && (cardsForDisplay.isLoading == true) || (gettingRecord.isLoadingAlert == true && !hasShownLaunchView) {
            VStack {
                Spacer()
                ProgressView() // This is the built-in iOS activity indicator
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(2)
                Spacer()
                .frame(height: UIScreen.screenHeight/5)
            }
        }
        }
    }

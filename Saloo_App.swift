//
//  GreetMe_2App.swift
//  GreetMe-2
//
//  Created by Sam Black on 4/30/22.

import SwiftUI
import CloudKit




@main
struct Saloo_App: App {
    @StateObject var musicSub = MusicSubscription()
    @StateObject var calViewModel = CalViewModel()
    @StateObject var showDetailView = ShowDetailView()
    let persistenceController = PersistenceController.shared
    @UIApplicationDelegateAdaptor var appDelegate: AppDelegate
    var body: some Scene {
        WindowGroup {
            StartMenu()
                .environment(\.managedObjectContext, persistenceController.persistentContainer.viewContext)
                .environmentObject(musicSub)
                .environmentObject(appDelegate)
                .environmentObject(calViewModel)
                .environmentObject(showDetailView)
        }
    }
}

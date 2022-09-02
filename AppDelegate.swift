//
//  AppDelegate.swift
//  GreetMe-2
//
//  Created by Sam Black on 9/1/22.
//

import Foundation
import SwiftUI
import CloudKit


class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting
        connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions) -> UISceneConfiguration {

        // Create a scene configuration object for the
        // specified session role.
        let config = UISceneConfiguration(name: nil,
            sessionRole: connectingSceneSession.role)

        // Set the configuration's delegate class to the
        // scene delegate that implements the share
        // acceptance method.
        config.delegateClass = SceneDelegate.self

        return config
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    func windowScene(_ windowScene: UIWindowScene,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        
        let stack = CoreDataStack.shared

        // Get references to the app's persistent container
        // and shared persistent store.
        let store = stack.sharedPersistentStore
        let container = stack.persistentContainer

        // Tell the container to accept the specified share, adding
        // the shared objects to the shared persistent store.
       container.acceptShareInvitations(from: [cloudKitShareMetadata],
                                        into: store) { _, error in
           if let error = error {
             print("acceptShareInvitation error :\(error)")
           }
         }
        //print("***************************************")
        //print(store)
        //print(cloudKitShareMetadata.share)
        //print("***************************************")
        //EnlargeECardView(chosenCard: )
    }
}

//
//  PersistenceController+Share.swift
//  GreetMe-2
//
//  Created by Sam Black on 1/4/23.
//

import Foundation
import CoreData
import UIKit
import CloudKit

#if os(iOS) // UICloudSharingController is only available in iOS.
// MARK: - Convenient methods for managing sharing.
//
extension PersistenceController {
    func presentCloudSharingController(coreCard: CoreCard) {
        var coreCardShare: CKShare?
        let predicate = NSPredicate(format: "CD_uniqueName == %@", coreCard.uniqueName)
        let query = CKQuery(recordType: "CD_CoreCard", predicate: predicate)
        if let shareSet = try? persistentContainer.fetchShares(matching: [coreCard.objectID]),
           let (_, share) = shareSet.first {
            print("ShareSetFirst is true")
            print(share.publicPermission.rawValue)
            coreCardShare = share // moved outside of the block
            let rateLimiter = RateLimiter(maxExecutionsPerSecond: 1)
            if share.publicPermission.rawValue != 3 {
                print("Updating share permissions")
                share.publicPermission = .readWrite
                let modifyOperation = CKModifyRecordsOperation(recordsToSave: [share], recordIDsToDelete: nil)
                rateLimiter.executeFunction {
                    print("executeFunction in closure called")
                    modifyOperation.modifyRecordsCompletionBlock = { saved, _, error in
                        if let error = error {print("Failed to update share permissions: \(error)")}
                        else {print("Share permissions updated")}
                    }
                    self.cloudKitContainer.publicCloudDatabase.add(modifyOperation)
                }
            }
        }
            let sharingController: MyCloudSharingController
            if coreCardShare == nil {
                sharingController = self.newSharingController(unsharedCoreCard: coreCard, persistenceController: self)
          } else {
                print("----"); print(coreCardShare)
                sharingController = MyCloudSharingController(share: coreCardShare!, container: self.cloudKitContainer)
           }
            sharingController.onDismiss = {
             print("Controller has been dismissed.")
             // Other cleanup code...
                if case .buildCard(let steps) = AppState.shared.currentScreen, steps == [.finalizeCardView] {
                    AlertVars.shared.alertType = .showCardComplete
                    AlertVars.shared.activateAlert = true
                }
                else {
                    
                }
            }

            //Setting the presentation style to .formSheet so there's no need to specify sourceView, sourceItem, or sourceRect.
            guard var topVC = UIApplication.shared.windows.first?.rootViewController else {return}
            while let presentedVC = topVC.presentedViewController {topVC = presentedVC }
            sharingController.modalPresentationStyle = .formSheet
            topVC.present(sharingController, animated: true)
    }





    func prepareAndPresentSharingController(sharingController: MyCloudSharingController) {
        sharingController.delegate = self

        // Setting the presentation style to .formSheet so there's no need to specify sourceView, sourceItem, or sourceRect.
        guard var topVC = UIApplication.shared.windows.first?.rootViewController else {return}
        while let presentedVC = topVC.presentedViewController {topVC = presentedVC }

        sharingController.modalPresentationStyle = .formSheet
        topVC.present(sharingController, animated: true)
    }

            
    
    func presentCloudSharingController(share: CKShare) {
        let sharingController = MyCloudSharingController(share: share, container: cloudKitContainer)
        sharingController.delegate = self
        /**
         Setting the presentation style to .formSheet so there's no need to specify sourceView, sourceItem, or sourceRect.
         */
        if let viewController = rootViewController {
            sharingController.modalPresentationStyle = .formSheet
            viewController.present(sharingController, animated: true)
        }
    }
    
    private func newSharingController(unsharedCoreCard: CoreCard, persistenceController: PersistenceController) -> MyCloudSharingController {
        let sharingController = MyCloudSharingController { (controller, completion: @escaping (CKShare?, CKContainer?, Error?) -> Void) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("Called new sharing controller2...")
                let rateLimiter = RateLimiter(maxExecutionsPerSecond: 1)
                rateLimiter.executeFunction {
                    self.persistentContainer.share([unsharedCoreCard], to: nil) { objectIDs, share, container, error in
                        print("Beginning share completion handler...")
                        if let share = share {
                            print("Share = Share")
                            self.configure(share: share,coreCard: unsharedCoreCard)
                            // Set the available permissions to an empty set to load the share into the sharing controller
                            controller.availablePermissions = []
                        }
                        print("Called share completion")
                        print(share?.publicPermission.rawValue)
                        completion(share, container, error)
                    }
                }
            }
        }
        return sharingController
    }
    
    
    
    func createCKShare(unsharedCoreCard: CoreCard, persistenceController: PersistenceController) {
        let sharingController = MyCloudSharingController { (controller, completion: @escaping (CKShare?, CKContainer?, Error?) -> Void) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            print("Called new sharing controller3...")
            
            self.persistentContainer.share([unsharedCoreCard], to: nil) { objectIDs, share, container, error in
                print("Beginning share completion handler...")
                if let share = share {
                    print("Share = Share")
                    self.configure(share: share,coreCard: unsharedCoreCard)
                    // Set the available permissions to an empty set to load the share into the sharing controller
                    controller.availablePermissions = []
                }
                print("Called share completion")
                completion(share, container, error)
            }
            }
        }
    }

        
    
    
    
    private func newSharingController(sharedRootRecord: CKRecord,
                                      database: CKDatabase,
                                      completionHandler: @escaping (MyCloudSharingController?) -> Void) {
        let shareRecordID = sharedRootRecord.share!.recordID
        let fetchRecordsOp = CKFetchRecordsOperation(recordIDs: [shareRecordID])

        fetchRecordsOp.fetchRecordsCompletionBlock = { recordsByRecordID, error in
            guard handleCloudKitError(error, operation: .fetchRecords, affectedObjects: [shareRecordID]) == nil,
                let share = recordsByRecordID?[shareRecordID] as? CKShare else {
                return
            }
            
            DispatchQueue.main.async {
                let sharingController = MyCloudSharingController(share: share, container: self.cloudKitContainer)
                completionHandler(sharingController)
            }
        }
        database.add(fetchRecordsOp)
    }

    private var rootViewController: UIViewController? {
        for scene in UIApplication.shared.connectedScenes {
            if scene.activationState == .foregroundActive,
               let sceneDeleate = (scene as? UIWindowScene)?.delegate as? UIWindowSceneDelegate,
               let window = sceneDeleate.window {
                return window?.rootViewController
            }
        }
        print("\(#function): Failed to retrieve the window's root view controller.")
        return nil
    }
}

extension PersistenceController: UICloudSharingControllerDelegate {
    /**
     CloudKit triggers the delegate method in two cases:
     - An owner stops sharing a share.
     - A participant removes themselves from a share by tapping the Remove Me button in UICloudSharingController.
     
     After stopping the sharing,  purge the zone or just wait for an import to update the local store.
     This sample chooses to purge the zone to avoid stale UI. That triggers a "zone not found" error because UICloudSharingController
     deletes the zone, but the error doesn't really matter in this context.
     
     Purging the zone has a caveat:
     - When sharing an object from the owner side, Core Data moves the object to the shared zone.
     - When calling purgeObjectsAndRecordsInZone, Core Data removes all the objects and records in the zone.
     To keep the objects, deep copy the object graph you want to keep and make sure no object in the new graph is associated with any share.
     
     The purge API posts an NSPersistentStoreRemoteChange notification after finishing its job, so observe the notification to update
     the UI, if necessary.
     */
    func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
        print("DID STOP SHARING")
        if let share = csc.share {
            purgeObjectsAndRecords(with: share)
        }
    }

    func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
        print("Saved Share")
        if let share = csc.share, let persistentStore = share.persistentStore {
            persistentContainer.persistUpdatedShare(share, in: persistentStore) { (share, error) in
                if let error = error {
                    print("\(#function): Failed to persist updated share: \(error)")
                }
            }
        }
    }

    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        print("\(#function): Failed to save a share: \(error)")
    }
    
    func itemTitle(for csc: UICloudSharingController) -> String? {
        return csc.share?.title ?? "A Greeting From Saloo"
    }
    
    func cloudSharingController(_ csc: UICloudSharingController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return csc.share
    }
    
    func cloudSharingControllerDidDismiss(_ csc: UICloudSharingController) {
        DispatchQueue.main.async {
            print("Did call cloud sharing controller dismiss...")
            AlertVars.shared.alertType = .showCardComplete
            AlertVars.shared.activateAlert = true
        }
    }
}
#endif

extension PersistenceController {
    
    func shareObject(_ unsharedObject: NSManagedObject, to existingShare: CKShare?,
                     completionHandler: ((_ share: CKShare?, _ error: Error?) -> Void)? = nil)
    {
        persistentContainer.share([unsharedObject], to: existingShare) { (objectIDs, share, container, error) in
            guard error == nil, let share = share else {
                print("\(#function): Failed to share an object: \(error!))")
                completionHandler?(share, error)
                return
            }
            /**
             Deduplicate tags, if necessary, because adding a photo to an existing share moves the whole object graph to the associated
             record zone, which can lead to duplicated tags.
             */

            if existingShare != nil {
                if let tagObjectIDs = objectIDs?.filter({ $0.entity.name == "CoreCard" }), !tagObjectIDs.isEmpty {
                    //self.deduplicateAndWait(tagObjectIDs: Array(tagObjectIDs))
                }
            } else {
                //self.configure(share: share)
            }
            /**
             Synchronize the changes on the share to the private persistent store.
             */

            self.persistentContainer.persistUpdatedShare(share, in: self.publicPersistentStore) { (share, error) in
                if let error = error {
                    print("\(#function): Failed to persist updated share: \(error)")
                }
                completionHandler?(share, error)
            }
        }
    }
    
    /**
     Delete the Core Data objects and the records in the CloudKit record zone associated with the share.
     */
    func purgeObjectsAndRecords(with share: CKShare, in persistentStore: NSPersistentStore? = nil) {
        guard let store = (persistentStore ?? share.persistentStore) else {
            print("\(#function): Failed to find the persistent store for share. \(share))")
            return
        }
        persistentContainer.purgeObjectsAndRecordsInZone(with: share.recordID.zoneID, in: store) { (zoneID, error) in
            if let error = error {
                print("\(#function): Failed to purge objects and records: \(error)")
            }
        }
    }

    func existingShare(coreCard: CoreCard) -> CKShare? {
        if let shareSet = try? persistentContainer.fetchShares(matching: [coreCard.objectID]),
           let (_, share) = shareSet.first {
            return share
        }
        return nil
    }
    
    func share(with title: String) -> CKShare? {
        let stores = [publicPersistentStore]
        let shares = try? persistentContainer.fetchShares(in: stores)
        let share = shares?.first(where: { $0.title == title })
        return share
    }
    
    func shareTitles() -> [String] {
        let stores = [publicPersistentStore]
        let shares = try? persistentContainer.fetchShares(in: stores)
        return shares?.map { $0.title } ?? []
    }
    //private func configure(share: CKShare, with coreCard: CoreCard? = nil) {
    private func configure(share: CKShare, coreCard: CoreCard?) {
        share[CKShare.SystemFieldKey.title] = "A Greeting from Saloo"
        share[CKShare.SystemFieldKey.thumbnailImageData] = coreCard?.coverImage
        share.publicPermission = .readWrite
        print("Did configure")
    }
}

extension PersistenceController {
    func addParticipant(emailAddress: String, permission: CKShare.ParticipantPermission = .readWrite, share: CKShare,
                        completionHandler: ((_ share: CKShare?, _ error: Error?) -> Void)?) {
        /**
         Use the email address to look up the participant from the private store. Return if the participant doesn't exist.
         Use privatePersistentStore directly because only the owner may add participants to a share.
         */
        let lookupInfo = CKUserIdentity.LookupInfo(emailAddress: emailAddress)
        let persistentStore = publicPersistentStore //share.persistentStore!

        persistentContainer.fetchParticipants(matching: [lookupInfo], into: persistentStore) { (results, error) in
            guard let participants = results, let participant = participants.first, error == nil else {
                completionHandler?(share, error)
                return
            }
                  
            participant.permission = permission
            participant.role = .publicUser
            share.addParticipant(participant)
            
            self.persistentContainer.persistUpdatedShare(share, in: persistentStore) { (share, error) in
                if let error = error {
                    print("\(#function): Failed to persist updated share: \(error)")
                }
                completionHandler?(share, error)
            }
        }
    }
    
    func deleteParticipant(_ participants: [CKShare.Participant], share: CKShare,
                           completionHandler: ((_ share: CKShare?, _ error: Error?) -> Void)?) {
        for participant in participants {
            share.removeParticipant(participant)
        }
        /**
         Use publicPersistentStore directly because only the owner may delete participants to a share.
         */
        persistentContainer.persistUpdatedShare(share, in: publicPersistentStore) { (share, error) in
            if let error = error {
                print("\(#function): Failed to persist updated share: \(error)")
            }
            completionHandler?(share, error)
        }
    }
}

extension CKShare.ParticipantAcceptanceStatus {
    var stringValue: String {
        return ["Unknown", "Pending", "Accepted", "Removed"][rawValue]
    }
}

extension CKShare {
    var title: String {
        guard let date = creationDate else {
            return "Share-\(UUID().uuidString)"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return "Share-" + formatter.string(from: date)
    }
    
    var persistentStore: NSPersistentStore? {
        let persistentContainer = PersistenceController.shared.persistentContainer
        let publicPersistentStore = PersistenceController.shared.publicPersistentStore
        if let shares = try? persistentContainer.fetchShares(in: publicPersistentStore) {
            let zoneIDs = shares.map { $0.recordID.zoneID }
            if zoneIDs.contains(recordID.zoneID) {
                return publicPersistentStore
            }
        }
        let sharedPersistentStore = PersistenceController.shared.sharedPersistentStore
        if let shares = try? persistentContainer.fetchShares(in: sharedPersistentStore) {
            let zoneIDs = shares.map { $0.recordID.zoneID }
            if zoneIDs.contains(recordID.zoneID) {
                return sharedPersistentStore
            }
        }
        return nil
    }
}

class MyCloudSharingController: UICloudSharingController {
    var onDismiss: (() -> Void)?
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onDismiss?()
    }
}

extension UIViewController {
    var topmostViewController: UIViewController {
        return presentedViewController?.topmostViewController ?? self
    }
}

//
//  UnsplashResponse.swift
//  GreetMe-2
//
//  Created by Sam Black on 4/30/22.
//

import Foundation
import UIKit


struct PhotoCollections: Decodable {
    let collections: [PhotoCollection]
}

struct CollectionPair: Decodable, Identifiable {
    let title: String
    let id: String
}

struct CollectionPair2: Decodable, Identifiable {
    let title: String
    let id: String
    let type: String
}

enum CollectionType: String, CaseIterable {
    case yearRound = "Year-Round Occassions"
    case winter = "Winter Holidays"
    case spring = "Spring Holidays"
    case summer = "Summer Holidays"
    case fall = "Fall Holidays"
}

struct PhotoCollection: Decodable {
    let id: String
    let title: String
    let description: String?
    let published_at: String
    let last_collected_at: String
    let updated_at: String
    let total_photos: Int
    let `private`: Bool
    let share_key: String
    let cover_photo: coverPhoto
}
struct coverPhoto: Decodable {
    let id: String
    let width: Int
    let height: Int
    let color: String
    let blu_hash: String?
    let likes: Int
    let liked_by_user: Bool
    let description: String?
    let user: userDetails
    let urls: variousURLs
    let links: variousLinks
}

struct PicResponse: Decodable {
    let total: Int
    let total_pages: Int
    let results: [ResultDetails]
}
 
// CONFIRMED KEYS
struct ResultDetails: Decodable {
    let id: String
    let created_at: String
    let updated_at: String?
    let promoted_at: String?
    let width: Int
    let height: Int
    let color: String?
    let blur_hash: String?
    let description: String?
    let alt_description: String?
    let urls: variousURLs
    let links: variousLinks
    // categories showing as empty list
    let categories: [String]?
    let likes: Int?
    let liked_by_user: Bool?
    // current_user_collections showing as empty list
    let current_user_collections: [String]
    // sponsorships showing as None
    //let sponsorship: String?
    // topc_submission showing as empty dictionary
    //let topic_submissions: topicSubmissionDetails
    let user: userDetails
    // Confirmed data types through user (with corresponding notes)
    //let tags: Data!
}

// CONFIRMED KEYS
// Confirmed Data Types
struct variousURLs: Decodable {
    let raw: String?
    let full: String?
    let regular: String?
    let small: String?
    let thumb: String?
    let small_s3: String?
}

// CONFIRMED KEYS
// Confirmed Data Types
struct variousLinks: Decodable {
    let `self`: String?
    let html: String?
    let download: String?
    let download_location: String?

}

// CONFIRMED KEYS
// Confirmed Data Types
struct userDetails: Decodable {
    let id: String?
    let updated_at: String?
    let username: String?
    let name: String?
    let first_name: String?
    let last_name: String?
    let twitter_username: String?
    let portfolio_url: String?
    let bio: String?
    let location: String?
    let links: linkDetails2
    let profile_image: profileImageDetails
    let instagram_username: String?
    let total_collections: Int?
    let total_likes: Int?
    let total_photos: Int?
    let accepted_tos: Bool?
    let for_hire: Bool?
    let social: socialDetails
    
}

// CONFIRMED KEYS
// Confirmed Data Types
struct linkDetails2: Decodable {
    let `self`: String?
    let html: String?
    let photos: String?
    let likes: String?
    let portfolio: String?
    let following: String?
    let followers: String?
}

// CONFIRMED KEYS
// Confirmed Data Types
struct profileImageDetails: Decodable {
    let small: String?
    let medium: String?
    let lage: String?
}

// CONFIRMED KEYS
// Confirmed Data Types
struct socialDetails: Decodable {
    let instagram_username: String?
    let portfolio_url: String?
    let twitter_username: String?
    let paypal_email: String?
}

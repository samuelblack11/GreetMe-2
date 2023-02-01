//
//  SpotResponses.swift
//  Saloo
//
//  Created by Sam Black on 1/31/23.
//

import Foundation




struct SpotResponse: Decodable {
    let tracks: Tracks
}

struct Tracks: Decodable {
    let items: [SpotItem]
}

struct SpotItems: Decodable {
    let dataPoints: [SpotItem]
}

struct SpotItem: Decodable {
    let id: String
    let name: String
    let album: AlbumData
    let artists: [ArtistObject]
    //let previews: [PreviewURL]
    let duration_ms: Int
}

struct ArtistObject: Decodable {
    let name: String
}

struct AlbumData: Decodable {
    let images: [AlbumImages]
}

struct AlbumImages: Decodable {
    let height: Int
    let url: String
    let width: Int
}




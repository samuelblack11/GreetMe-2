//
//  Launch View.swift
//  Saloo
//
//  Created by Sam Black on 5/28/23.
//

import Foundation
import SwiftUI

struct LaunchView: View {
    @EnvironmentObject var appDelegate: AppDelegate
    
    var body: some View {
        ZStack {
            appDelegate.appColor
            Image("logo180")
                .frame(maxWidth: UIScreen.screenWidth/2,maxHeight: UIScreen.screenHeight/3)
        }
        .onAppear {print("LaunchView appeared...")}
        .ignoresSafeArea()
        }
    }




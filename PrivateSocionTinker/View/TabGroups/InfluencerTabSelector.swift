//
//  TabSelector.swift
//  PrivateSocionTinker
//
//  Created by Ted Wind on 4/7/23.
//

import SwiftUI

struct InfluencerTabSelector: View {
    @EnvironmentObject var userViewModel : UserViewModel
    var body: some View {
        withAnimation {
            TabView {
                ContractListView().tabItem {
                    Image(systemName: "newspaper.fill")
                    Text("View All Contracts")
                }
                AgencyView().tabItem {
                    Image(systemName: "person.3.sequence")
                    Text("Agency Dashboard")
                }
            }
        }
    }
}



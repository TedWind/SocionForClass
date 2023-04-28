//
//  ModelView.swift
//  PrivateSocionTinker
//
//  Created by Ted Wind on 4/11/23.
//
import SwiftUI

struct ModelView: View {
    @EnvironmentObject var userViewModel : UserViewModel
    @ObservedObject var agencyViewModel : AgencyViewModel
    var body: some View {
        HStack {
            VStack {
                Text("User: ")
                Text("Name: \(userViewModel.getName())")
                Text("Email: \(userViewModel.user.email)")
                Text("isAgencyOwner: \(String(userViewModel.user.isAgencyOwner))")
                Text("isTalentManager: \(String(userViewModel.user.IsTalentManager))")
                Text("isAgencyOwner: \(String(userViewModel.user.isAgencyOwner))")
                if userViewModel.user.agency != nil {
                    Text("Owned Agency: \(String(userViewModel.user.agency!))")
                }
                Text("Contracts: ")
                ForEach(userViewModel.user.contracts, id: \.self) { contract in
                    Text("Contract: \(contract.name)")
                }
            }
            if userViewModel.user.isInfluencer || userViewModel.user.IsTalentManager || userViewModel.user.isAgencyOwner {
                VStack {
                    Text("Agency Info: ").onTapGesture {
                        print("Agency Name: \(userViewModel.agencyViewModel.getAgencyName())")
                    }
                    Text("Name: \(userViewModel.agencyViewModel.agency.name)")
                    Text("Owner: \(userViewModel.agencyViewModel.agency.owner.firstName)")
                    Text("Influencers:")
                    ForEach(userViewModel.agencyViewModel.agency.influencers, id: \.self) { influencer in
                        Text("\(influencer.firstName)")
                        Text("Contracts: ")
                        ForEach(influencer.contracts, id: \.self) { contract in
                            Text("\(contract.name)")
                        }
                    }
                }
            }
        }
    }
}

struct ModelViewPreview : PreviewProvider {
    static var previews: some View {
        ModelView(agencyViewModel: AgencyViewModel())
            .environmentObject(UserViewModel())
    }
}

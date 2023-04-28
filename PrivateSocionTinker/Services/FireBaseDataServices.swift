//
//  FireBaseDataServices.swift
//  PrivateSocionTinker
//
//  Created by Ted Wind on 4/1/23.
//

import Foundation
import Firebase
import FirebaseDatabase
import SwiftUI

/// Class with a singleton (shared) that should be the access point for all interactions with the FireStore database.
class FireBaseDataServices {
    static let shared = FireBaseDataServices()
    let db = Firestore.firestore()
    
    
    /// Initializes an instance of a user in the database. This will only be called when a User has first register, and populates only the required information. The Contracts collection isn't initialized until one is added for the first time.
    /// - Parameters:
    ///   - id: User ID, the one provided by FireBase and returned from the Authentication.authentication.getUserID() command
    ///   - firstName: First Name
    ///   - lastName: Last Name
    ///   - email: Email
    func startUser (id: String, firstName : String, lastName : String, email : String, isAgencyOwner : Bool, agency : String?, isTalentManager : Bool, isInfluencer : Bool) {
        let userAgencyID : String = agency == nil ? String() : agency!
        print("1Calling document: \(id)")
        db.collection("users").document(id).setData([
            "email" : email,
            "firstName" : firstName,
            "lastName" : lastName,
            "isAgencyOwner" : isAgencyOwner,
            "agency" : userAgencyID,
            "isTalentManager" : isTalentManager,
            "isInfluencer" : isInfluencer
        ])
    }
    

    /// Marks a user as an influencer, and assigns them to a provided agency
    /// - Parameters:
    ///   - userID: userID String
    ///   - agencyID: agencyID String
    func assignInfluencerToAgency (userID : String, agencyID : String) {
        self.documentExists(agencyID: agencyID) { completion in
            if completion {
                print("3Calling document: \(userID)")
                self.db.collection("users").document(userID).updateData([
                    "isInfluencer" : true,
                    "agency" : agencyID
                ])
                print("Completion successful")
            }
            else {
                print("Agency not found")
            }
        }
    }
    
    /// Initializes a new agency in FireStore. Initializes and fills in values for ownerID, agencyName, and puts it under a document with the name agencyID in the agencies collection. Intiailizes but does not store values in influencers and talent managers section.
    /// - Parameters:
    ///   - ownerId: UUID of the user that is the "Creator" of the Agency
    ///   - agencyName: String name of Agency (i.e. Viralist)
    ///   - return: returns a UUID string which serves as the UUID for the agency
    func startAgency (ownerId : String, agencyName : String) -> String {
        let agencyID : String = UUID().uuidString
        db.collection("agencies").document(agencyID).setData([
            "influencers" : [],
            "name" : agencyName,
            "owner" : ownerId,
            "talentManagers" : []
            ])
        return agencyID
    }
    
    /// Checks to see if a an agency exists with a given name, with a completion callback
    /// - Parameters:
    ///   - agencyID: string of agency ID
    ///   - completion: completion callback, true or false, true meaning agency exists
    func documentExists(agencyID: String, completion: @escaping (Bool) -> Void) {
        print("Entered Document Exists")
        print("4Calling document: \(agencyID)")
        let agenciesCollection = FireBaseDataServices.shared.db.collection("agencies").document(agencyID)

        agenciesCollection.getDocument { document, error in
            guard let document = document else  {
                print("Returning false unexpectedly")
                completion(false)
                return
            }
            if document.exists {
                    completion(true)
                    print("Returning true from closure")
                  } else {
                      completion(false)
                     print("Returning false from closure")
                  }
        }
        
    }
  

    
    /// This adds a new contract under the current user, creating a contract collections if it hasn't yet been initialized.
    /// - Parameters:
    ///   - id: UUID provided by the ViewModel
    ///   - contract: the contract to be added
    func addContract (id: String, contract : Contract) {
        var unwrappedRate : Double = 0
        if contract.rate != nil {
            unwrappedRate = contract.rate!
        }
        let unwrappedDate = returnUnwrappedOrEmptyString(optional: Contract.dateToStringForStorage(date: contract.dueDate))
        let unwrappedPostLink = returnUnwrappedOrEmptyString(optional: contract.postLink)
        print("5Calling document: \(contract.id)")
        print("6Calling document: \(id)")
        db.collection("users").document(id).collection("contracts").document(contract.id).setData([
            "company" : contract.company,
            "status" : contract.status.rawValue,
            "name" : contract.name,
            "rate" : unwrappedRate,
            "paymentStatus" : contract.paymentStatus.rawValue,
            "postLink" : unwrappedPostLink,
            "dueDate" : unwrappedDate
        ])
    }
    
    //TODO: Add influencer to agency
    /// Adds influencerID to the influencer Array of a particular AgencyID
    /// - Parameters:
    ///   - agencyID: agencyID String
    ///   - influencerID: influencerID Strng
    func addInfluencerToAgency (agencyID : String, influencerID : String) {
        print("7Calling document: \(agencyID)")
        db.collection("agencies").document(agencyID).updateData([
            "influencers": FieldValue.arrayUnion([influencerID])
            ])
    }
    
    func getContracts(userID : String)  -> [Contract] {
        var returnArray : [Contract] = []
        print("1Calling document: \(userID)")
         db.collection("users").document(userID).collection("contracts").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else {
                print("Error unpacking contracts")
                return
            }
            print("Document count \(documents.count)")
            for queryDocumentSnapshot in documents {
                print("Entered for loop")
                returnArray.append(Contract.toContractFromStringMap(id: queryDocumentSnapshot.documentID, stringMap: queryDocumentSnapshot.data()))
                print("Inside closure count \(returnArray.count)")
            }
        }
        print("Now returning array of length \(returnArray.count)")
        return returnArray
    }
    
    /// Deletes contract document of the provided ID
    /// - Parameters:
    ///   - id: FireStore id of deleted contract
    ///   - contract: Contract contents to be deleted
    func deleteContract (userID : String, contract : Contract) {
        db.collection("users").document(userID).collection("contracts").document(contract.id).delete()
    }
    
    /// Assigns user as an owner of the provided Agency
    /// - Parameters:
    ///   - userID: userID string
    ///   - agencyID: agencyID String
    func assignUserAsOwner (userID : String, agencyID : String) {
        print("10Calling document: \(userID)")
        db.collection("users").document(userID).updateData([
            "isAgencyOwner" : true,
            "agency" : agencyID
        ])
    }
    
    func changeAgencyName(id : String, name : String) {
        print("11Calling document: \(id)")
        db.collection("agencies").document(id).updateData([
            "name" : name
        ])
    }
    
    
    func setFirstName (id : String, name : String) {
        let userRef = db.collection("users")
        print("12Calling document: \(id)")
        userRef.document(id).updateData([
            "firstName": "New.",
            ])
    }
    
    func setLastName (id: String, name : String) {
        let userRef = db.collection("users")
        print("13Calling document: \(id)")
        userRef.document(id).updateData([
            "lastName": "New.",
            ])
    }
    

    
    /// Takes an old contract, and takes updated fields. This will update the old contract in the databse and populate it with the new fields. This will in turn call listeners which will update the local copy of the contract as well.
    /// - Parameters:
    ///   - userID: user authentication ID
    ///   - contract: old Contract (needed for Contract ID)
    ///   - company: new company
    ///   - influencer: new influencer
    ///   - status: new status
    ///   - rate: new rate
    ///   - paymentStatus: new payment status
    ///   - postLink: new post link
    ///   - dueDate: new DueDate
    func editExistingContract (userID : String, contract : Contract, company : String, influencer : String, status : Contract.Progress, rate : Double?, paymentStatus : Contract.Progress, postLink : String?, dueDate : String?) {
        let unwrappedPostLink = returnUnwrappedOrEmptyString(optional: postLink)
        let unwrappedDueDate = returnUnwrappedOrEmptyString(optional: dueDate)
        var unwrappedRate : Double = 0
        if rate != nil {
            unwrappedRate = rate!
        }
        print("DataBaseServices updating status to \(status.rawValue)")
        print("15Calling document: \(userID)")
        
        let contractsRef = db.collection("users").document(userID).collection("contracts")
        print("16Calling document: \(contract.id)")
        contractsRef.document(contract.id).setData([
            "company" : company,
            "name" : influencer,
            "status" : status.rawValue,
            "rate" : unwrappedRate,
            "paymentStatus" : paymentStatus.rawValue,
            "postLink" : unwrappedPostLink,
            "dueDate" : unwrappedDueDate
        ])
    }
    
    private func returnUnwrappedOrEmptyString (optional : String?) -> String {
        if optional != nil {
            return optional!
        } else {
            return ""
        }
    }
    
    func getUserFromID (userID : String, completion : @escaping (User) -> Void) {
        db.collection("users").document(userID).getDocument { document, error in
            var returnUser : User = User()
            guard let document = document else {
                print("Error line 251 FireBaseDataServices")
                return
            }
            
            guard let data = document.data() else {
                print("Error line 255 FireBaseDataServices")
                return
            }
            
            if let firstName : String = data["firstName"] as? String {
                returnUser.firstName = firstName
            }
            
            if let lastName : String = data["lastName"] as? String {
                returnUser.lastName = lastName
            }
            
            if let email : String = data["email"] as? String {
                returnUser.email = email
            }
            
            if let isAgencyOwner : Bool = data["isAgencyOwner"] as? Bool {
                returnUser.isAgencyOwner = isAgencyOwner
            }
            
            if let isInfluencer : Bool = data["isInfluencer"] as? Bool {
                returnUser.isInfluencer = isInfluencer
            }
            
            if let isTalentManager : Bool = data["isTalentManager"] as? Bool {
                returnUser.IsTalentManager = isTalentManager
            }
            
            returnUser.id = userID
            
            
            
            self.db.collection("users").document(userID).collection("contracts").getDocuments {snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error line 288 FireBaseDataServices")
                    return
                }
            
                for document in documents {
                    let contract = Contract.toContractFromStringMap(id: document.documentID, stringMap: document.data())
                    returnUser.contracts.append(contract)
                }
                completion(returnUser)
            }
            
            
        }
        
        
        
    }
    
    
    

    
    

    
}

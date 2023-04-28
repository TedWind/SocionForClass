//
//  LoginViewModel.swift
//  PrivateSocionTinker
//
//  Created by Ted Wind on 3/31/23.
//

import Foundation
import FirebaseAuth
import Firebase

/// The viewmodel class is the viewmodel for the User model. It accesses FireBaseAuthServices and FireBaseDataServices in order to access the FireStore database and do Authentication related things. All edit's to the model are not done directly through the viewmodel. Rather, intents called on the viewmodel will make changes to the FireStore database. On Register and on Log-in attach the listeners and call functions that will update the model as those listeners fire.
class UserViewModel: ObservableObject {
    @Published var user = User()
    @Published var agencyViewModel = AgencyViewModel()
    @Published var loading = false
    @Published var error : Authentication.AuthenticationError?
    @Published var hasError : Bool = false
    
    var registerDisable : Bool {
        user.email.isEmpty || user.password.isEmpty
    }
    
    func resetLogInFields() {
        user.password = ""
        user.firstName = ""
        user.lastName = ""
        user.email = ""
    }
    
    //MARK: Intents
    
    /// Register is called by the View once the user has clicked the register button. Register will access the FireBaseAuthServices shared instance, and attempt to log in. On failure or success, it will return that status as a callback.
    /// - Parameter completion: This is a callback that returns true or false based on success or failure of the authentication
    func register(completion: @escaping (Bool) -> Void) {
        loading = true
        //Unowned self to prevent memory leak
        FireBaseAuthServices.shared.register(credentials: user) { [unowned self] (result: Result<Bool,Authentication.AuthenticationError>) in
            loading = false
            //If successful, login, otherwise set credentials to ""
            switch result {
            case .success:
                user.id = FireBaseAuthServices.shared.getLoggedInID() ?? ""
                print("Registering New User:")
                print("isOwner: \(user.isAgencyOwner)")
                print("Name: \(user.firstName)")
                print("agency: \(user.agency ?? "")")
                FireBaseDataServices.shared.startUser(id: user.id, firstName: user.firstName, lastName: user.lastName, email: user.email, isAgencyOwner: user.isAgencyOwner, agency: user.agency, isTalentManager: user.IsTalentManager, isInfluencer: user.isInfluencer)
                addListeners(id: user.id) { completion in
                    if completion {
                        if self.user.isInfluencer || self.user.isInfluencer || self.user.isAgencyOwner {
                            print("Agency \(self.user.agency!)")
                            self.agencyViewModel.initiateAgencyListeners(userViewModel: self)
                        }
                    }
                }
                print("Successful Reggie")
                completion(true)
            case .failure(let error):
                print("Failed reggie")
                self.error = error
                completion(false)
            }
            user.password = ""
        }
        
    }
    
    /// Adds the current, logged in influencer, as an agency object for a provided agency in FireStore
    /// - Parameters:
    ///   - agencyID: AgencyID as a string
    func addInfluencerToAgency (agencyID : String) {
        if agencyID != "" && agencyID != " " {
            if let userID = self.getID() {
                FireBaseDataServices.shared.addInfluencerToAgency(agencyID: agencyID, influencerID: userID)
            } else {
                print("User not logged in error")
            }
        }
    }
    
    /// LogIn Function: Called with a user name and password, and attempts to log in the user. If it is succesful, will update the UserID of the model, and will also call the addListeners() private function that will add listeners for the current session.
    /// - Parameter completion: callback that says wether or not login was successful
    func logIn(completion: @escaping (Bool) -> Void) {
        loading = true
        //Unowned self to prevent memory leak
        FireBaseAuthServices.shared.logIn(credentials: user) { [unowned self] (result: Result<FireBaseAuthServices,Authentication.AuthenticationError>) in
            print("Logging In")
            print("User ID is")
            loading = false
            //If successful, login, otherwise set credentials to ""
            switch result {
            case .success:
                print("Log in success")
                user.id = FireBaseAuthServices.shared.getLoggedInID() ?? ""
                addListeners(id: user.id) { completion in
                    if completion {
                        if self.user.isInfluencer || self.user.isInfluencer || self.user.isAgencyOwner {
                            self.agencyViewModel.initiateAgencyListeners(userViewModel: self)
                        }
                    }
                }
                print(user.id)
                completion(true)
            case .failure(let error):
                self.error = error
                completion(false)
                print("Logging in unsuccess")
            }
            user.password = ""
            user.email = ""
        }
    }
    
    func logOut() {
        self.user = User()
        self.agencyViewModel = AgencyViewModel()
    }
    
    
    
    //MARK: This is where listeners for data are added, both on registration and log in. Any changes to the model need to be reflected here (may also require further changes for functions called by this function).
    private func addListeners(id: String,  completion: @escaping (Bool) -> Void ) {
        print("17Calling document: \(id)")
        let userRef = FireBaseDataServices.shared.db.collection("users").document(id)
        
        userRef.addSnapshotListener {documentSnapshot, error in
            print("Listener Triggered")
            guard let document = documentSnapshot else {
                print("Error with fetch")
                return
            }
            guard let data = document.data() else {
                print("Document data empty")
                return
            }
            
            self.updateUserInfo(data: data) {success in
                if success {
                    completion(true)
                } else {
                    completion(false)
                }
            }
            
        }
        
        let contractRef = userRef.collection("contracts")
        contractRef.addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("Error with fetch")
                return
            }
            var returnArray : [Contract] = []
            for document in documents {
                let id = document.documentID
                let data = document.data()
                returnArray.append(Contract.toContractFromStringMap(id: id, stringMap: data))
            }
            self.user.contracts = returnArray
                
            }
            
        }
    
    /// Takes a user, checks to make suer they are already not assigned anything, and then assigns them as an influencer to a provided agency
    /// - Parameter agencyID: String ID of the Agency it is being assigned
    /// - Returns: Boolean representing wether or not assignment was successful
    func attachInfluencerToAgency (agencyID : String) {
        if let userID = self.getID() {
            FireBaseDataServices.shared.assignInfluencerToAgency(userID: userID, agencyID: agencyID)
        } else {
            print("User not found")
        }
    }
    
    /// Checks to see if the agency held by the local user object matches the paramater
    /// - Parameter agencyID: string of agencyID
    /// - Returns: boolean, true meaning that the two agencies match
    func userAgencyMatches (agencyID : String) -> Bool {
        print("checking if agency matches")
        if (user.agency != nil) {
            print ("userAgencyMatches")
            print("User agency: \(user.agency!) and agencyID: \(agencyID)")
            return user.agency! == agencyID
        }
        return false
    }
    
    /// Checks to make sure that a user is not already registered as an owner, influencer, or talent manager of an agency
    /// - Returns: Boolean. True == has not been assigned, false == already been assigned to something
    func userHasNoRegisteredAgencies () -> Bool {
        return !user.isInfluencer && !user.IsTalentManager && !user.isAgencyOwner && user.agency == nil
    }
    
    /// Takes an Agency Name, and creates a brand new Agency for the provided User under that name
    /// - Parameter agencyName: Name of Agency to be created
    func createAgencyForUser (agencyName : String) {
        if (user.isAgencyOwner) {
            print("User already Owns agency")
            return
        }
        if let id = self.getID() {
            let agencyID = agencyViewModel.createAgencyForUser(userID: id, agencyName: agencyName)
                FireBaseDataServices.shared.assignUserAsOwner(userID: id, agencyID: agencyID)
            }
                print("User not logged in")
        }
    
    /// Part of the listeners pipeline. Everytime someone log's in, this will be called if they own an agency. This will create their corresponding agency object.
    
    
    
    //Used in listener to update User Details
    private func updateUserInfo (data : [String: Any], completion: (Bool) -> Void) {
        
        if let isTalentManager : Bool = data["isTalentManager"] as? Bool {
            user.IsTalentManager = isTalentManager
        }
        
        if let isInfluencer : Bool = data["isInfluencer"] as? Bool {
            user.isInfluencer = isInfluencer
        }
       
        if let lastName : String = data["lastName"] as? String {
            user.lastName = lastName
        }
        if let firstName : String = data["firstName"] as? String {
            user.firstName = firstName
        }

        if let email : String = data["email"] as? String {
            user.email = email
        }
        
        if let isAgencyOwner : Bool = data["isAgencyOwner"] as? Bool {
            user.isAgencyOwner = isAgencyOwner
        }
        
        print("Checking agency")
        if let agency : String = data["agency"] as? String {
            print("Agency we retried:\(agency)")
            if agency == "" || agency == " " || agency.isEmpty {
                print("Updating agency to NIL")
                user.agency = nil
                return
            }
            user.agency = agency
        }
        completion(true)
        print(data)
    }
    
    
    //MARK: All of the following functions are interactions with the model/databse. There should be NO direct updates to the model. Instead, all changes should be made to the database, which are in turn updated directly through the listeners and the functions they call. Any changes to the model (ex. adding fields) need to be reflected in the listeners so that it is always updated.
    
    func getID () -> String? {
        return user.id
    }
    
    
    func addContract (contract : Contract) -> Void {
        if let id = getID() {
            FireBaseDataServices.shared.addContract(id: id, contract: contract)
        }
       
    }
    
    func deleteContract (contract : Contract) -> Void {
        if let id = getID() {
            FireBaseDataServices.shared.deleteContract(userID: id, contract: contract)
        }
    }
    
    func editContract (contract : Contract, company : String, influencer : String, status : Contract.Progress, dueDate : String?, rate : Double?, paymentStatus : Contract.Progress, postLink : String?) {
        if let id = self.getID() {
            print("Updating contract status to \(status.rawValue)")
            FireBaseDataServices.shared.editExistingContract(userID: id, contract: contract, company: company, influencer: influencer, status: status, rate : rate, paymentStatus: paymentStatus, postLink: postLink, dueDate: dueDate)
        } else {
            print("Auth Issue")
        }
    }
    
    func setLastName (name: String) {
        if let id = self.getID() {
            FireBaseDataServices.shared.setFirstName(id: id, name: name)
        } else {
            print("Failure")
        }
    }
    
    func setFirstName (name: String) -> Void {
        if let id = self.getID() {
            FireBaseDataServices.shared.setLastName(id: id, name: name)
        } else {
            print("Failure")
        }
        
    }
    
    func getName() -> String {
        return ("\(user.firstName) \(user.lastName)")
       
    }
    
}

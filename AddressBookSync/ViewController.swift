//
//  ViewController.swift
//  AddressBookSync
//
//  Created by Tran Huu Tam on 10/2/15.
//  Copyright © 2015 Benjaminsoft. All rights reserved.
//

import UIKit
import AddressBook
import AddressBookUI

class ViewController: UIViewController {

    // MARK: UI's elements
    @IBOutlet weak var syncButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    

    // MARK: Class's properties
    let def = NSUserDefaults.standardUserDefaults()
    
    // MARK: View's lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated);
        self.initialize();
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    
    // MARK: View's action handlers
    @IBAction func syncButtonTouchAction(sender: AnyObject) {
        syncAddressBook()
    }
    
    
    // MARK: View's private method
    private func initialize() {
        if let _ = def.objectForKey(kAddressBookDataKey) {
            // Already has Address Book in Local
            self.statusLabel.text = "Sync is done"
        }
        else {
            // run at first time
            authorizeToAccessADB()
        }
    }
    
    private func authorizeToAccessADB() {
        let authorizationStatus = ABAddressBookGetAuthorizationStatus()
        switch authorizationStatus {
        case .Denied, .Restricted:
            self.statusLabel.text = "Go to Setting/Privacy to grant access Address Book."
        case .Authorized:
//            syncAddressBook()
            // get Address Book Phone and save to application data
            saveAddressBookPhoneToLocal()
        case .NotDetermined:
            promptForAddressBookRequestAccess()
            print("Not Determined")
        }
    }
    
    private func saveAddressBookPhoneToLocal() {
        let addressBookPhone = getAddressBookPhone()
        def.setObject(addressBookPhone, forKey: kAddressBookDataKey)
        def.synchronize()
    }
    
    private func promptForAddressBookRequestAccess() {
        let addressBookRef: ABAddressBook? = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
        if let _ = addressBookRef {
            ABAddressBookRequestAccessWithCompletion(addressBookRef) {
                (granted: Bool, error: CFError!) in
                dispatch_async(dispatch_get_main_queue()) {
                    if !granted {
                        self.statusLabel.text = "Denied to access Address Book."
                    } else {
                        self.statusLabel.text = "Syncing is in progress. Please wait."
                        self.syncButton.hidden = true
//                        self.syncAddressBook()
                        self.saveAddressBookPhoneToLocal()
                        self.statusLabel.text = "Sync is done"
                        self.syncButton.hidden = false
                    }
                }
            }
        }
    }
    
    private func syncAddressBook() {
        let addressBookRef: ABAddressBook? = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
        if let _ = addressBookRef {
            let addressBookPhone = getAddressBookPhone()
            if let localAddressBook = def.objectForKey(kAddressBookDataKey) {
                let localAddressBookArr = localAddressBook as! [Dictionary<String, String>]
                var isChanged = false
                for localContact in localAddressBookArr {
                    for phoneContact in addressBookPhone {
                        if localContact["ID"] == phoneContact["ID"] {
                            let name = localContact["Name"]
                            if name == phoneContact["Name"] {
                                if localContact["Phone"] != phoneContact["Phone"] {
                                    isChanged = true
                                    let phone = phoneContact["Phone"]
                                    let oldPhone = localContact["Phone"]
                                    print("Difference Phone in \(oldPhone!) new Phone \(phone!)")
                                }
                            }
                            else {
                                isChanged = true
                                print("Difference Name in \(name)")
                            }
                        }
                    }
                }
                self.syncButton.hidden = false
                if isChanged {
                    self.statusLabel.text = "Done. See the changed contacts in dialog."
                    showListOfChanged()
                }
                else {
                    self.statusLabel.text = "No changes"
                }
            }
        }
        else {
            
        }
    }
    
    private func getAddressBookPhone() -> [Dictionary<String, String>] {
        let addressBookRef: ABAddressBook? = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
        var currentContactsList = [Dictionary<String, String>]()
        if let _ = addressBookRef {
            var contactDetails = [String : String]()
            self.statusLabel.text = "Checking changes in Address Book..."
            let allContacts = ABAddressBookCopyArrayOfAllPeople(addressBookRef).takeRetainedValue() as Array
            for record in allContacts {
                let contact: ABRecordRef = record
                var contactFullName = ""
                var contactPhoneNumber = ""
                let contactid = ABRecordGetRecordID(contact)
                if let _ = ABRecordCopyValue(contact, kABPersonFirstNameProperty), let _ = ABRecordCopyValue(contact, kABPersonLastNameProperty) {
                    let firstName = ABRecordCopyValue(contact, kABPersonFirstNameProperty).takeRetainedValue() as! String
                    let lastName = ABRecordCopyValue(contact, kABPersonLastNameProperty).takeRetainedValue() as! String
                    contactFullName = "\(firstName) \(lastName)"
                }
                else if let _ = ABRecordCopyValue(contact, kABPersonFirstNameProperty) {
                    let firstName = ABRecordCopyValue(contact, kABPersonFirstNameProperty).takeRetainedValue() as! String
                    contactFullName = firstName
                }
                else if let _ = ABRecordCopyValue(contact, kABPersonLastNameProperty) {
                    let lastName = ABRecordCopyValue(contact, kABPersonLastNameProperty).takeRetainedValue() as! String
                    contactFullName = lastName
                }
                let contactPhoneNumbers = ABRecordCopyValue(contact, kABPersonPhoneProperty).takeRetainedValue()
                if ABMultiValueGetCount(contactPhoneNumbers) > 0 {
                    contactPhoneNumber = ABMultiValueCopyValueAtIndex(contactPhoneNumbers, 0).takeRetainedValue() as! String
                    
                }
                contactDetails["ID"] = "\(contactid)"
                contactDetails["Name"] = contactFullName
                contactDetails["Phone"] = contactPhoneNumber
                currentContactsList.append(contactDetails)
            }
        }
        return currentContactsList
    }
    
    private func showListOfChanged() {
        
    }
}


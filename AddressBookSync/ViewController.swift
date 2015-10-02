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
    
    
    // MARK: View's action handlers
    @IBAction func syncButtonTouchAction(sender: AnyObject) {
        authorizeToAccessADB()
    }
    
    
    // MARK: View's private method
    private func initialize() {
        
    }
    
    private func authorizeToAccessADB() {
        let authorizationStatus = ABAddressBookGetAuthorizationStatus()
        switch authorizationStatus {
        case .Denied, .Restricted:
            self.statusLabel.text = "Go to Setting/Privacy to grant access Address Book."
        case .Authorized:
            syncAddressBook()
        case .NotDetermined:
            promptForAddressBookRequestAccess()
            print("Not Determined")
        }
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
                        self.statusLabel.text = "Authorized to access Address Book."
                        self.syncAddressBook()
                    }
                }
            }
        }
    }
    
    private func syncAddressBook() {
        let addressBookRef: ABAddressBook? = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
        var currentContactsList = [Dictionary<String, String>]()
        if let _ = addressBookRef {
            var contactDetails = [String : String]()
            self.statusLabel.text = "Syncing is in progress. Please wait."
            self.syncButton.hidden = true
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
//        print(currentContactsList)
        let def = NSUserDefaults.standardUserDefaults()
        if let savedContacts = def.objectForKey(kAddressBookDataKey) {
            let savedContactsArray = savedContacts as! [Dictionary<String, String>]
            var isChanged = false
            for contact in savedContactsArray {
                for contactCompare in currentContactsList {
                    if contact["ID"] == contactCompare["ID"] {
                        let name = contact["Name"]
                        if name == contactCompare["Name"] {
                            if contact["Phone"] != contactCompare["Phone"] {
                                isChanged = true
                                let phone = contactCompare["Phone"]
                                print("Difference Phone in \(phone)")
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
            if !isChanged {
//                self.statusLabel.text = "Syncing is in progress. Please wait."
            }
        }
        else {
            def.setObject(currentContactsList, forKey: kAddressBookDataKey)
            def.synchronize()
        }
    }
}


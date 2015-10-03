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

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: UI's elements
    @IBOutlet weak var syncButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var dialogContactChangedBlurEffect: UIVisualEffectView!
    @IBOutlet weak var contactChangedTableView: UITableView!
    
    // MARK: Class's properties
    let def = NSUserDefaults.standardUserDefaults()
    var contactChanged = [String]()
    
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
    
    @IBAction func saveChangedTouchAction(sender: AnyObject) {
        saveAddressBookPhoneToLocal()
        closeDialogTouchAction(sender)
        self.statusLabel.text = "Sync is done"
    }
    
    @IBAction func closeDialogTouchAction(sender: AnyObject) {
        dialogContactChangedBlurEffect.hidden = true
        contactChanged.removeAll()
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
            self.statusLabel.text = "Sync is done"
            // get Address Book Phone and save to application data
            saveAddressBookPhoneToLocal()
        case .NotDetermined:
            self.statusLabel.text = "Allow app to access Address Book."
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
        let checkIfAuthen = ABAddressBookCreateWithOptions(nil, nil)
        if let _ = checkIfAuthen {
            let addressBookRef: ABAddressBook? = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
            var isChanged = false
            if let _ = addressBookRef {
                let addressBookPhone = getAddressBookPhone()
                var setPhone = Set<String>()
                for contact in addressBookPhone {
                    setPhone.insert(contact["ID"]!)
                }
                if let localAddressBook = def.objectForKey(kAddressBookDataKey) {
                    let localAddressBookArr = localAddressBook as! [Dictionary<String, String>]
                    var setLocal = Set<String>()
                    for contact in localAddressBookArr {
                        setLocal.insert(contact["ID"]!)
                    }
                    let setRemove = setLocal.subtract(setPhone) // remove contact
                    let setNew = setPhone.subtract(setLocal) // new contact add
                    if setRemove.count > 0 {
                        var countRemove = 0
                        for idRemove in setRemove {
                            for localContact in localAddressBookArr {
                                if localContact["ID"] == idRemove {
                                    countRemove++
                                    isChanged = true
                                }
                            }
                        }
                        contactChanged.append("\(countRemove) contact(s) removed")
                    }
                    if setNew.count > 0 {
                        var countNew = 0
                        for idNew in setNew {
                            for phoneContact in addressBookPhone {
                                if phoneContact["ID"] == idNew {
                                    countNew++
                                    isChanged = true
                                }
                            }
                        }
                        contactChanged.append("\(countNew) contact(s) added")
                    }
                    for localContact in localAddressBookArr {
                        for phoneContact in addressBookPhone {
                            if localContact["ID"] == phoneContact["ID"] {
                                let name = localContact["Name"]
                                if name == phoneContact["Name"] {
                                    if localContact["Phone"] != phoneContact["Phone"] {
                                        isChanged = true
                                        let phone = phoneContact["Phone"]
                                        let oldPhone = localContact["Phone"]
                                        contactChanged.append("\(oldPhone!) -> \(phone!)")
                                        //                                    print("\(oldPhone!) changed to \(phone!)")
                                    }
                                }
                                else {
                                    isChanged = true
                                    let namePhone = phoneContact["Name"]
                                    contactChanged.append("\(name!) -> \(namePhone!)")
                                    //                                print("\(name!) changed to \(namePhone!)")
                                }
                            }
                        }
                    }
                    self.syncButton.hidden = false
                    if isChanged {
                        self.statusLabel.text = "Check done."
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
        else {
            self.statusLabel.text = "Go to Setting/Privacy to grant access Address Book."
        }
    }
    
    private func getAddressBookPhone() -> [Dictionary<String, String>] {
        let addressBookRef: ABAddressBook? = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
        var currentContactsList = [Dictionary<String, String>]()
        if let _ = addressBookRef {
            var contactDetails = [String : String]()
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
        dialogContactChangedBlurEffect.hidden = false
        contactChangedTableView.reloadData()
    }
    
    // MARK: Table view for contacts changed
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let element = contactChanged[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier(CONTACT_CHANGED_CELL_ID)!
        cell.textLabel?.text = element
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contactChanged.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44.0
    }
}


//
//  ViewController.swift
//  AddressBookSync
//
//  Created by Tran Huu Tam on 10/2/15.
//  Copyright © 2015 Benjaminsoft. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    // MARK: UI's elements
    @IBOutlet weak var syncButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    

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
        
    }
    
    
    // MARK: View's private method
    private func initialize() {
        
    }
}


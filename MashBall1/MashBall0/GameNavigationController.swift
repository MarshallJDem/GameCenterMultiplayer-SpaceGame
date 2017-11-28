//
//  GameViewController.swift
//  SquareSplit
//
//  Created by Marshall Demirjian on 1/26/16.
//  Copyright (c) 2016 MarshallD. All rights reserved.
//

import UIKit
import SpriteKit
import GameKit


class GameNavigationController: UINavigationController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(self.showAuthenticationViewController), name: NSNotification.Name(rawValue: PresentAuthenticationViewController), object: nil)
        authenticate()
        
    }
    func showAuthenticationViewController() {
        var gameKitHelper = GameKitHelper.sharedGameKitHelper
        self.topViewController!.present(gameKitHelper.authenticationViewController!, animated: true, completion: { _ in })
    }
    func authenticate(){
        GameKitHelper.sharedGameKitHelper.authenticateLocalPlayer()
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

//
//  GameViewController.swift
//  NetworkTest
//
//  Created by Marshall Demirjian on 3/25/17.
//  Copyright © 2017 MarshallD. All rights reserved.
//

import UIKit
import SpriteKit
import GameKit

class GameViewController: UIViewController {
    
    var networkingEngine: MultiplayerNetworking?
    var isAuthenticated: Bool = false
    var scene: GameScene = GameScene()
    
    @IBAction func buttonClicked(_ sender: Any) {
        if (isAuthenticated){
            GameKitHelper.sharedGameKitHelper.findMatchWithMinPlayers(minPlayers: 2, maxPlayers: 2, viewController: self, delegate: networkingEngine!)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        //  loadGameScene()
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerAuthenticated), name: NSNotification.Name(rawValue: LocalPlayerIsAuthenticated), object: nil)
        loadGameScene()
        scene.currentPlayerIndex = 0
    }
    
    
    func playerAuthenticated() {
        
        networkingEngine = MultiplayerNetworking()
        
        
        scene = GameScene(size: view.bounds.size)
        
        networkingEngine!.delegate = scene
        networkingEngine!.viewController = self
        
        isAuthenticated = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func matchStarted() {
        print("Match started")
    }
    
    func matchEnded() {
        print("Match ended")
    }
    func match(match: GKMatch, didReceiveData data: NSData, fromPlayer playerID: String) {
        print("Received data")
    }
    
    func loadGameScene() {
        scene.scaleMode = .resizeFill
        scene.viewController = self
        scene.networkingEngine = networkingEngine
        
        
        let transitionType = SKTransition.flipHorizontal(withDuration: 1.0)
        let skView1 = view as! SKView
        skView1.ignoresSiblingOrder = true
        skView1.presentScene(scene,transition: transitionType)
    }
}


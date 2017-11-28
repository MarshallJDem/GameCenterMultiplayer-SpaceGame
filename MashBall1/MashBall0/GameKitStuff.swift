//
//  GameKitStuff.swift
//  NetworkTest
//
//  Created by Marshall Demirjian on 3/25/17.
//  Copyright © 2017 MarshallD. All rights reserved.
//

import GameKit
import SpriteKit

let PresentAuthenticationViewController = "present_authentication_view_controller"
let LocalPlayerIsAuthenticated = "local_player_authenticated"


protocol GameKitHelperDelegate: class {
    func matchStarted()
    
    func matchEndedAbruptly()
    
    func match(match: GKMatch, data: Data, playerID: String)
}


class GameKitHelper: NSObject, GKMatchmakerViewControllerDelegate, GKMatchDelegate{
    var authenticationViewController: UIViewController?
    var lastError: NSError?
    var enableGameCenter = false
    weak var delegate: GameKitHelperDelegate?
    var match: GKMatch!
    var matchStarted = false
    static let sharedGameKitHelper = GameKitHelper()
    var playersDict = [AnyHashable: Any]()
    
    override init() {
        super.init()
        enableGameCenter = true
    }
    
    
    func findMatchWithMinPlayers(minPlayers: Int, maxPlayers: Int, viewController: UIViewController, delegate: GameKitHelperDelegate) {
        if !enableGameCenter {
            return
        }
        self.matchStarted = false
        self.match = nil
        self.delegate = delegate
        viewController.dismiss(animated: false, completion: { _ in })
        var request = GKMatchRequest()
        request.minPlayers = minPlayers
        request.maxPlayers = maxPlayers
        var mmvc = GKMatchmakerViewController(matchRequest: request)
        mmvc!.matchmakerDelegate = self
        viewController.present(mmvc!, animated: true, completion: { _ in })
        
    }
    
    
    // A peer-to-peer match has been found, the game should start
    
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match: GKMatch) {
        viewController.dismiss(animated: true, completion: { _ in })
        self.match = match
        match.delegate = self
        if !matchStarted && match.expectedPlayerCount == 0 {
            print("Ready to start match!")
            self.lookupPlayers()
        }
    }
    // The user has cancelled matchmaking
    
    func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
        viewController.dismiss(animated: true, completion: { _ in })
    }
    
    // Matchmaking has failed with an error
    
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: Error) {
        viewController.dismiss(animated: true, completion: { _ in })
        print("Error finding match: \(error.localizedDescription)")
    }
    
    // The match received data sent from the player.
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        if self.match != match {
            return
        }
        delegate?.match(match: match, data: data, playerID: player.playerID! )
    }
    
    // The player state changed (eg. connected or disconnected)
    
    // The match was unable to connect with the player due to an error.
    func match(_ match: GKMatch, didFailWithError error: Error?) {
        if self.match != match {
            return
        }
        print("Match failed with error: \(error?.localizedDescription)")
        matchStarted = false
        delegate?.matchEndedAbruptly()
    }
    
    // The match was unable to be established with any players due to an error.
    func match(_ match: GKMatch, connectionWithPlayerFailed playerID: String, withError error: NSError?) {
        if self.match != match {
            return
        }
        print("Failed to connect to player with error: \(error?.localizedDescription)")
        matchStarted = false
        delegate?.matchEndedAbruptly()
    }
    
    
    //Authentication -------------------------------------------------------------------------
    
    func authenticateLocalPlayer() {//Good
        //1
        let localPlayer = GKLocalPlayer.localPlayer()
        //1.5
        if localPlayer.isAuthenticated {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: LocalPlayerIsAuthenticated), object: nil)
            return
        }
        //2
        localPlayer.authenticateHandler = {viewController, error in
            //3
            try? self.setLastError(error: error as NSError?)
            if viewController != nil {
                //4
                self.setAuthenticationViewController(authenticationViewController: viewController!)
            }
            else if GKLocalPlayer.localPlayer().isAuthenticated {
                //5
                self.enableGameCenter = true
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: LocalPlayerIsAuthenticated), object: nil)
            }
            else {
                //6
                self.enableGameCenter = false
            }
            
        }
        //barronsbooks.com/ap/compsci
    }
    func lookupPlayers() {
        print("Looking up \(UInt(match.playerIDs.count)) players...")
        GKPlayer.loadPlayers(forIdentifiers: match.playerIDs, withCompletionHandler: {players, error in
            if error != nil {
                print("Error retrieving player info: \(error?.localizedDescription)")
                self.matchStarted = false
                self.delegate!.matchEndedAbruptly()
            }
            else {
                // Populate players dict
                self.playersDict = [AnyHashable: Any](minimumCapacity: players!.count)
                for player: GKPlayer in players! {
                    print("Found player: \(player.alias)")
                    self.playersDict[player.playerID!] = player
                }
                self.playersDict[GKLocalPlayer.localPlayer().playerID!] = GKLocalPlayer.localPlayer()
                // Notify delegate match can begin
                self.matchStarted = true
                self.delegate!.matchStarted()
            }
        })
    }
    func setAuthenticationViewController(authenticationViewController: UIViewController) { //Good
        if (authenticationViewController != nil) {
            self.authenticationViewController = authenticationViewController
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: PresentAuthenticationViewController), object: self)
        }
    }
    func setLastError(error: NSError?) { //Good
        self.lastError = error
        if lastError != nil {
            print("GameKitHelper ERROR: \(lastError!.debugDescription)")
        }
    }
}

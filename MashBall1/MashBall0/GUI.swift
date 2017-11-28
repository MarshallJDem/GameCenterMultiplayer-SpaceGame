//
//  GUI.swift
//  MashBall0
//
//  Created by Marshall Demirjian on 3/6/17.
//  Copyright © 2017 MarshallD. All rights reserved.
//

import Foundation
import SpriteKit


class ShootStick: SKSpriteNode {
    
    var stick = SKSpriteNode()
    var global: GameScene!
    let constantSize: CGFloat = 150
    
    init(global: GameScene) {
        
        //Init Self
        super.init(texture: SKTexture(imageNamed: "knob.png"), color: UIColor.gray, size: CGSize(width: constantSize, height: constantSize))
        self.colorBlendFactor = 10
        self.alpha = 0.25
        
        self.position = CGPoint(x: global.size.width/2 - 25 - self.size.width/2, y: -global.size.height/2 + 25 + self.size.height/2)
        
        stick = SKSpriteNode(texture: SKTexture(imageNamed: "knob.png"), size: CGSize(width: constantSize/3, height: constantSize/3))
        stick.alpha = 1
        self.addChild(stick)
        
        //others
        self.global = global
        
        isUserInteractionEnabled = true
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    func updateStick(pos: CGPoint, hasForce: Bool){
        var length = sqrt(pos.x * pos.x + pos.y * pos.y)
        if(!hasForce){length = 0}
        let angle = atan(pos.y/pos.x)
        if (length > self.size.width/2){length = self.size.width/2}
        stick.position = CGPoint(x: length*cos(angle), y: length*sin(angle))
        stick.zRotation = angle - .pi/2
        if(pos.x < 0){stick.position.x *= -1; stick.position.y *= -1; stick.zRotation -= .pi}
        global.players[global.currentPlayerIndex].changeTurret(angle: stick.zRotation, isOn: hasForce, send: true)
        
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        guard let touch = touches.first else {
            return;}
        let pos = touch.location(in: self)
        let touchedNode = self.atPoint(pos)
        updateStick(pos: pos, hasForce: true)
        
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return;
        }
        let touchLocation = touch.location(in: self)
        let touchedNode = self.atPoint(touchLocation)
        updateStick(pos: touchLocation, hasForce: true)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return;
        }
        let touchLocation = touch.location(in: self)
        let touchedNode = self.atPoint(touchLocation)
        updateStick(pos: touchLocation, hasForce: false)
    }
    
}
class MoveStick: SKSpriteNode {
    
    var stick = SKSpriteNode()
    var global: GameScene!
    
    init(global: GameScene) {
        
        //Init Self
        super.init(texture: SKTexture(imageNamed: "knob.png"), color: UIColor.gray, size: CGSize(width: 150, height: 150))
        self.colorBlendFactor = 10
        self.alpha = 0.25
        
        self.position = CGPoint(x: -global.size.width/2 + 25 + self.size.width/2, y: -global.size.height/2 + 25 + self.size.height/2)
        
        stick = SKSpriteNode(texture: SKTexture(imageNamed: "knob.png"), size: CGSize(width: 50, height: 50))
        stick.alpha = 1
        self.addChild(stick)
        
        //others
        self.global = global
        
        isUserInteractionEnabled = true
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    func updateStick(pos: CGPoint, hasForce: Bool){
        var length = sqrt(pos.x * pos.x + pos.y * pos.y)
        if(!hasForce){length = 0}
        let angle = atan(pos.y/pos.x)
        if (length > self.size.width/2){length = self.size.width/2}
        stick.position = CGPoint(x: length*cos(angle), y: length*sin(angle))
        stick.zRotation = angle - .pi/2
        if(pos.x < 0){stick.position.x *= -1; stick.position.y *= -1; stick.zRotation -= .pi}
        global.players[global.currentPlayerIndex].updatePlayer(angle: angle, length: length, maxLength: sqrt(pow(self.size.width/2,2) + pow(self.size.height/2,2)), posX: pos.x)
        
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        guard let touch = touches.first else {
            return;}
        let pos = touch.location(in: self)
        let touchedNode = self.atPoint(pos)
        updateStick(pos: pos, hasForce: true)
        global.players[global.currentPlayerIndex].changeRocket(isOn: true, send: true)
        
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return;
        }
        let touchLocation = touch.location(in: self)
        let touchedNode = self.atPoint(touchLocation)
        updateStick(pos: touchLocation, hasForce: true)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return;
        }
        let touchLocation = touch.location(in: self)
        let touchedNode = self.atPoint(touchLocation)
        updateStick(pos: touchLocation, hasForce: false)
        global.players[global.currentPlayerIndex].changeRocket(isOn: false, send: true)
    }
    
}

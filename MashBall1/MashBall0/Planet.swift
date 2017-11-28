//
//  Planet.swift
//  MashBall0
//
//  Created by Marshall Demirjian on 5/16/17.
//  Copyright © 2017 MarshallD. All rights reserved.
//

import SpriteKit
import Foundation


class Planet: SKSpriteNode {
    
    var global: GameScene!
    var type: Int!
    var body = SKSpriteNode()
    
    init(position: CGPoint, type: Int, global: GameScene){
        super.init(texture: SKTexture(imageNamed: "knob"), color: UIColor.clear, size: CGSize(width: 1, height: 1))
        self.colorBlendFactor = 1
        
        self.global = global
        self.type = type
        
        body = SKSpriteNode(texture: SKTexture(imageNamed: "redP"), color: UIColor.clear, size: CGSize(width: 250, height: 250))
        body.position = position
        body.physicsBody = SKPhysicsBody(circleOfRadius: body.size.width/2)
        body.physicsBody!.isDynamic = false
        body.physicsBody!.categoryBitMask = obstacleCat
        self.addChild(body)
        
        if(type == 1){
            body.texture = SKTexture(imageNamed: "blueP")
        }
        else if(type == 2){
            body.texture = SKTexture(imageNamed: "orangeP")
        }
        
        body.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi/4, duration: 10)))
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}

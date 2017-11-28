//
//  Player.swift
//  MashBall0
//
//  Crimport UIKit
import SpriteKit
import Foundation


class Player: SKSpriteNode {
    
    var global: GameScene!
    var power: CGFloat = 6000
    var currentForce: CGVector = CGVector(dx: 0, dy: 0)
    var rocket: SKEmitterNode!
    var maxSpeed: CGFloat = 500
    var turret: SKSpriteNode!
    var shotType: Int = 1
    var health: Int = 1000
    var index: Int = -1
    var healthBar: SKLabelNode!
    
    init(index: Int, pos: CGPoint, angle: CGFloat, global: GameScene) {
        
        //Init Self
        super.init(texture: SKTexture(imageNamed: "Spaceship"), color: UIColor.clear, size: CGSize(width: 50, height: 50))
        self.position = pos
        self.zPosition = 15
        self.zRotation = angle
        self.index = index
        
        //Init Body
        self.physicsBody = SKPhysicsBody(rectangleOf: self.size)
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.usesPreciseCollisionDetection = true
        self.physicsBody?.categoryBitMask = playerCat
        self.physicsBody?.contactTestBitMask = shotCat
        self.physicsBody?.collisionBitMask = obstacleCat
        self.physicsBody?.angularDamping = 100
        self.physicsBody?.linearDamping = 0
        
        self.global = global
        isUserInteractionEnabled = false
        
        //The rocket emitter in back for animation purposes
        rocket = SKEmitterNode(fileNamed: "Rocket.sks")
        rocket.position = CGPoint(x: 0, y: -20)
        rocket.zRotation = .pi
        rocket.setScale(0.5)
        addChild(rocket)
        changeRocket(isOn: false, send: false)
        
        //Turret
        turret = SKSpriteNode(imageNamed: "knob")
        turret.size = CGSize(width: 25, height: 25)
        turret.zPosition = 10
        self.addChild(turret)
        
        healthBar = SKLabelNode(text: "1000")
        healthBar.position = CGPoint(x: 0, y: -50)
        healthBar.fontSize = 10
        self.addChild(healthBar)
        
        
        
        
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    func changeTurret(angle: CGFloat, isOn: Bool, send: Bool){
        if(send){global.networkingEngine?.sendTurret(angle: angle, isOn: isOn)}
        turret.zRotation = angle
                                                        
        if(isOn && send){
            if(!self.hasActions()){
                self.run(SKAction.repeatForever(SKAction.sequence([SKAction.run {
                    self.shoot(position: self.position, angle: self.turret.zRotation, type: self.shotType, send: true)
                    }, SKAction.wait(forDuration: 0.2)])))
            }
        } else{
            self.removeAllActions()
        }
    }
    func shoot(position: CGPoint, angle: CGFloat, type: Int, send: Bool){
        if(send){global.networkingEngine?.sendShoot(position: position, angle: angle, type: 1)}
        var shot = Shot(position: position, angle: angle, type: type, player: self, global: global, isLocal: send)
        global.addChild(shot)
    }
    func changeRocket(isOn: Bool, send: Bool){
        if(send){global.networkingEngine?.sendRocket(isOn: isOn)}
        if(isOn){
            rocket.numParticlesToEmit = -1
        } else{
            rocket.numParticlesToEmit = 1
        }
    }
    func updatePlayer(angle: CGFloat, length: CGFloat, maxLength: CGFloat, posX: CGFloat){
        zRotation = angle - .pi/2
        var force = CGVector(dx: length*cos(angle)*power/maxLength, dy: length*sin(angle)*power/maxLength)
        if(posX < 0){
            force.dx *= -1
            force.dy *= -1
            zRotation -= .pi
        }
        currentForce = force
    }
    func recievedMove(position: CGPoint, velocity: CGVector, force: CGVector, angle: CGFloat){
        
        //Calculate a time interval for updating. The greater the speed, the lower the interval so theres no animation lag
        let speed = sqrt(pow(velocity.dx, 2) + pow(velocity.dy, 2))
        var moveTimeInterval = 10/speed
        if (speed <= 0){ //Lower Bound
            moveTimeInterval = 0.2
        }
        moveTimeInterval *= 0.05
        if(moveTimeInterval > 0.05){ //Upper Bound
            moveTimeInterval = 0.5
        }
        self.run(SKAction.move(to: position, duration: TimeInterval(moveTimeInterval)))
        self.physicsBody?.velocity = velocity
        self.currentForce = force
        run(SKAction.rotate(toAngle: angle, duration: 0.05, shortestUnitArc: true))
        
    }
    func changeHealth(amount: Int, send: Bool){
        if(send){global.networkingEngine!.sendHealth(amount: amount)}
        health += amount
        healthBar.text = "\(self.health)"
    }
    func applyThrust(deltaTime: TimeInterval){
        self.physicsBody?.applyForce(CGVector(dx: currentForce.dx * CGFloat(deltaTime), dy: currentForce.dy * CGFloat(deltaTime)))
        let vel: CGVector! = self.physicsBody?.velocity
        let speed = sqrt(pow(vel.dx, 2) + pow(vel.dy, 2))
        if(speed > maxSpeed){
            let factor = maxSpeed/speed
            self.physicsBody?.velocity.dx *= factor
            self.physicsBody?.velocity.dy *= factor
        }
    }
}

class Shot: SKSpriteNode {
    
    var player: Player!
    var isLocal: Bool!
    var global: GameScene!
    
    init(position: CGPoint, angle: CGFloat, type: Int, player: Player, global: GameScene,isLocal: Bool){
        super.init(texture: SKTexture(imageNamed: "shot"), color: UIColor.clear, size: CGSize(width: 20, height: 40))
        self.position = position
        self.zRotation = angle
        let angle = angle + .pi/2
        self.physicsBody = SKPhysicsBody(rectangleOf: self.size)
        self.physicsBody!.velocity = CGVector(dx: 1000*cos(angle), dy: 1000*sin(angle))
        self.physicsBody!.linearDamping = 0
        self.physicsBody!.angularDamping = 0
        self.physicsBody!.affectedByGravity = false
        self.physicsBody!.categoryBitMask = shotCat
        self.physicsBody!.collisionBitMask = 0
        self.physicsBody!.contactTestBitMask = playerCat | obstacleCat
        self.physicsBody!.isDynamic = true
        self.run(SKAction.sequence([SKAction.wait(forDuration: 10), SKAction.run {
            self.die()
            }]))
        
        self.player = player
        self.isLocal = isLocal
        
        self.global = global
        
        
        
        
        //Do something with type
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    func die(){
        
        let explosion = SKEmitterNode(fileNamed: "Explosion.sks")
        explosion!.position = self.position
        explosion!.setScale(0.5)
        global.addChild(explosion!)
        self.removeFromParent()
    }
    
}
//littlekitten3126@yahoo.com

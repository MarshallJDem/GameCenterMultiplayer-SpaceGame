import SpriteKit
import Darwin


var allCategory: UInt32 = 0xFFFFFFFF
var playerCat: UInt32 = 1 << 1 //2
var obstacleCat: UInt32 = 1 << 2 //4?
var shotCat: UInt32 = 1 << 3 //8

class GameScene: SKScene, SKPhysicsContactDelegate, MultiplayerNetworkingProtocol{
    
    var viewController: GameViewController!
    
    var lastTime = NSDate()
    
    var networkingEngine: MultiplayerNetworking?
    
    var players = Array<Player>()
    var currentPlayerIndex: Int = -1
    var scores = Array<Int>()
    
    var healthBar: SKLabelNode = SKLabelNode(text: "Health: ")
    
    override func didMove(to view: SKView) {
        self.removeAllChildren()
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.speed = 1.0
        backgroundColor = SKColor.white
        //self.physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect( x: 0, y: 0, width: self.size.width, height: self.size.height))
        physicsWorld.contactDelegate = self
        isUserInteractionEnabled = true
        
        var newPlayer = Player(index: 0, pos: CGPoint(x: -100, y: -100), angle: 0, global: self)
        addChild(newPlayer)
        players.append(newPlayer)
        
        newPlayer = Player(index: 1, pos: CGPoint(x: 100, y: 100), angle: 0, global: self)
        addChild(newPlayer)
        players.append(newPlayer)
        
        //Camera & GUI
        var cam = SKCameraNode()
        self.camera = cam
        cam.position = CGPoint(x: 100, y: 0)
        cam.setScale(2)
        cam.zPosition = 10000
        addChild(cam)
        cam.addChild(MoveStick(global: self))
        cam.addChild(ShootStick(global: self))
        cam.addChild(healthBar)
        healthBar.position = CGPoint(x: 0, y: self.size.height/2 - 50)
        healthBar.fontSize = 30
        
        
        var max = 10
        for y in 0...(max-1) {
            for x in 0...(max-1) {
                var background = SKSpriteNode(texture: SKTexture(imageNamed: "space"), size: CGSize(width: 1920, height: 1080))
                background.position = CGPoint(x: CGFloat(x) * background.size.width - (background.size.width * CGFloat(max)/2), y: CGFloat(y) * background.size.height - (background.size.height * CGFloat(max)/2))
                background.zPosition = -1
                self.addChild(background)
            }
        }
        
        var planet = Planet(position: CGPoint.zero, type: 0, global: self)
        self.addChild(planet)
        var planet2 = Planet(position: CGPoint(x: 600, y:250), type: 1, global: self)
        self.addChild(planet2)
        var planet3 = Planet(position: CGPoint(x: -350, y:150), type: 2, global: self)
        self.addChild(planet3)
        var planet4 = Planet(position: CGPoint(x: -450, y:-500), type: 1, global: self)
        self.addChild(planet4)
        var planet5 = Planet(position: CGPoint(x: 500, y:-650), type: 0, global: self)
        self.addChild(planet5)
        
    }
    
    func matchEnded(scores: Array<Int>) {
        if (scores[currentPlayerIndex] == 1){
            self.backgroundColor = SKColor.green
        }
        else{
            self.backgroundColor = SKColor.red
            
        }
    }
    func setCurrentPlayerIndex(index: Int) {
        currentPlayerIndex = index
        
    }
    func movePlayer(index: Int, position: CGPoint, velocity: CGVector, force: CGVector, angle: CGFloat){
        players[index].recievedMove(position: position, velocity: velocity, force: force, angle: angle)
    }
    func changeRocket(index: Int, isOn: Bool){
        if(currentPlayerIndex != -1){
            players[index].changeRocket(isOn: isOn, send: false)}
    }
    
    func changeTurret(index: Int, angle: CGFloat, isOn: Bool){
        if(currentPlayerIndex != -1){
            players[index].changeTurret(angle: angle, isOn: isOn, send: false)
        }
    }
    func shoot(index: Int, position: CGPoint, angle: CGFloat, type: Int){
        if(currentPlayerIndex != -1){
            players[index].shoot(position: position, angle: angle, type: type, send: false)
        }
    }
    func changeHealth(index: Int, amount: Int){
        players[index].changeHealth(amount: amount, send: (index == currentPlayerIndex))
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        var deltaTime = lastTime.timeIntervalSinceNow
        deltaTime = abs(deltaTime)
        for player in players{
            player.applyThrust(deltaTime: deltaTime)
        }
        lastTime = NSDate()
        if(currentPlayerIndex != -1){
            self.camera?.position = players[currentPlayerIndex].position
            networkingEngine?.sendMove(player: players[currentPlayerIndex])
            healthBar.text = "Health: \(players[currentPlayerIndex].health)"
            if (players[currentPlayerIndex].health <= 0){
                healthBar.text = "You lose!"
            }
        }
        
    }
    func didBegin(_ contact: SKPhysicsContact) {
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        switch(contactMask) {
        case 0 | 0:
            return
        case shotCat | playerCat:
            var player: Player!, shot: Shot!
            
            if(contact.bodyA.categoryBitMask == playerCat){
                player = contact.bodyA.node as! Player
                shot = contact.bodyB.node as! Shot
            } else{
                player = contact.bodyB.node as! Player
                shot = contact.bodyA.node as! Shot
            }
            if(player.index != shot.player.index && !shot.isLocal){
                changeHealth(index: player.index, amount: -10)
                shot.die();
            }
            else if(player.index != shot.player.index){
                shot.die();}
            return
        case shotCat | obstacleCat:
            var shot: Shot!
            
            if(contact.bodyA.categoryBitMask == obstacleCat){
                shot = contact.bodyB.node as! Shot
            } else{
                shot = contact.bodyA.node as! Shot
            }
            shot.die()
            return
        default:
            return
        }
    }
    func didEnd(_ contact: SKPhysicsContact) {
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        switch(contactMask) {
        case 0 | 0:
            return
        default:
            return
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        guard let touch = touches.first else {
            return;}
        let positionInScene = touch.location(in: self)
        let touchedNode = self.atPoint(positionInScene)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return;
        }
        let touchLocation = touch.location(in: self)
        let touchedNode = self.atPoint(touchLocation)
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return;
        }
        let touchLocation = touch.location(in: self)
        let touchedNode = self.atPoint(touchLocation)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return;}
        let positionInScene = touch.location(in: self)
        let touchedNode = self.atPoint(positionInScene)
    }
}

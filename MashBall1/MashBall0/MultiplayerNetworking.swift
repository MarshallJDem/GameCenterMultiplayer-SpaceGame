import UIKit
import SpriteKit
import GameKit



protocol MultiplayerNetworkingProtocol: class {
    func matchEnded(scores: Array<Int>)
    func setCurrentPlayerIndex(index: Int)
    func movePlayer(index: Int, position: CGPoint, velocity: CGVector, force: CGVector, angle: CGFloat)
    func changeRocket(index: Int, isOn: Bool)
    func changeTurret(index: Int, angle: CGFloat, isOn: Bool)
    func shoot(index: Int, position: CGPoint, angle: CGFloat, type: Int)
    func changeHealth(index: Int, amount: Int)

}
enum GameState : Int {
    case kGameStateWaitingForMatch = 0
    case kGameStateWaitingForRandomNumber = 1
    case kGameStateWaitingForStart = 2
    case kGameStateActive = 3
    case kGameStateDone = 4
}
enum MessageType : Int {
    case kMessageTypeRandomNumber = 0
    case kMessageTypeGameBegin = 1
    case kMessageTypeMove = 2
    case kMessageTypeGameOver = 3
    case kMessageTypeRocket = 4
    case kMessageTypeTurret = 5
    case kMessageTypeShoot = 6
    case kMessageTypeHealth = 7
}
protocol MessageProtocol {
    var message: Message { get set }
}
struct Message {
    var messageType: MessageType;
}

struct MessageRandomNumber: MessageProtocol {
    var message: Message;
    var randomNumber: UInt32
}

struct MessageGameBegin: MessageProtocol{
    var message: Message
}

struct MessageMove: MessageProtocol{
    var message: Message
    var position: CGPoint
    var velocity: CGVector
    var force: CGVector
    var angle: CGFloat
}
struct MessageRocket: MessageProtocol{
    var message: Message
    var isOn: Bool
}
struct MessageGameOver: MessageProtocol{
    var message: Message
    var scores = Array(repeating: 0, count: 2)
    
}
struct MessageTurret: MessageProtocol{
    var message: Message
    var angle: CGFloat
    var isOn: Bool
}
struct MessageShoot: MessageProtocol{
    var message: Message
    var position: CGPoint
    var angle: CGFloat
    var type: Int
}
struct MessageHealth: MessageProtocol{
    var message: Message
    var amount: Int
}

class MultiplayerNetworking: NSObject, GameKitHelperDelegate {
    var delegate: MultiplayerNetworkingProtocol?
    var ourRandomNumber: UInt32 = 0
    var gameState: GameState!
    var isPlayer1: Bool = false
    var receivedAllRandomNumbers: Bool = false
    var orderOfPlayers = Array<NSDictionary>()
    let playerIdKey = "PlayerId"
    let randomNumberKey = "randomNumber"
    var viewController: GameViewController!
    
    override init() {
        super.init()
        
        ourRandomNumber = arc4random()
        gameState = .kGameStateWaitingForMatch
        orderOfPlayers = Array<NSDictionary>()
        
        orderOfPlayers.append([playerIdKey: GKLocalPlayer.localPlayer().playerID!, randomNumberKey: (ourRandomNumber)])
        
    }

    func send(data: Data) {
        var error: NSError?
        let gameKitHelper = GameKitHelper.sharedGameKitHelper
        let success = try? gameKitHelper.match.sendData(toAllPlayers: data, with: .reliable)
        //^ issue
        if success == nil {
            print("Error sending data:\(error?.localizedDescription)")
            matchEndedAbruptly()
        }
        
    }
    
    func matchStarted() {
        print("Match has started successfully")
        viewController.loadGameScene()
        if receivedAllRandomNumbers {
            gameState = .kGameStateWaitingForStart
        }
        else {
            gameState = .kGameStateWaitingForRandomNumber
        }
        sendRandomNumber()
        tryStartGame()
    }
    
    func matchEndedAbruptly() {
        
    }
    
    func match(match: GKMatch, data: Data, playerID: String) {
        //1
        
        let message: Message? = data.withUnsafeBytes { $0.pointee }
        if message?.messageType == .kMessageTypeRandomNumber {
            let messageRandomNumber: MessageRandomNumber? = data.withUnsafeBytes { $0.pointee }
            print("Our random number: \(String(ourRandomNumber))")
            print("Received random number:\(String(describing: messageRandomNumber?.randomNumber))")
            var tie: Bool = false
            if messageRandomNumber?.randomNumber == ourRandomNumber {
                //2
                print("Tie")
                tie = true
                ourRandomNumber = arc4random()
                sendRandomNumber()
            }
            else {
                //3
                let dictionary: [AnyHashable: Any]? = [playerIdKey: playerID, randomNumberKey: (messageRandomNumber?.randomNumber)!]
                processReceivedRandomNumber(randomNumberDetails: dictionary! as NSDictionary)
            }
            if receivedAllRandomNumbers {
                isPlayer1 = isLocalPlayerPlayer1()
            }
            if !tie && receivedAllRandomNumbers {
                //5
                if gameState == .kGameStateWaitingForRandomNumber {
                    gameState = .kGameStateWaitingForStart
                }
                tryStartGame()
            }
        }
        else if message?.messageType == .kMessageTypeGameBegin {
            print("Begin game message received")
            gameState = .kGameStateActive
            delegate?.setCurrentPlayerIndex(index: indexForLocalPlayer())
            
        }
        else if message?.messageType == .kMessageTypeMove {
            //print("Move message received")
            let messageMove: MessageMove! = data.withUnsafeBytes { $0.pointee }
            delegate?.movePlayer(index: indexForPlayer(playerID: playerID), position: messageMove!.position, velocity: messageMove!.velocity, force: messageMove!.force, angle: messageMove!.angle)
            //delegate?.movePlayer(index: indexForPlayer(playerID: playerID), position: messageMove!.position, velocity: CGVector.zero, force: CGVector.zero)
           // print("Getting" + String(describing: messageMove!.position))
        }
        else if message?.messageType == .kMessageTypeGameOver {
            print("Game over message received")
            let messageOver: MessageGameOver? = data.withUnsafeBytes { $0.pointee }
            delegate?.matchEnded(scores: (messageOver?.scores)!)
        }
        else if message?.messageType == .kMessageTypeRocket {
            //print("Rocket message received")
            let messageRocket: MessageRocket? = data.withUnsafeBytes { $0.pointee }
            delegate?.changeRocket(index: indexForPlayer(playerID: playerID), isOn: messageRocket!.isOn)
        }
        else if message?.messageType == .kMessageTypeTurret {
            //print("Turret message received")
            let messageTurret: MessageTurret? = data.withUnsafeBytes { $0.pointee }
            delegate?.changeTurret(index: indexForPlayer(playerID: playerID), angle: messageTurret!.angle, isOn: messageTurret!.isOn)
        }
        else if message?.messageType == .kMessageTypeShoot {
            //print("Shoot message received")
            let messageShoot: MessageShoot? = data.withUnsafeBytes { $0.pointee }
            delegate?.shoot(index: indexForPlayer(playerID: playerID), position: messageShoot!.position, angle: messageShoot!.angle, type: messageShoot!.type)
        }
        else if message?.messageType == .kMessageTypeHealth {
            print("Health message received")
            let messageHealth: MessageHealth? = data.withUnsafeBytes { $0.pointee }
            delegate?.changeHealth(index: indexForPlayer(playerID: playerID), amount: messageHealth!.amount)
        }
        
    }
    
    //Send messages
    
    func sendGameBegin() {
        var message: MessageGameBegin = MessageGameBegin(message: Message(messageType: .kMessageTypeGameBegin))
        let data = Data(bytes: &message, count: MemoryLayout<MessageGameBegin>.size)
        send(data: data)
    }
    func sendGameEnd(scores: Array<Int>) {
        var message: MessageGameOver = MessageGameOver(message: Message(messageType: .kMessageTypeGameOver), scores: scores)
        let data = Data(bytes: &message, count: MemoryLayout<MessageGameOver>.size)
        send(data: data)
    }
    func sendRandomNumber() {
        var message: MessageRandomNumber = MessageRandomNumber(message: Message(messageType: .kMessageTypeRandomNumber), randomNumber: ourRandomNumber)
        let data = Data(bytes: &message, count: MemoryLayout<MessageRandomNumber>.size)
        send(data: data)
    }
    func sendMove(player: Player) {
        var message: MessageMove = MessageMove(message: Message(messageType: .kMessageTypeMove), position: player.position, velocity: (player.physicsBody?.velocity)!, force: player.currentForce, angle: player.zRotation)
       // var message: MessageMove = MessageMove(message: Message(messageType: .kMessageTypeMove), position: player.position)
        let data = Data(bytes: &message, count: MemoryLayout<MessageMove>.size)
        send(data: data)
    }
    func sendRocket(isOn: Bool) {
        var message: MessageRocket = MessageRocket(message: Message(messageType: .kMessageTypeRocket), isOn: isOn)
        let data = Data(bytes: &message, count: MemoryLayout<MessageRocket>.size)
        send(data: data)
    }
    func sendTurret(angle: CGFloat, isOn: Bool) {
        var message: MessageTurret = MessageTurret(message: Message(messageType: .kMessageTypeTurret), angle: angle, isOn: isOn)
        let data = Data(bytes: &message, count: MemoryLayout<MessageTurret>.size)
        send(data: data)
    }
    func sendShoot(position: CGPoint, angle: CGFloat, type: Int) {
        var message: MessageShoot = MessageShoot(message: Message(messageType: .kMessageTypeShoot), position: position, angle: angle, type: type)
        let data = Data(bytes: &message, count: MemoryLayout<MessageShoot>.size)
        send(data: data)
    }
    func sendHealth(amount: Int) {
        var message: MessageHealth = MessageHealth(message: Message(messageType: .kMessageTypeHealth), amount: amount)
        let data = Data(bytes: &message, count: MemoryLayout<MessageHealth>.size)
        send(data: data)
    }
    
    //Other stuff used by other stuff that u kinda dont have to worry about anymore
    
    func tryStartGame() {
        if isPlayer1 && gameState == .kGameStateWaitingForStart {
            gameState = .kGameStateActive
            sendGameBegin()
        }
    }
    func processReceivedRandomNumber(randomNumberDetails: NSDictionary) {
        if orderOfPlayers.contains(randomNumberDetails) {
            orderOfPlayers.remove(at: (orderOfPlayers as Array).index(of: randomNumberDetails)!)
        }
        //2
        orderOfPlayers.append(randomNumberDetails)
        //3
        var sortByRandomNumber = NSSortDescriptor(key: randomNumberKey, ascending: false)
        var sortDescriptors: [NSSortDescriptor] = [sortByRandomNumber]
        NSMutableArray(array: orderOfPlayers).sort(using: sortDescriptors)
        orderOfPlayers = (orderOfPlayers as NSArray).sortedArray(using: sortDescriptors) as! Array<NSDictionary>
        //4
        if allRandomNumbersAreReceived() {
            receivedAllRandomNumbers = true
        }
    }
    
    func allRandomNumbersAreReceived() -> Bool {
        var receivedRandomNumbers = [UInt32]()
        for dict in orderOfPlayers {
            receivedRandomNumbers.append(dict[randomNumberKey]! as! UInt32)
            var bob = dict[randomNumberKey]!
        }
        let arrayOfUniqueRandomNumbers = Array(Set<UInt32>(receivedRandomNumbers))
        if arrayOfUniqueRandomNumbers.count == GameKitHelper.sharedGameKitHelper.match.players.count + 1 {
            return true
        }
        return false
    }
    
    func isLocalPlayerPlayer1() -> Bool {
        var dictionary = orderOfPlayers[0]
        if (dictionary[playerIdKey] as! String == GKLocalPlayer.localPlayer().playerID) {
            print("I'm player 1")
            delegate?.setCurrentPlayerIndex(index: 0)
            return true
            
        }
        print("I'm not player 1")
        return false
    }
    func indexForLocalPlayer() -> Int {
        let playerId: String = GKLocalPlayer.localPlayer().playerID!
        return indexForPlayer(playerID: playerId)
    }
    
    func indexForPlayer(playerID: String) -> Int {
        var index: Int = -1
        var counter = 0
        for dict in orderOfPlayers{
            if (dict[playerIdKey] as! String == playerID) {
                index = counter
            }
            counter += 1
        }
        return index
    }
}

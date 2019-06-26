//
//  GameScene.swift
//  CoinRunGame
//
//  Created by Connor Miller on 1/7/19.
//  Copyright © 2019 Connor Miller. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var score = 0
    var highScore = 0
    
    var coinMan : SKSpriteNode?
    var ceiling : SKSpriteNode?
    
    var coinTimer : Timer?
    var bombTimer : Timer?
    
    var scoreLabel : SKLabelNode?
    var highScoreLabel: SKLabelNode?
    var yourScoreLabel : SKLabelNode?
    var finalScoreLabel : SKLabelNode?
    
    let coinManCategory : UInt32 = 0x1 << 1
    let coinCategory : UInt32 = 0x1 << 2
    let bombCategory : UInt32 = 0x1 << 3
    let groundAndCeilingCategory : UInt32 = 0x1 << 4
    
    override func sceneDidLoad() {
        
        highScoreLabel = childNode(withName: "highScoreLabel") as? SKLabelNode
        
        if let userHighScore = UserDefaults.standard.object(forKey: "highScore") as? Int {
            
            highScoreLabel?.text = "High: \(userHighScore)"
            highScore = userHighScore
            
        }
        
    }
    
    override func didMove(to view: SKView) {
        
        physicsWorld.contactDelegate = self
        
        coinMan = childNode(withName: "coinMan") as? SKSpriteNode
        coinMan?.physicsBody?.categoryBitMask = coinManCategory
        coinMan?.physicsBody?.contactTestBitMask = coinCategory | bombCategory
        coinMan?.physicsBody?.collisionBitMask = groundAndCeilingCategory
        
        var coinManRun : [SKTexture] = []
        
        for number in 1...5 {
            
            coinManRun.append(SKTexture(imageNamed: "frame-\(number)"))
            
        }
        
        coinMan?.run(SKAction.repeatForever(SKAction.animate(with: coinManRun, timePerFrame: 0.1)))
        
        ceiling = childNode(withName: "ceiling") as? SKSpriteNode
        ceiling?.physicsBody?.categoryBitMask = groundAndCeilingCategory
        ceiling?.physicsBody?.collisionBitMask = coinManCategory
        
        scoreLabel = childNode(withName: "scoreLabel") as? SKLabelNode
        
        startTimers()
        createGrass()
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if scene?.isPaused == false {
            
            coinMan?.physicsBody?.applyForce(CGVector(dx: 0, dy: 100000))
            
        }
        
        let touch = touches.first
        
        if let location = touch?.location(in: self) {
            
            let theNodes = nodes(at: location)
            
            for node in theNodes {
                
                if node.name == "playBtn" {
                    
                    // Restart the game
                    scene?.isPaused = false
                    
                    score = 0
                    scoreLabel?.text = "Score: \(score)"
                    
                    node.removeFromParent()
                    
                    finalScoreLabel?.removeFromParent()
                    yourScoreLabel?.removeFromParent()
                    
                    self.startTimers()
                    
                }
                
            }
            
        }
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        if contact.bodyA.categoryBitMask == coinCategory {
            
            self.score += 1
            scoreLabel?.text = "Score: \(self.score)"
            contact.bodyA.node?.removeFromParent()
            
        }
        
        if contact.bodyB.categoryBitMask == coinCategory {
            
            self.score += 1
            scoreLabel?.text = "Score: \(self.score)"
            contact.bodyB.node?.removeFromParent()
            
        }
        
        if contact.bodyA.categoryBitMask == bombCategory {
            
            contact.bodyA.node?.removeFromParent()
            self.gameOver()
            
        }
        
        if contact.bodyB.categoryBitMask == bombCategory {
            
            contact.bodyB.node?.removeFromParent()
            self.gameOver()
            
        }
        
    }
    
    func createGrass() {
    
        let sizingGrass = SKSpriteNode(imageNamed: "grass")
        let numOfGrass = Int(size.width / sizingGrass.size.width) + 1
        
        for num in 0...numOfGrass {
            
            let grass = SKSpriteNode(imageNamed: "grass")
            grass.physicsBody = SKPhysicsBody(rectangleOf: grass.size)
            grass.physicsBody?.categoryBitMask = groundAndCeilingCategory
            grass.physicsBody?.collisionBitMask = coinManCategory
            grass.physicsBody?.affectedByGravity = false
            grass.physicsBody?.isDynamic = false
            addChild(grass)
            
            let grassX = -size.width / 2 + grass.size.width / 2 + grass.size.width * CGFloat(num)
            grass.position = CGPoint(x: grassX, y: -size.height / 2 + grass.size.height / 2)
            let speed = 100.0
            let firstMoveLeft = SKAction.moveBy(x: -grass.size.width - grass.size.width * CGFloat(num), y: 0, duration: TimeInterval(grass.size.width + grass.size.width * CGFloat(num)) / speed)
            let resetGrass = SKAction.moveBy(x: size.width + grass.size.width, y: 0, duration: 0)
            let grassFullMove = SKAction.moveBy(x: -size.width - grass.size.width, y: 0, duration: TimeInterval(size.width + grass.size.width) / speed)
            let grassInfiniteLoop = SKAction.repeatForever(SKAction.sequence([grassFullMove, resetGrass]))
            
            grass.run(SKAction.sequence([firstMoveLeft, resetGrass, grassInfiniteLoop]))
        }
    
    }
    
    func startTimers() {
        
        coinTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
            
            self.createCoin()
            
        })
        
        bombTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true, block: { (timer) in
            
            self.createBomb()
            
        })
        
    }
    
    func createBomb() {
     
        let bomb = SKSpriteNode(imageNamed: "bomb")
        bomb.physicsBody = SKPhysicsBody(rectangleOf: bomb.size)
        bomb.physicsBody?.affectedByGravity = false
        bomb.physicsBody?.categoryBitMask = bombCategory
        bomb.physicsBody?.contactTestBitMask = coinManCategory
        bomb.physicsBody?.collisionBitMask = 0
        bomb.zPosition = 1
        
        let maxY = self.size.height / 2 - bomb.size.height
        let minY = -self.size.height / 2 + bomb.size.height
        let range = maxY - minY
        let bombY = maxY - CGFloat(arc4random_uniform(UInt32(range)))
        
        addChild(bomb)
        
        bomb.position = CGPoint(x: self.size.width / 2 + bomb.size.width / 2, y: bombY)
        
        let moveLeft = SKAction.moveBy(x: -self.size.width - bomb.size.width, y: 0, duration: 4)
        
        bomb.run(SKAction.sequence([moveLeft, SKAction.removeFromParent()]))
        
    }
    
    func createCoin() {
        
        let coin = SKSpriteNode(imageNamed: "coin")
        coin.physicsBody = SKPhysicsBody(rectangleOf: coin.size)
        coin.physicsBody?.affectedByGravity = false
        coin.physicsBody?.categoryBitMask = coinCategory
        coin.physicsBody?.contactTestBitMask = coinManCategory
        coin.physicsBody?.collisionBitMask = 0
        
        let maxY = self.size.height / 2 - coin.size.height
        let minY = -self.size.height / 2 + coin.size.height
        let range = maxY - minY
        let coinY = maxY - CGFloat(arc4random_uniform(UInt32(range)))
        
        addChild(coin)
        
        coin.position = CGPoint(x: self.size.width / 2 + coin.size.width / 2, y: coinY)
        
        let moveLeft = SKAction.moveBy(x: -self.size.width - coin.size.width, y: 0, duration: 4)
        
        coin.run(SKAction.sequence([moveLeft, SKAction.removeFromParent()]))
        
    }
    
    func gameOver() {
        
        scene?.isPaused = true
        
        coinTimer?.invalidate()
        bombTimer?.invalidate()
        
        yourScoreLabel = SKLabelNode(text: "Your Score:")
        yourScoreLabel?.position = CGPoint(x: 0, y: 150)
        yourScoreLabel?.fontSize = 100
        yourScoreLabel?.zPosition = 1

        if yourScoreLabel != nil {
            
            addChild(yourScoreLabel!)
            
        }
        
        if score > highScore {
            
            highScore = score
            UserDefaults.standard.set(highScore, forKey: "highScore")
            highScoreLabel?.text = "High: \(highScore)"
            
        }
        
        finalScoreLabel = SKLabelNode(text: "\(score)")
        finalScoreLabel?.position = CGPoint(x: 0, y: 0)
        finalScoreLabel?.fontSize = 150
        finalScoreLabel?.zPosition = 1
        
        if finalScoreLabel != nil {
            
            addChild(finalScoreLabel!)
            
        }
        
        let playBtn = SKSpriteNode(imageNamed: "play")
        playBtn.position = CGPoint(x: 0, y: -200)
        playBtn.name = "playBtn"
        playBtn.zPosition = 1
        addChild(playBtn)
        
    }
    
}

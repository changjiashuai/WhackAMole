//
//  MyScene.h
//  WhackAMole
//

//  Copyright (c) 2014年 常家帅. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import <AVFoundation/AVFoundation.h>

@interface MyScene : SKScene

@property (strong, nonatomic) NSMutableArray *moles;
@property (strong, nonatomic) SKTexture *moleTexture;
@property (strong, nonatomic) SKAction *laughAnimation;
@property (strong, nonatomic) SKAction *hitAnimation;
@property (strong, nonatomic) SKLabelNode *scoreLabel;
@property (nonatomic) NSInteger score;
@property (nonatomic) NSInteger totalSpawns;
@property (nonatomic) BOOL gameOver;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (strong, nonatomic) SKAction *laughSound;
@property (strong, nonatomic) SKAction *owSound;

@end

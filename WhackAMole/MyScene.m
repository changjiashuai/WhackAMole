//
//  MyScene.m
//  WhackAMole
//
//  Created by CJS on 14-5-7.
//  Copyright (c) 2014年 常家帅. All rights reserved.
//

#import "MyScene.h"

#define IS_WIDESCREEN ( fabs( ( double )[ [ UIScreen mainScreen ] bounds].size.height - ( double )568 ) < DBL_EPSILON )

const float kMoleHoleOffset = 155.0;

@implementation MyScene

-(SKTextureAtlas *)textureAtlasNamed:(NSString *)fileName
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (IS_WIDESCREEN) {
            // iPhone Retina 4-inch
            fileName = [NSString stringWithFormat:@"%@-568", fileName];
        }else{
            // iPhone Retina 3.5-inch
            fileName = fileName;
        }
    }else{
        fileName = [NSString stringWithFormat:@"%@-ipad",fileName];
    }
    SKTextureAtlas *textureAtlas = [SKTextureAtlas atlasNamed:fileName];
    return textureAtlas;
}

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        // Add background
        SKTextureAtlas *backgroundAtlas = [self textureAtlasNamed:@"background"];
        SKSpriteNode *dirt = [SKSpriteNode spriteNodeWithTexture:[backgroundAtlas textureNamed:@"bg_dirt"]];
        dirt.scale = 20;
        dirt.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
        dirt.zPosition = 0;
        [self addChild:dirt];
        
        // Add foreground
        SKTextureAtlas *foregroundAtlas = [self textureAtlasNamed:@"foreground"];
        SKSpriteNode *upper = [SKSpriteNode spriteNodeWithTexture:[foregroundAtlas textureNamed:@"grass_upper"]];
        upper.anchorPoint = CGPointMake(0.5, 0.0);
        upper.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
        upper.zPosition = 1;
        [self addChild:upper];
        
        SKSpriteNode *lower = [SKSpriteNode spriteNodeWithTexture:[foregroundAtlas textureNamed:@"grass_lower"]];
        lower.anchorPoint = CGPointMake(0.5, 1.0);
        lower.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
        lower.zPosition = 3;
        [self addChild:lower];
        
        // Load sprites
        self.moles = [[NSMutableArray alloc] init];
        SKTextureAtlas *spriteAtlas = [self textureAtlasNamed:@"sprites"];
        self.moleTexture = [spriteAtlas textureNamed:@"mole_1.png"];
        
        float center = 240.0;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && IS_WIDESCREEN) {
            center = 284.0;
        }
        
        SKSpriteNode *mole1 = [SKSpriteNode spriteNodeWithTexture:self.moleTexture];
        mole1.position = [self convertPoint:CGPointMake(center - kMoleHoleOffset, 85.0)];
        mole1.zPosition = 2;
        mole1.name = @"Mole";
        mole1.userData = [[NSMutableDictionary alloc] init];
        [self addChild:mole1];
        [self.moles addObject:mole1];
        
        SKSpriteNode *mole2 = [SKSpriteNode spriteNodeWithTexture:self.moleTexture];
        mole2.position = [self convertPoint:CGPointMake(center, 85.0)];
        mole2.zPosition = 2;
        mole2.name = @"Mole";
        mole2.userData = [[NSMutableDictionary alloc] init];
        [self addChild:mole2];
        [self.moles addObject:mole2];
        
        SKSpriteNode *mole3 = [SKSpriteNode spriteNodeWithTexture:self.moleTexture];
        mole3.position = [self convertPoint:CGPointMake(center + kMoleHoleOffset, 85.0)];
        mole3.zPosition = 2;
        mole3.name = @"Mole";
        mole3.userData = [[NSMutableDictionary alloc] init];
        [self addChild:mole3];
        [self.moles addObject:mole3];
        
        
        self.laughAnimation = [self animationFromPlist:@"laughAnim"];
        self.hitAnimation = [self animationFromPlist:@"hitAnim"];
        
        // Add score label
        float margin = 10;
        self.scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        self.scoreLabel.text = @"Score: 0";
        self.scoreLabel.fontSize = [self convertFontSize:14];
        self.scoreLabel.zPosition = 4;
        self.scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        self.scoreLabel.position = CGPointMake(margin, margin);
        [self addChild:self.scoreLabel];
        
        
        // Preload whack sound effect
        self.laughSound = [SKAction playSoundFileNamed:@"laugh.caf" waitForCompletion:NO];
        self.owSound = [SKAction playSoundFileNamed:@"ow.caf" waitForCompletion:NO];
        
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"whack" withExtension:@"caf"];
        NSError *error = nil;
        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
        
        if (!self.audioPlayer) {
            NSLog(@"Error creating player: %@", error);
        }
        
        [self.audioPlayer play];
        
        
        // Add more here later...
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self];
    
    SKNode *node = [self nodeAtPoint:touchLocation];
    if ([node.name isEqualToString:@"Mole"]) {
        SKSpriteNode *mole = (SKSpriteNode *)node;
        if (![[mole.userData objectForKey:@"tappable"] boolValue]) {
            return;
        }
        
        self.score += 10;
        [mole.userData setObject:@0 forKey:@"tappable"];
        [mole removeAllActions];
        
        SKAction *easeMoveDown = [SKAction moveToY:(mole.position.y - mole.size.height) duration:0.2f];
        easeMoveDown.timingMode = SKActionTimingEaseInEaseOut;
        
        // Slow down the animation by half
        easeMoveDown.speed = 0.5;
        
        SKAction *sequence = [SKAction sequence:@[self.owSound, self.hitAnimation, easeMoveDown]];
        [mole runAction:sequence];
        
        if (self.gameOver) {
            return;
        }
        
        if (self.totalSpawns > 50) {
            SKLabelNode *gameOverLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
            gameOverLabel.text = @"Level Complete!";
            gameOverLabel.fontSize = 48;
            gameOverLabel.zPosition = 4;
            gameOverLabel.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
            [gameOverLabel setScale:0.1];
            [self addChild:gameOverLabel];
            [gameOverLabel runAction:[SKAction scaleTo:1.0 duration:0.5]];
            self.gameOver = YES;
            return;
        }
        
        [self.scoreLabel setText:[NSString stringWithFormat:@"Score: %d", self.score]];
    }
}

-(float)convertFontSize:(float)fontSize
{
    if(UI_USER_INTERFACE_IDIOM()){
        return fontSize * 2;
    }else{
        return fontSize;
    }
}

-(CGPoint)convertPoint:(CGPoint)point
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return CGPointMake(32 + point.x * 2, 64 + point.y * 2);
    }else{
        return point;
    }
}

-(SKAction *)animationFromPlist:(NSString *)animPlist
{
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:animPlist ofType:@"plist"];
    NSArray *animImages = [NSArray arrayWithContentsOfFile:plistPath];
    NSMutableArray *animFrames = [NSMutableArray array];
    for (NSString *imageName in animImages) {
        [animFrames addObject:[SKTexture textureWithImageNamed:imageName]];
    }
    
    float framesOverOneSecond = 1.0f / (float)[animFrames count];
    return [SKAction animateWithTextures:animFrames timePerFrame:framesOverOneSecond resize:NO restore:YES];
}

-(void)popMole:(SKSpriteNode *)mole
{
    if (self.totalSpawns > 50) {
        return;
    }
    
    self.totalSpawns++;
    // Reset texture of mole sprite
    mole.texture = self.moleTexture;
    
    SKAction *easeMoveUp = [SKAction moveToY:mole.position.y + mole.size.height duration:0.2f];
    easeMoveUp.timingMode = SKActionTimingEaseInEaseOut;
    
    SKAction *easeMoveDown = [SKAction moveToY:mole.position.y duration:0.2f];
    easeMoveDown.timingMode = SKActionTimingEaseInEaseOut;
    
    SKAction *setTappable = [SKAction runBlock:^{
        [mole.userData setObject:@1 forKey:@"tappable"];
    }];
    
    SKAction *unsetTappable = [SKAction runBlock:^{
        [mole.userData setObject:@0 forKey:@"tappable"];
    }];
    
//    SKAction *delay = [SKAction waitForDuration:0.5f];
    
    
    SKAction *sequence = [SKAction sequence:@[easeMoveUp, setTappable, self.laughSound, self.laughAnimation, unsetTappable, easeMoveDown]];
    [mole runAction:sequence completion:^{
        [mole removeAllActions];
    }];
    
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    
    NSLog(@"currentTime");
    
    for (SKSpriteNode *mole in self.moles) {
        if (arc4random() % 3 == 0) {
            if (!mole.hasActions) {
                [self popMole:mole];
            }
        }
    }
}

@end

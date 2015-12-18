//
//  JALSampler.h
//  JALAudioSampler
//
//  Created by Jason Lew on 12/17/15.
//  Copyright © 2015 Jason Lew. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AVFoundation;
@import AudioToolbox;
#import "JALLog.h"

@interface JALSampler : NSObject

@property (nonatomic) AudioUnit samplerUnit;

- (OSStatus)loadAUPreset:(NSString *)presetName;
- (BOOL)loadEXSInstrument:(NSString *)exsInstrumentName withPatch:(int)presetNumber;
- (BOOL)loadSoundFont:(NSString *)soundFontName withPatch:(int)presetNumber;
- (void)playNote:(UInt32)noteNum withVelocity:(UInt32)velocity;
- (void)stopNote:(UInt32)noteNum;

@end

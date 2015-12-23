//
//  JALMidiPlayer.h
//  JALAudioSampler
//
//  Created by Jason Lew on 12/19/15.
//  Copyright © 2015 Jason Lew. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AVFoundation;
@import AudioToolbox;

@interface JALMidiPlayer : NSObject

@property (nonatomic) MusicSequence musicSequence;

- (OSStatus)loadMidiSequence:(NSString *)midiSequence withAUGraph:(AUGraph)graph;
- (OSStatus)playMidiSequence;
- (OSStatus)stopMidiSequence;
- (OSStatus)setTempo:(Float64)tempo forSequence:(MusicSequence)sequence;

@end

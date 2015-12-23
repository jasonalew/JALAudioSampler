//
//  JALMidiPlayer.m
//  JALAudioSampler
//
//  Created by Jason Lew on 12/19/15.
//  Copyright © 2015 Jason Lew. All rights reserved.
//

#import "JALMidiPlayer.h"
#import "JALLog.h"

@interface JALMidiPlayer()

@property (nonatomic) MusicPlayer musicPlayer;

@end

@implementation JALMidiPlayer

- (instancetype)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    OSStatus result = noErr;
    
    // Create a new MusicPlayer and MusicSequence
    result = NewMusicPlayer(&_musicPlayer);
    NSAssert(result == noErr, @"Unable to create new MusicPlayer. Error code: %d", (int)result);
    
    result = NewMusicSequence(&_musicSequence);
    NSAssert(result == noErr, @"Unable to create new MusicSequence. Error code: %d", (int)result);
    
    return self;
}

- (OSStatus)loadMidiSequence:(NSString *)midiSequence withAUGraph:(AUGraph)graph
{
    OSStatus result = noErr;
    
    NSURL *midiSequenceURL = [NSURL fileURLWithPath:[[NSBundle mainBundle]pathForResource:midiSequence
                                                                                   ofType:@"mid"]];
    if (midiSequenceURL) {
        DLog(@"Attempting to load midi sequence: %@", [midiSequenceURL description]);
    } else {
        DLog(@"Could not get midi sequence path.");
    }
    
    // Load the midi sequence and set it for the music player.
    result = MusicSequenceFileLoad(self.musicSequence,
                                   (__bridge CFURLRef _Nonnull)(midiSequenceURL),
                                   0,
                                   0);
    result = MusicPlayerSetSequence(self.musicPlayer, self.musicSequence);
    NSAssert(result == noErr, @"Unable to set music player sequence. Error code: %d", (int)result);
    
    // Set the AUGraph for the sequence
    result = MusicSequenceSetAUGraph(self.musicSequence, graph);
    NSAssert(result == noErr, @"Unable to set the AUGraph for the sequence. Error code:", (int)result);
    
    // Prepare the music player to prevent any lag on play
    result = MusicPlayerPreroll(self.musicPlayer);
    NSAssert(result == noErr, @"Unable to start preroll on music player. Error code:", (int)result);
    
    return result;
}
- (OSStatus)playMidiSequence
{
    return MusicPlayerStart(self.musicPlayer);
}

- (OSStatus)stopMidiSequence
{
    OSStatus result                 = noErr;
    MusicTimeStamp startingTimeStamp    = 0;
    
    result = MusicPlayerStop(self.musicPlayer);
    
    // Reset the sequence to the beginning
    MusicPlayerSetTime(self.musicPlayer, startingTimeStamp);
    return result;
}

- (OSStatus)setTempo:(Float64)tempo forSequence:(MusicSequence)sequence
{
    MusicTrack tempoTrack;
    // Get the tempo track and remove the events
    MusicSequenceGetTempoTrack(sequence, &tempoTrack);
    [self removeTempoEvents:tempoTrack];
    // Set the new tempo
    return MusicTrackNewExtendedTempoEvent(tempoTrack, 0, tempo);
}

- (void)removeTempoEvents:(MusicTrack) tempoTrack
{
    // Create a new iterator
    MusicEventIterator iterator;
    NewMusicEventIterator(tempoTrack, &iterator);
    
    Boolean hasNext;
    MusicTimeStamp timeStamp    = 0;
    MusicEventType eventType    = 0;
    const void *eventData       = NULL;
    UInt32 eventDataSize        = 0;
    
    // Check if there is an event and loop
    MusicEventIteratorHasCurrentEvent(iterator, &hasNext);
    while (hasNext) {
        MusicEventIteratorGetEventInfo(iterator,
                                       &timeStamp,
                                       &eventType,
                                       &eventData,
                                       &eventDataSize);
        // Delete the tempo event
        if (eventType == kMusicEventType_ExtendedTempo) {
            MusicEventIteratorDeleteEvent(iterator);
        } else {
            MusicEventIteratorNextEvent(iterator);
        }
        MusicEventIteratorHasCurrentEvent(iterator, &hasNext);
        
    }
    DisposeMusicEventIterator(iterator);
}

@end

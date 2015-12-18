//
//  JALSampler.m
//  JALAudioSampler
//
//  Created by Jason Lew on 12/17/15.
//  Copyright © 2015 Jason Lew. All rights reserved.
//

#import "JALSampler.h"

// MIDI constants
enum {
    kMIDIMessage_NoteOn     = 0x9,
    kMIDIMessage_NoteOff    = 0x8,
};

const double preferredSampleRate = 44100.0;

@interface JALSampler()

@property (nonatomic) double    graphSampleRate;
@property (nonatomic) AUGraph   processingGraph;

@property (nonatomic) AudioUnit ioUnit;
@property (nonatomic, strong) AVAudioSession *sessionInstance;

@end

@implementation JALSampler

- (instancetype)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    // Set up the audio session for the app
    BOOL audioSessionActivated = [self setupAudioSession];
    NSAssert(audioSessionActivated == YES, @"Unable to set up the audio session.");
    
    // Create the audio processing graph.
    // Place references to the graph and to the sampler unit into the processing graph
    // and sampler unit instance variables.
    [self createAUGraph];
    [self configureAndStartAudioProcessingGraph:self.processingGraph];
    
    [self registerForAudioInterruptionNotifications];
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

#pragma mark - Configure AUGraph

- (BOOL) createAUGraph
{
    OSStatus result = noErr;
    AUNode samplerNode, ioNode;
    
    // Specify the common portion of the audio unit's identity
    AudioComponentDescription cd    = {};
    cd.componentManufacturer        = kAudioUnitManufacturer_Apple;
    cd.componentFlags               = 0;
    cd.componentFlagsMask           = 0;
    
    // Instantiate an audio processing graph
    self.processingGraph = nil;
    result = NewAUGraph(&_processingGraph);
    NSAssert(result == noErr, @"Unable to create an AUGraph object. Error code: %d", (int)result);
    
    // Description for the sampler unit
    cd.componentType = kAudioUnitType_MusicDevice;
    cd.componentSubType = kAudioUnitSubType_Sampler;
    
    // Add the sampler to the graph
    result = AUGraphAddNode(self.processingGraph, &cd, &samplerNode);
    NSAssert(result == noErr, @"Unable to add the sampler unit to the graph. Error code: %d", (int)result);
    
    // Specify the output unit
    cd.componentType = kAudioUnitType_Output;
    cd.componentSubType = kAudioUnitSubType_RemoteIO;
    
    // Add the output unit to the graph
    result = AUGraphAddNode(self.processingGraph, &cd, &ioNode);
    NSAssert(result == noErr, @"Unable to add the output unit to the graph. Error code: %d", (int)result);
    
    // Open the graph
    result = AUGraphOpen(self.processingGraph);
    NSAssert(result == noErr, @"Unable to open the graph. Error code: %d", (int)result);
    
    // Connect the sampler unit to the output unit
    result = AUGraphConnectNodeInput(self.processingGraph, samplerNode, 0, ioNode, 0);
    NSAssert(result == noErr, @"Unable to interconnect the nodes in the graph. Error code: %d", (int)result);
    
    // Obtain a reference to the sampler unit from its node
    result = AUGraphNodeInfo(self.processingGraph, samplerNode, NULL, &_samplerUnit);
    NSAssert(result == noErr, @"Unable to obtain a reference to the sampler unit. Error code: %d", (int)result);
    
    // Obtain a reference to the I/O unit from its node
    result = AUGraphNodeInfo(self.processingGraph, ioNode, NULL, &_ioUnit);
    NSAssert(result == noErr, @"Unable to obtain a reference to the I/O unit. Error code: %d", (int)result);
    
    return YES;
}

// Starting with instantiated audio processing graph, configure its audio units,
// initialize it, and start it.
- (OSStatus) configureAndStartAudioProcessingGraph: (AUGraph) graph
{
    OSStatus result = noErr;
    UInt32 framesPerSlice = 0;
    UInt32 framesPerSlicePropertySize = sizeof(framesPerSlice);
    UInt32 sampleRatePropertySize = sizeof(self.graphSampleRate);
    
    result = AudioUnitInitialize(self.ioUnit);
    NSAssert(result == noErr, @"Unable to initialize the I/O unit. Error code: %d", (int)result);
    
    // Set the I/O unit's output sample rate.
    result = AudioUnitSetProperty(self.ioUnit,
                                  kAudioUnitProperty_SampleRate,
                                  kAudioUnitScope_Output,
                                  0,
                                  &_graphSampleRate,
                                  sampleRatePropertySize);
    NSAssert(result == noErr,
             @"AudioUnitSetProperty (set I/O unit output stream sample rate). Error code: %d",
             (int)result);
    
    // Obtain the value of the maximum-frames-per-slice from the I/O unit.
    result = AudioUnitGetProperty(self.ioUnit,
                                  kAudioUnitProperty_MaximumFramesPerSlice,
                                  kAudioUnitScope_Global,
                                  0,
                                  &framesPerSlice,
                                  &framesPerSlicePropertySize);
    NSAssert(result == noErr,
             @"Unable to retrieve the maximum frames per slice from the I/O unit. Error code: %d",
             (int)result);
    
    // Set the sampler unit's output sample rate
    result = AudioUnitSetProperty(self.samplerUnit,
                                  kAudioUnitProperty_SampleRate,
                                  kAudioUnitScope_Output,
                                  0,
                                  &_graphSampleRate,
                                  sampleRatePropertySize);
    NSAssert(result == noErr,
             @"AudioUnitSetProperty (set sampler unit output stream sample rate). Error code: %d",
             (int)result);
    
    // Set the sampler unit's maximum frames per slice
    result = AudioUnitSetProperty(self.samplerUnit,
                                  kAudioUnitProperty_MaximumFramesPerSlice,
                                  kAudioUnitScope_Global,
                                  0,
                                  &framesPerSlice,
                                  framesPerSlicePropertySize);
    NSAssert(result == noErr,
             @"AudioUnitSetProperty (set sampler unit maximum frames per slice). Error code: %d",
             (int)result);
    
    if (graph) {
        // Initialize the audio processing graph.
        result = AUGraphInitialize(graph);
        NSAssert(result == noErr, @"Unable to initialize the AUGraph object. Error code: %d", (int)result);
        
        // Start the graph
        result = AUGraphStart(graph);
        NSAssert(result == noErr, @"Unable to start audio processing graph. Error code: %d", (int)result);
        
        // Print out the graph to the console
        CAShow(graph);
    }
    
    return result;
}

// Stop the audio processing graph
- (void)stopAudioProcessingGraph
{
    OSStatus result = noErr;
    if (self.processingGraph) {
        result = AUGraphStop(self.processingGraph);
        NSAssert(result == noErr,
                 @"Unable to stop the audio processing graph. Error code: %d",
                 (int)result);
    }
}

// Restart the audio processing graph
- (void)restartAudioProcessingGraph
{
    OSStatus result = noErr;
    if (self.processingGraph) {
        result = AUGraphStart(self.processingGraph);
        NSAssert(result == noErr,
                 @"Unable to restart the audio processing graph. Error code: %d",
                 (int)result);
    }
}

// Setup the audio session
- (BOOL)setupAudioSession
{
    self.sessionInstance = [AVAudioSession sharedInstance];
    
    NSError *error = nil;
    
    // Set the session category
    BOOL success = [self.sessionInstance setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&error];
    if (!success) {
        DLog(@"Error setting AVAudioSession category %@\n", [error localizedDescription]);
        return NO;
    }
    
    // Request a desired sample rate
    self.graphSampleRate = preferredSampleRate; // Sample rate 44.1kHz
    success = [self.sessionInstance setPreferredSampleRate:self.graphSampleRate error:&error];
    if (!success) {
        DLog(@"Error setting preferred hardware sample rate %@\n", [error localizedDescription]);
        return NO;
    }
    
    // Request preferred buffer duration
    NSTimeInterval bufferDuration = .005; // Buffer duration 5ms
    success = [self.sessionInstance setPreferredIOBufferDuration:bufferDuration error:&error];
    if (!success) {
        DLog(@"Error setting preferred buffer duration %@\n", [error localizedDescription]);
        return NO;
    }
    
    // Activate the audio session
    success = [self.sessionInstance setActive:YES error:&error];
    if (!success) {
        DLog(@"Error activating the audio session %@\n", [error localizedDescription]);
        return NO;
    }
    
    // Obtain the actual hardware sample rate and store it for later use in the audio processing graph.
    self.graphSampleRate = [self.sessionInstance sampleRate];
    
    return YES;
}

#pragma mark - Load Instruments

- (BOOL)loadSoundFont:(NSString *)soundFontName withPatch:(int)presetNumber
{
    NSURL *soundFontURL = [NSURL fileURLWithPath:[[NSBundle mainBundle]pathForResource:soundFontName
                                                                                ofType:@"sf2"]];
    
    if (soundFontURL) {
        DLog(@"Attempting to load SoundFont: %@", [soundFontURL description]);
        [self loadAUSamplerInstrument:soundFontURL
                            withPatch:presetNumber
                               ofType:kInstrumentType_SF2Preset];
    } else {
        DLog(@"Could not get SoundFont path.");
        return NO;
    }
    return YES;
}

- (BOOL)loadEXSInstrument:(NSString *)exsInstrumentName withPatch:(int)presetNumber
{
    NSURL *exsInstrumentURL = [NSURL fileURLWithPath:[[NSBundle mainBundle]pathForResource:exsInstrumentName
                                                                                    ofType:@"exs"]];
    
    if (exsInstrumentURL) {
        DLog(@"Attempting to load EXS Instrument: %@", [exsInstrumentURL description]);
        [self loadAUSamplerInstrument:exsInstrumentURL
                            withPatch:presetNumber
                               ofType:kInstrumentType_EXS24];
    } else {
        DLog(@"Could not get EXS Instrument path.");
        return NO;
    }
    return YES;
}

- (OSStatus)loadAUSamplerInstrument:(NSURL *)instrumentURL
                          withPatch:(int)presetNumber
                             ofType:(UInt8)instrumentType
{
    OSStatus result = noErr;
    
    // Fill out an instrument data structure
    AUSamplerInstrumentData instData = {0};
    instData.fileURL        = (__bridge CFURLRef _Nonnull)(instrumentURL);
    instData.instrumentType = instrumentType;
    instData.bankMSB        = kAUSampler_DefaultMelodicBankMSB;
    instData.bankLSB        = kAUSampler_DefaultBankLSB;
    instData.presetID       = (UInt8)presetNumber;
    
    // Set the kAUSamplerProperty_LoadPresetFromBank property
    result = AudioUnitSetProperty(self.samplerUnit,
                                  kAUSamplerProperty_LoadInstrument,
                                  kAudioUnitScope_Global,
                                  0,
                                  &instData,
                                  sizeof(instData));
    NSAssert(result == noErr,
             @"Unable to set the preset property on the sampler. Error code: %d",
             (int)result);
    return result;
}

- (OSStatus)loadAUPreset:(NSString *)presetName
{
    NSURL *presetURL = [NSURL fileURLWithPath:[[NSBundle mainBundle]pathForResource:presetName
                                                                             ofType:@"aupreset"]];
    if (presetURL) {
        DLog(@"Attempting to load preset '%@'\n", [presetURL  description]);
    } else {
        DLog(@"Could not get preset path");
    }
    
    OSStatus result = noErr;
    
    AUSamplerInstrumentData auPreset = {0};
    
    auPreset.fileURL = (__bridge CFURLRef)presetURL;
    auPreset.instrumentType = kInstrumentType_AUPreset;
    
    result = AudioUnitSetProperty(self.samplerUnit,
                                  kAUSamplerProperty_LoadInstrument,
                                  kAudioUnitScope_Global,
                                  0,
                                  &auPreset,
                                  sizeof(auPreset));
    return result;
}

- (void)playNote:(UInt32)noteNum withVelocity:(UInt32)velocity
{
    UInt32 newVelocity = velocity > 127 ? 127 : velocity; // Make sure 0-127
    UInt32 noteCommand = kMIDIMessage_NoteOn << 4 | 0;
    
    OSStatus result = noErr;
    result = MusicDeviceMIDIEvent(self.samplerUnit, noteCommand, noteNum, newVelocity, 0);
    if (result != noErr) {
        DLog(@"Unable to play the note. Error code: %d", (int)result);
    }
}

- (void)stopNote:(UInt32)noteNum
{
    UInt32 noteCommand = kMIDIMessage_NoteOff << 4 | 0;
    
    OSStatus result = noErr;
    result = MusicDeviceMIDIEvent(self.samplerUnit, noteCommand, noteNum, 0, 0);
    if (result != noErr) {
        DLog(@"Unable to stop playing the note. Error code: %d", (int)result);
    }
}

#pragma mark - Audio Interruption Handling

// Register for audio interruption notifications
- (void)registerForAudioInterruptionNotifications
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(handleInterruption:) name:AVAudioSessionInterruptionNotification object:self.sessionInstance];
    
    [notificationCenter addObserver:self selector:@selector(handleRouteChange:) name:AVAudioSessionRouteChangeNotification object:self.sessionInstance];
    
    [notificationCenter addObserver:self selector:@selector(handleMediaServicesReset:) name:AVAudioSessionMediaServicesWereResetNotification object:self.sessionInstance];
}

- (void)handleInterruption:(NSNotification *)notification
{
    UInt8 theInterruptionType = [[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] intValue];
    if (theInterruptionType == AVAudioSessionInterruptionTypeBegan) {
        [self stopAudioProcessingGraph];
        DLog(@"Audio session interruption began.");
    } else if (theInterruptionType == AVAudioSessionInterruptionTypeEnded) {
        [self restartAudioProcessingGraph];
        DLog(@"Audio session interruption ended.");
    }
}

- (void)handleRouteChange:(NSNotification *)notification
{
    UInt8 reasonValue = [[notification.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey]intValue];
    DLog(@"Route change: ");
    
    switch (reasonValue) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            DLog(@"New Device Available");
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            DLog(@"Old Device Unavailable");
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            DLog(@"Category Change, New Catagory: %@", [self.sessionInstance category]);
            break;
        case AVAudioSessionRouteChangeReasonOverride:
            DLog(@"Override");
            break;
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            DLog(@"Wake From Sleep");
            break;
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            DLog(@"No Suitable Route For Category");
            break;
        default:
            DLog(@"Reason Unknown");
            break;
    }
    
    DLog(@"Previous route: %@", [notification.userInfo valueForKey:AVAudioSessionRouteChangePreviousRouteKey]);
}

- (void)handleMediaServicesReset:(NSNotification *)notification
{
    // If we received this notification, the media server has been reset.
    // Rewire all the connections and start the engine.
    
    DLog(@"Media services has been reset. Rewiring connections and starting again.");
    [self createAUGraph];
    [self restartAudioProcessingGraph];
    
}

@end

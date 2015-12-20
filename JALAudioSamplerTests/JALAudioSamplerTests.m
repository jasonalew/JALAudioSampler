//
//  JALAudioSamplerTests.m
//  JALAudioSamplerTests
//
//  Created by Jason Lew on 12/17/15.
//  Copyright © 2015 Jason Lew. All rights reserved.
//

#import <XCTest/XCTest.h>
@import AVFoundation;
@import AudioToolbox;
#import "JALSampler.h"
#import "JALMidiPlayer.h"

@interface JALAudioSamplerTests : XCTestCase

@property (nonatomic, strong) JALSampler *sampler;

@end

@implementation JALAudioSamplerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.sampler = [[JALSampler alloc]init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    self.sampler = nil;
    [super tearDown];
}

- (void)loadSoundFont {
    [self.sampler loadSoundFont:@"ElPiano1" withPatch:0];
}

- (void)testLoadEXSInstrument {
    [self.sampler loadEXSInstrument:@"ontology-destroy-you-bass" withPatch:0];
}

- (void)testLoadSoundFont {
    [self loadSoundFont];
}

- (void)testLoadMidiSequence {
    [self loadSoundFont];
    JALMidiPlayer *midiPlayer = [[JALMidiPlayer alloc]init];
    [midiPlayer loadMidiSequence:@"bach-invention-01" withAUGraph:self.sampler.processingGraph];
}

//- (void)testExample {
//    // This is an example of a functional test case.
//    // Use XCTAssert and related functions to verify your tests produce the correct results.
//}
//
//- (void)testPerformanceExample {
//    // This is an example of a performance test case.
//    [self measureBlock:^{
//        // Put the code you want to measure the time of here.
//    }];
//}

@end

//
//  JALAudioSamplerTests.m
//  JALAudioSamplerTests
//
//  Created by Jason Lew on 12/17/15.
//  Copyright © 2015 Jason Lew. All rights reserved.
//

#import <XCTest/XCTest.h>
@import AVFoundation;
#import "JALSampler.h"

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

- (void)testLoadEXSInstrument {
    [self.sampler loadEXSInstrument:@"ontology-destroy-you-bass" withPatch:0];
}

- (void)testLoadSoundFont {
    [self.sampler loadSoundFont:@"ElPiano1" withPatch:0];
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

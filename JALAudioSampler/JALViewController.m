//
//  JALViewController.m
//  JALAudioSampler
//
//  Created by Jason Lew on 12/17/15.
//  Copyright © 2015 Jason Lew. All rights reserved.
//

#import "JALViewController.h"
#import "JALSampler.h"

@interface JALViewController ()
@property (weak, nonatomic) IBOutlet UIButton *button01;
@property (weak, nonatomic) IBOutlet UIButton *button02;
@property (weak, nonatomic) IBOutlet UIButton *button03;
@property (weak, nonatomic) IBOutlet UIButton *button04;
@property (weak, nonatomic) IBOutlet UIButton *button05;
@property (weak, nonatomic) IBOutlet UIButton *button06;
@property (weak, nonatomic) IBOutlet UIButton *button07;

@property (strong, nonatomic) JALSampler *sampler;

@end

@implementation JALViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Add selectors to the buttons.
    // Touch down to play the note and touch up inside to stop the note.
    NSArray *buttonArray = @[self.button01,
                             self.button02,
                             self.button03,
                             self.button04,
                             self.button05,
                             self.button06,
                             self.button07];
    for (UIButton *button in buttonArray) {
        [button addTarget:self
                   action:@selector(playNote:)
         forControlEvents:UIControlEventTouchDown ];
        [button addTarget:self
                   action:@selector(stopNote:)
         forControlEvents:UIControlEventTouchUpInside];
    }
    
    // Create the sampler and load an instrument
    self.sampler = [[JALSampler alloc]init];
    [self.sampler loadEXSInstrument:@"ontology-destroy-you-bass" withPatch:0];
}

- (void)playNote:(UIButton *)button
{
    // Buttons are tagged 1-7
    switch (button.tag) {
        case 1:
            [self.sampler playNote:60 withVelocity:127];
            break;
        case 2:
            [self.sampler playNote:62 withVelocity:127];
            break;
        case 3:
            [self.sampler playNote:64 withVelocity:127];
            break;
        case 4:
            [self.sampler playNote:65 withVelocity:127];
            break;
        case 5:
            [self.sampler playNote:67 withVelocity:127];
            break;
        case 6:
            [self.sampler playNote:69 withVelocity:127];
            break;
        case 7:
            [self.sampler playNote:71 withVelocity:127];
            break;
            
        default:
            break;
    }
}

- (void)stopNote:(UIButton *)button
{
    switch (button.tag) {
        case 1:
            [self.sampler stopNote:60];
            break;
        case 2:
            [self.sampler stopNote:62];
            break;
        case 3:
            [self.sampler stopNote:64];
            break;
        case 4:
            [self.sampler stopNote:65];
            break;
        case 5:
            [self.sampler stopNote:67];
            break;
        case 6:
            [self.sampler stopNote:69];
            break;
        case 7:
            [self.sampler stopNote:71];
            break;
            
        default:
            break;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

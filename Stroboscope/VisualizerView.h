//
//  VisualizerView.h
//  Stroboscope
//
//  Created by Kate and Ricky on 1/3/14.
//  Copyright (c) 2014 pomware. All rights reserved.

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
@interface VisualizerView : UIView

@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (strong, nonatomic) AVAudioRecorder *audioRecorder;
@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureDevice *flashlight;


@end
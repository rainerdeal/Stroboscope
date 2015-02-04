//
//  VisualizerView.mm
//  Stroboscope
//
//  Created by Kate and Ricky on 1/3/14.
//  Copyright (c) 2014 pomware. All rights reserved.

#import "VisualizerView.h"
#import <QuartzCore/QuartzCore.h>
#import "MeterTable.h"
#import <AVFoundation/AVFoundation.h>

@implementation VisualizerView {
    CAEmitterLayer *emitterLayer;
    MeterTable meterTable;
}

+ (Class)layerClass {
    return [CAEmitterLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
    self.captureSession = [[AVCaptureSession alloc] init];
    [_captureSession beginConfiguration];
    [_captureSession commitConfiguration];
    [_captureSession startRunning];
    self.flashlight = [AVCaptureDevice defaultDeviceWithMediaType: AVMediaTypeVideo];
    
    
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor blackColor]];
        emitterLayer = (CAEmitterLayer *)self.layer;
        
        CGFloat width = MAX(frame.size.width, frame.size.height);
        CGFloat height = MIN(frame.size.width, frame.size.height);
        emitterLayer.emitterPosition = CGPointMake(width/2, height/2);
        emitterLayer.emitterSize = CGSizeMake(width-80, 60);
        emitterLayer.emitterShape = kCAEmitterLayerRectangle;
        emitterLayer.renderMode = kCAEmitterLayerAdditive;
        
        CAEmitterCell *cell = [CAEmitterCell emitterCell];
        cell.name = @"cell";
        CAEmitterCell *childCell = [CAEmitterCell emitterCell];
        childCell.name = @"childCell";
        childCell.lifetime = 1.0f / 60.0f;
        childCell.birthRate = 60.0f;
        childCell.velocity = 0.0f;
        
        childCell.contents = (id)[[UIImage imageNamed:@"particleTexture.png"] CGImage];
        
        cell.emitterCells = @[childCell];
        
        //pink color
        cell.color = [[UIColor colorWithRed:0.8f green:0.2f blue:0.1f alpha:0.6f] CGColor];
        cell.redRange = 0.46f;
        cell.greenRange = 0.49f;
        cell.blueRange = 0.67f;
        cell.alphaRange = 0.55f;
        
        cell.redSpeed = -0.11f;
        cell.greenSpeed = 0.07f;
        cell.blueSpeed = 0.25f;
        cell.alphaSpeed = 0.15f;
        
        cell.scale = 0.5f;
        cell.scaleRange = 0.5f;
        
        cell.lifetime = 1.0f;
        cell.lifetimeRange = .25f;
        cell.birthRate = 70;
        
        cell.velocity = 100.0f;
        cell.velocityRange = 300.0f;
        cell.emissionRange = M_PI * 2;
        
        emitterLayer.emitterCells = @[cell];
        
        
        CADisplayLink *dpLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
        [dpLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (void)update {
    static int flash = 0;
    flash++;
    float scale = 0.5;
    
    if (_audioPlayer.playing ) {
        [_audioPlayer updateMeters];
        
        float power = 0.0f;
        for (int i = 0; i < [_audioPlayer numberOfChannels]; i++) {
            power += [_audioPlayer averagePowerForChannel:i];
        }
        power /= [_audioPlayer numberOfChannels];
        
        float level = meterTable.ValueAt(power);
        scale = level * 5;
        if ([_flashlight isTorchAvailable] && [_flashlight isTorchModeSupported:AVCaptureTorchModeOn]) {
            BOOL success = [_flashlight lockForConfiguration: nil];
            if (success && level > .7 && level < 1.0 && flash % 6 == 0) {
                [_flashlight setTorchMode:AVCaptureTorchModeOn];
            }
            [NSThread sleepForTimeInterval:0.008f];
            [_flashlight setTorchMode:AVCaptureTorchModeOff];
            [_flashlight unlockForConfiguration];
        }
    } else if (_audioRecorder.recording){
        [_audioRecorder updateMeters];
        
        float power = 0.0f;
        power = [_audioRecorder averagePowerForChannel:0];
        
        float level = meterTable.ValueAt(power) * 1.5;
        scale = level * 7;
        if ([_flashlight isTorchAvailable] && [_flashlight isTorchModeSupported:AVCaptureTorchModeOn]) {
            BOOL success = [_flashlight lockForConfiguration: nil];
            if (success && level > .5 && level < 1.0 && flash % 6 == 0) {
                [_flashlight setTorchMode:AVCaptureTorchModeOn];
            }
            [NSThread sleepForTimeInterval:0.008f];
            [_flashlight setTorchMode:AVCaptureTorchModeOff];
            [_flashlight unlockForConfiguration];
        }
    }
    [emitterLayer setValue:@(scale) forKeyPath:@"emitterCells.cell.emitterCells.childCell.scale"];
}

@end
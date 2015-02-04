//
//  ViewController.m
//  Stroboscope
//
//  Created by Kate and Ricky on 1/3/14.
//  Copyright (c) 2014 pomware. All rights reserved.

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "VisualizerView.h"

@interface ViewController ()

@property (strong, nonatomic) UIView *backgroundView;
@property (strong, nonatomic) UINavigationBar *navBar;
@property (strong, nonatomic) UIToolbar *toolBar;
@property (strong, nonatomic) NSArray *playItems;
@property (strong, nonatomic) NSArray *pauseItems;
@property (strong, nonatomic) NSArray *stopItems;
@property (strong, nonatomic) NSArray *recordItems;
@property (strong, nonatomic) UIBarButtonItem *playBBI;
@property (strong, nonatomic) UIBarButtonItem *pauseBBI;
@property (strong, nonatomic) UIBarButtonItem *pickBBI;
@property (strong, nonatomic) UIBarButtonItem *recordBBI;
@property (strong, nonatomic) UIBarButtonItem *stopBBI;
@property (strong, nonatomic) UIBarButtonItem *mode;
@property (strong, nonatomic) UIColor *buttonColor;
@property (strong, nonatomic) UIApplication *app;


// Add properties here
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (strong, nonatomic) AVAudioRecorder *audioRecorder;
@property (strong, nonatomic) VisualizerView *visualizer;

@property BOOL isPaused;
@property BOOL scrubbing;
@property NSTimer *strobeTimer;

@end

@implementation ViewController {
    BOOL _isPlaying;
    BOOL _isRecording;
    //true if mic, false if music
    BOOL _micMusic;
}

- (void)configureAudioPlayer {
    NSURL *audioFileURL = [[NSBundle mainBundle] URLForResource:@"" withExtension:@""];
    NSError *error;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioFileURL error:&error];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
    }
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [_audioPlayer setNumberOfLoops: -1];
    [_audioPlayer setMeteringEnabled:YES];
    [_visualizer setAudioPlayer:_audioPlayer];
}

-(void)configureAudioRecorder{
    NSDictionary* recorderSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithInt:kAudioFormatAppleIMA4],AVFormatIDKey,
                                      [NSNumber numberWithInt:44100],AVSampleRateKey,
                                      [NSNumber numberWithInt:1],AVNumberOfChannelsKey,
                                      [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
                                      [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,
                                      [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                                      nil];
    NSError* error = nil;
    NSURL *tmpurl = [NSURL URLWithString: [NSTemporaryDirectory() stringByAppendingPathComponent: @"tmp.cfa"]];
    self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:tmpurl  settings:recorderSettings error:&error];
    [_audioRecorder setMeteringEnabled:YES];
    [_visualizer setAudioRecorder: _audioRecorder];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureBars];
    self.visualizer = [[VisualizerView alloc] initWithFrame:self.view.frame];
    [_visualizer setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
    [_backgroundView addSubview:_visualizer];
    [self configureAudioRecordSession];
    [self configureAudioRecorder];
    
    self.app = [UIApplication sharedApplication];
    self.app.idleTimerDisabled = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self toggleBars];
}

- (void)configureBars {
    self.buttonColor = [UIColor colorWithRed:0.0f green:0.6f blue:0.8f alpha:0.6f];
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    CGRect frame = self.view.frame;
    
    self.backgroundView = [[UIView alloc] initWithFrame:frame];
    [_backgroundView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
    [_backgroundView setBackgroundColor:[UIColor blackColor]];
    
    [self.view addSubview:_backgroundView];
    // NavBar
    self.navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 44)];
    [_navBar setBarStyle:UIBarStyleBlackTranslucent];
    [_navBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    
    UINavigationItem *navTitleItem = [[UINavigationItem alloc] initWithTitle:@""];
    [_navBar pushNavigationItem:navTitleItem animated:NO];
    
    UIImage *image = [UIImage imageNamed:@"194-note-2.png"];
    UIBarButtonItem *micMode = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(selectMode)];
    navTitleItem.rightBarButtonItem = micMode;
    navTitleItem.rightBarButtonItem.tintColor = self.buttonColor;
    
    [self.view addSubview:_navBar];
    
    // ToolBar
    self.toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 276, frame.size.width, 44)];
    [_toolBar setBarStyle:UIBarStyleBlackTranslucent];
    [_toolBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    
    self.playBBI = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(playPause)];
    self.playBBI.tintColor =  self.buttonColor;
    self.pauseBBI = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(playPause)];
    self.pauseBBI.tintColor =  self.buttonColor;
    
    self.recordBBI = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(recordStop)];
    self.recordBBI.tintColor =  self.buttonColor;
    
    self.stopBBI = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(recordStop)];
    self.stopBBI.tintColor =  self.buttonColor;
    
    //time values
    UIBarButtonItem *leftFlexBBI = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *rightFlexBBI = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    self.playItems = [NSArray arrayWithObjects: leftFlexBBI, _playBBI, rightFlexBBI, nil];
    self.pauseItems = [NSArray arrayWithObjects: leftFlexBBI, _pauseBBI,  rightFlexBBI, nil];
    self.recordItems = [NSArray arrayWithObjects: leftFlexBBI, _recordBBI, rightFlexBBI, nil];
    self.stopItems = [NSArray arrayWithObjects: leftFlexBBI,_stopBBI, rightFlexBBI, nil];
    
    [_toolBar setItems:_recordItems];
    [self.view addSubview:_toolBar];
    
    _micMusic = YES;
    _isPlaying = NO;
    _isRecording = NO;
    
    UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureHandler:)];
    [_backgroundView addGestureRecognizer:tapGR];
}

- (void)selectMode{
    if(_micMusic){
        if(_isRecording){
            [self recordStop];
        }
        [self configureAudioPlaybackSession];
        [self configureAudioPlayer];
        UIImage *image = [UIImage imageNamed:@"Microphone-1.png"];
        UIBarButtonItem *musMode = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(selectMode)];
        [_navBar.topItem setRightBarButtonItem:musMode];
        [_navBar.topItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(pickSong)]];
        [_navBar setTintColor:self.buttonColor];
        [_toolBar setItems:_playItems];
        _micMusic = NO;
    } else {
        if(_isPlaying)
            [self playPause];
        [self configureAudioRecordSession];
        [self configureAudioRecorder];
        [_navBar.topItem setTitle:@""];
        UIImage *image = [UIImage imageNamed:@"194-note-2.png"];
        UIBarButtonItem *micMode = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(selectMode)];
        micMode.tintColor =  self.buttonColor;
        [_navBar.topItem setRightBarButtonItem: micMode];
        [_navBar.topItem setLeftBarButtonItem:nil];
        [_toolBar setItems: _recordItems];
        _micMusic = YES;
    }
}

- (void)toggleBars {
    BOOL barsHidden = self.navBar.hidden;
    self.navBar.hidden = !barsHidden;
    self.toolBar.hidden = !barsHidden;
}

- (void)tapGestureHandler:(UITapGestureRecognizer *)tapGR {
    [self toggleBars];
}

- (void)playPause {
    if (_isPlaying) {
        // Pause audio here
        [_audioPlayer pause];
        [_toolBar setItems:_playItems];  // toggle play/pause button
        
    }
    else {
        // Play audio here
        [_audioPlayer play];
        [_toolBar setItems:_pauseItems]; // toggle play/pause button
    }
    _isPlaying = !_isPlaying;
}

-(void)recordStop{
    if (_isRecording) {
        // Pause audio here
        [_audioRecorder stop];
        [_toolBar setItems:_recordItems];  // toggle play/pause button
        
    }
    else {
        // Play audio here
        [_audioRecorder record];
        [_toolBar setItems:_stopItems]; // toggle play/pause button
    }
    _isRecording = !_isRecording;
}

- (void)playURL:(NSURL *)url {
    if (_isPlaying) {
        [self playPause]; // Pause the previous audio player
    }
    
    // Add audioPlayer configurations here
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    [_audioPlayer setNumberOfLoops: -1];
    [_audioPlayer setMeteringEnabled:YES];
    [_visualizer setAudioPlayer:_audioPlayer];
    [self playPause];
}

- (void)configureAudioPlaybackSession {
    NSError *error;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
    
    if (error) {
        NSLog(@"Error setting category: %@", [error description]);
    }
}

- (void)configureAudioRecordSession {
    NSError *error;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:&error];
    
    if (error) {
        NSLog(@"Error setting category: %@", [error description]);
    }
}


/*
 * This method is called when the user presses the plus button. It displays a media picker
 * screen to the user configured to show only audio files.
 */
- (void)pickSong {
    MPMediaPickerController *picker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeAnyAudio];
    [picker setDelegate:self];
    [picker setAllowsPickingMultipleItems: NO];
    [self presentViewController:picker animated:YES completion:NULL];
}


/*
 * This method is called when the user chooses something from the media picker screen. It dismisses the media picker screen
 * and plays the selected song.
 */
- (void)mediaPicker:(MPMediaPickerController *) mediaPicker didPickMediaItems:(MPMediaItemCollection *) collection {
    
    // remove the media picker screen
    [self dismissViewControllerAnimated:YES completion:NULL];
    
    // grab the first selection (media picker is capable of returning more than one selected item,
    // but this app only deals with one song at a time)
    MPMediaItem *item = [[collection items] objectAtIndex:0];
    NSString *title = [item valueForProperty:MPMediaItemPropertyTitle];
    [_navBar.topItem setTitle:title];
    
    // get a URL reference to the selected item
    NSURL *url = [item valueForProperty:MPMediaItemPropertyAssetURL];
    
    // pass the URL to playURL:, defined earlier in this file
    [self playURL:url];
}

/*
 * This method is called when the user cancels out of the media picker. It just dismisses the media picker screen.
 */
- (void)mediaPickerDidCancel:(MPMediaPickerController *) mediaPicker {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
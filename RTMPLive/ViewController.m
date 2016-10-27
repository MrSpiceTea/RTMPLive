//
//  ViewController.m
//  RTMPLive
//
//  Created by 谢展图 on 2016/10/14.
//  Copyright © 2016年 spice. All rights reserved.
//

#import "ViewController.h"
@import Accelerate;
@import AVFoundation;

@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>{
    AVCaptureSession *avCaptureSession;
//    AVCaptureVideoDataOutput *audioDataOutput;
    AVCaptureVideoDataOutput *videoDataOutput;
//    AVCaptureConnection *audioConnect;
    AVCaptureConnection *videooConnect;
    AVCaptureVideoPreviewLayer *_previewLayer;
    CALayer *customPreviewLayer;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    avCaptureSession = [[AVCaptureSession alloc] init];
    AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:&error];
    if ([avCaptureSession canAddInput:audioInput]) {
        [avCaptureSession addInput:audioInput];
    }
    
    
    videoDataOutput = [[AVCaptureVideoDataOutput alloc]init];
    dispatch_queue_t videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
    [videoDataOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];
    
    if ([avCaptureSession canAddOutput:videoDataOutput]) {
        [avCaptureSession addOutput:videoDataOutput];
    }
    
    NSDictionary *captureSettings = @{(NSString*)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
    videoDataOutput.videoSettings = captureSettings;
    videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    
//    audioConnect = [audioDataOutput connectionWithMediaType:AVMediaTypeAudio];
    videooConnect = [videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    
    //添加预览到界面
    _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:avCaptureSession];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill; // 设置预览时的视频缩放方式
    [[_previewLayer connection] setVideoOrientation:AVCaptureVideoOrientationPortrait]; // 设置视频的朝向
    _previewLayer.frame = CGRectMake(0, 5, CGRectGetWidth(self.view.frame), 250);
    [self.view.layer addSublayer:_previewLayer];
    
    //实时处理后的视频
    customPreviewLayer = [CALayer layer];
    customPreviewLayer.frame = CGRectMake(0, 200, CGRectGetWidth(self.view.frame), 300);
    customPreviewLayer.affineTransform = CGAffineTransformMakeRotation(M_PI/2);
    [self.view.layer addSublayer:customPreviewLayer];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    if (connection == videooConnect) {
//        NSLog(@"%@",videooConnect);
        CVImageBufferRef imageBuffer =  CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(imageBuffer, 0);
        size_t width = CVPixelBufferGetWidthOfPlane(imageBuffer, 0);
        size_t height = CVPixelBufferGetHeightOfPlane(imageBuffer, 0);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);
        
        //luam
        Pixel_8 *lumaBuffer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
        
        CGColorSpaceRef grayColorSpace = CGColorSpaceCreateDeviceGray();
        CGContextRef context = CGBitmapContextCreate(lumaBuffer, width, height, 8, bytesPerRow, grayColorSpace, kCGImageAlphaNone);
        CGImageRef dstImage = CGBitmapContextCreateImage(context);
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            customPreviewLayer.contents = (__bridge id)dstImage;
        });
        CGImageRelease(dstImage);
        CGContextRelease(context);
        CGColorSpaceRelease(grayColorSpace);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)openButtonTapped:(id)sender {
    if (!avCaptureSession.isRunning) {
        [avCaptureSession startRunning];
    }
}

- (IBAction)closeButtonTapped:(id)sender {
    if (avCaptureSession.isRunning) {
        [avCaptureSession stopRunning];
    }
}

- (IBAction)transtionButtonTapped:(id)sender {
    
}

@end

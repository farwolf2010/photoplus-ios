//
//  WXPhotoplusModule.m
//  AFNetworking
//
//  Created by 郑江荣 on 2019/5/28.
//

#import "WXPhotoplusModule.h"
#import "TZImagePickerController.h"
//#import <ZLPhotoBrowser/ZLPhotoBrowser.h>
#import "farwolf.h"
#import "RSKImageCropper/RSKImageCropper.h"
 
//#import <SDWebImage/SDAnimatedImageView.h>

//注册module，名字叫photoplus
WX_PlUGIN_EXPORT_MODULE(photoplus, WXPhotoplusModule)

@implementation WXPhotoplusModule
    
@synthesize weexInstance;
//异步方法
WX_EXPORT_METHOD(@selector(open:callback:))
//同步返回方法注册
WX_EXPORT_METHOD_SYNC(@selector(getData))
CGFloat _aspX = 0.0f;
CGFloat _aspY = 0.0f;
WXModuleCallback _returnImgPath;
-(void)open:(NSMutableDictionary*)param  callback:(WXModuleCallback)callback{
    _returnImgPath = callback;
    NSString *action=@"choose";
    if(param[@"action"]){
        action=param[@"action"];
    }
    NSString *type=@"photo";
    if(param[@"type"]){
        type=param[@"type"];
    }
    CGFloat aspX=0;
    CGFloat aspY=0;
    CGFloat maxSize=0;
    int maxCount=99;
    
    if(param[@"aspX"]){
          aspX = [[@"" add:param[@"aspX"]] floatValue];
          _aspX = aspX;
      }
    if(param[@"aspY"]){
          aspY = [[@"" add:param[@"aspY"]] floatValue];
         _aspY = aspY;
    }
    if(param[@"maxSize"]){
        maxSize = [[@"" add:param[@"maxSize"]] floatValue];
     }
    if(param[@"maxCount"]){
        maxCount = [[@"" add:param[@"maxCount"]] intValue] ;
     }
    

    if([@"choose" isEqualToString:action]){
        if([@"video" isEqualToString:type]){
            [self chooseVideo:callback];
        }else{
            int maxCount=99;
            if(aspX>0&&aspY>0){
                maxCount=1;
            }
            [self chooseImage:maxSize aspX:aspX aspY:aspY count:maxCount callback:callback];
        }
       
    }else{
        self.maxSize=maxSize;
        [self openCamera:aspX aspY:aspY themeColor:@"#000000" callback:callback];
    }
    
    
}

-(void)chooseVideo:(WXModuleCallback)callback{
    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:99 delegate:self];
    imagePickerVc.allowPickingVideo=true;
    imagePickerVc.allowTakeVideo=true;
    imagePickerVc.allowPickingImage = NO;
    
    [imagePickerVc setDidFinishPickingVideoHandle:^(UIImage *coverImage, PHAsset *asset) {
        NSMutableDictionary *data=[NSMutableDictionary new];
        NSMutableArray *ary=[NSMutableArray new];
        [[TZImageManager manager] getVideoOutputPathWithAsset:asset presetName:AVAssetExportPresetLowQuality success:^(NSString *outputPath) {
               // NSData *data = [NSData dataWithContentsOfFile:outputPath];
               NSLog(@"视频导出到本地完成,沙盒路径为:%@",outputPath);
               NSMutableArray *ary=[NSMutableArray new];
               NSMutableDictionary *item=[NSMutableDictionary new];
               [item setValue:[PREFIX_SDCARD add:outputPath] forKey:@"path"];
               [ary addObject:item];
               data[@"res"]=ary;
               callback(data);
               // Export completed, send video here, send by outputPath or NSData
               // 导出完成，在这里写上传代码，通过路径或者通过NSData上传
           } failure:^(NSString *errorMessage, NSError *error) {
               NSLog(@"视频导出失败:%@,error:%@",errorMessage, error);
           }];
 
    }];
     imagePickerVc.modalPresentationStyle=UIModalPresentationFullScreen;
//     NSMutableArray *mediaTypes = [NSMutableArray array];
     [weexInstance.viewController presentViewController:imagePickerVc animated:YES completion:nil];
}

-(void)chooseImage:(CGFloat)maxSize aspX:(CGFloat)aspX  aspY:(CGFloat)aspY count:(int)count callback:(WXModuleCallback)callback{

    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:count delegate:self];
    CGFloat width=UIApplication.sharedApplication.keyWindow.frame.size.width;
    CGFloat height=UIApplication.sharedApplication.keyWindow.frame.size.height;
    imagePickerVc.allowCrop=false;
//    imagePickerVc.cropRect=CGRectMake(0, 0, aspX, aspY);
    imagePickerVc.allowPickingVideo=NO;
       imagePickerVc.allowPickingImage = true;
     CGFloat cropViewWH = width / 3 * 2;
      
      aspY=aspY*cropViewWH/aspX;
      imagePickerVc.cropRect = CGRectMake((width - cropViewWH) / 2, (height - aspY) / 2, cropViewWH, aspY);
    
    
     [imagePickerVc setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {
         
          NSMutableDictionary *data=[NSMutableDictionary new];
          NSMutableArray *ary=[NSMutableArray new];
          __block int count=0;
          NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
          NSString *photoplus= documentPath=[documentPath add:@"photoplus"];
          if([photoplus isExist]){
              [photoplus delete];
          }
         if(aspX>0&&aspY>0){
             RSKImageCropViewController *imageCropVC = [[RSKImageCropViewController alloc] initWithImage:photos[0]];
             imageCropVC.cropMode = RSKImageCropModeCustom;
             imageCropVC.delegate = self;
             imageCropVC.dataSource = self;
//                 [self.navigationController pushViewController:imageCropVC animated:YES];
            [weexInstance.viewController presentViewController:imageCropVC animated:YES completion:nil];
//             NSString *path= [photos[0] save:[[@"photoplus/imgs/origin/" add:[[NSDate new] getCurrentTimestamp]]add:@".png"]];
//             [ary addObject:@{@"path":[PREFIX_SDCARD add:path] }];
//             callback(@{@"res":ary});
             return;
         }
       
         for(PHAsset *ps in assets){
             [[PHImageManager defaultManager] requestImageDataForAsset:ps options:nil resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                 count++;
                
                 NSMutableDictionary *item=[NSMutableDictionary new];
                  UIImage *img=[UIImage imageWithData:imageData];
                 NSString *path= [img save:[[@"photoplus/imgs/origin/" add:[[NSDate new] getCurrentTimestamp]]add:@".png"]];
                 [item setValue:[PREFIX_SDCARD add:path] forKey:@"path"];
                 if(maxSize>0){
                     NSData *tdata = [img compress:maxSize];
                     UIImage *compressImg=[UIImage imageWithData:tdata];
                     NSString *compressPath= [compressImg save:[[@"photoplus/imgs/origin/" add:[[NSDate new] getCurrentTimestamp]]add:@".png"]];
                     [item setValue:[PREFIX_SDCARD add:compressPath] forKey:@"compressPath"];
                 }
      
                 [ary addObject:item];
                 if(count==assets.count){
                     data[@"res"]=ary;
                     callback(data);
                 }
              }];
         }
     }];
     imagePickerVc.modalPresentationStyle=UIModalPresentationFullScreen;
     NSMutableArray *mediaTypes = [NSMutableArray array];
     [weexInstance.viewController presentViewController:imagePickerVc animated:YES completion:nil];
    
}

-(void)openCamera:(int)aspX aspY:(int)aspY themeColor:(NSString*)themeColor  callback:(WXModuleCallback)callback
{
      self.callback =callback;
      [self initUploader:@"#ffffff" titleColor:@"#ffffff" cancelColor:@"#ffffff"];
      [self.uploadImage setAsp:aspX aspY:aspY];
      [self.uploadImage openCamera];
}

 -(void)initUploader:(NSString*)themeColor titleColor:(NSString*)titleColor cancelColor:(NSString*)cancelColor
 {
     if(self.uploadImage==nil)
     {
         self.uploadImage=[UploadImage new];
         self.uploadImage.delegate=self;
         self.uploadImage.frame=CGRectMake(0, 0, 0, 0);
         [self.weexInstance.viewController.view addSubview: self.uploadImage];
         self.uploadImage.themeColor=[themeColor toColor];
         self.uploadImage.titleColor=[titleColor toColor];
         self.uploadImage.cancelColor=[cancelColor toColor];
     }
 }

-(void)imageSelect:(UIImage*)img
{
    if(self.maxSize>0)
    img= [UIImage  imageWithData: [img compress:self.maxSize]];
    NSString *path= [WXPhotoModule saveImageDocuments:img];
    path=[@"sdcard:" add:path];
//    NSString *encodedString = [self image2DataURL:img];
//    encodedString=[@"base64===" add:encodedString];
    NSMutableDictionary *d=[NSMutableDictionary new];
    [d setValue:path forKey:@"path"];
    NSMutableArray *ary=[NSMutableArray new];
    [ary addObject:d];
    self.callback(@{@"res":ary});
}
-(int)getData{
    return 0;
}

// Returns a custom rect for the mask.
- (CGRect)imageCropViewControllerCustomMaskRect:(RSKImageCropViewController *)controller
{
    CGSize aspectRatio = CGSizeMake(16.0f, 9.0f);
    
    CGFloat viewWidth = CGRectGetWidth(controller.view.frame);
    CGFloat viewHeight = CGRectGetHeight(controller.view.frame);
    
    CGFloat maskWidth;
    if ([controller isPortraitInterfaceOrientation]) {
        maskWidth = viewWidth;
    } else {
        maskWidth = viewHeight;
    }
    
    CGFloat maskHeight;
    do {
        maskHeight = maskWidth * aspectRatio.height / aspectRatio.width;
        maskWidth -= 1.0f;
    } while (maskHeight != floor(maskHeight));
    maskWidth += 1.0f;
    
    CGSize maskSize = CGSizeMake(maskWidth, maskHeight);
    //剪裁区域
    CGRect maskRect = CGRectMake((viewWidth - _aspX) * 0.5f,
                                 (viewHeight - _aspY) * 0.5f,
                                 _aspX,
                                 _aspY);
    return maskRect;
}

// Returns a custom path for the mask.
- (UIBezierPath *)imageCropViewControllerCustomMaskPath:(RSKImageCropViewController *)controller
{
    CGRect rect = controller.maskRect;
    CGPoint point1 = CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect));
    CGPoint point2 = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    CGPoint point3 = CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect));
    CGPoint point4 = CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect));
    
    UIBezierPath *rectangle = [UIBezierPath bezierPath];
    [rectangle moveToPoint:point1];
    [rectangle addLineToPoint:point2];
    [rectangle addLineToPoint:point3];
    [rectangle addLineToPoint:point4];
    [rectangle closePath];
    
    return rectangle;
}

// Returns a custom rect in which the image can be moved.
- (CGRect)imageCropViewControllerCustomMovementRect:(RSKImageCropViewController *)controller
{
    if (controller.rotationAngle == 0) {
        return controller.maskRect;
    } else {
        CGRect maskRect = controller.maskRect;
        CGFloat rotationAngle = controller.rotationAngle;
        
        CGRect movementRect = CGRectZero;
        
        movementRect.size.width = CGRectGetWidth(maskRect) * fabs(cos(rotationAngle)) + CGRectGetHeight(maskRect) * fabs(sin(rotationAngle));
        movementRect.size.height = CGRectGetHeight(maskRect) * fabs(cos(rotationAngle)) + CGRectGetWidth(maskRect) * fabs(sin(rotationAngle));
        
        movementRect.origin.x = CGRectGetMinX(maskRect) + (CGRectGetWidth(maskRect) - CGRectGetWidth(movementRect)) * 0.5f;
        movementRect.origin.y = CGRectGetMinY(maskRect) + (CGRectGetHeight(maskRect) - CGRectGetHeight(movementRect)) * 0.5f;
        
        movementRect.origin.x = floor(CGRectGetMinX(movementRect));
        movementRect.origin.y = floor(CGRectGetMinY(movementRect));
        movementRect = CGRectIntegral(movementRect);
        
        return movementRect;
    }
}

// Crop image has been canceled.

- (void)imageCropViewControllerDidCancelCrop:(RSKImageCropViewController *)controller
{
    [weexInstance.viewController dismissViewControllerAnimated:YES completion:nil];
}

// The original image has been cropped.

//TODO 没有执行
- (void)imageCropViewController:(RSKImageCropViewController *)controller
didCropImage:(UIImage *)croppedImage
usingCropRect:(CGRect)cropRect
{
    NSLog(@"done???");
//    self.imageView.image = croppedImage;
//    [self.navigationController popViewControllerAnimated:YES];
}

// The original image has been cropped. Additionally provides a rotation angle used to produce image.

- (void)imageCropViewController:(RSKImageCropViewController *)controller

didCropImage:(UIImage *)croppedImage

usingCropRect:(CGRect)cropRect

rotationAngle:(CGFloat)rotationAngle
{
    //确定剪裁回调
    NSString *path= [croppedImage save:[[@"photoplus/imgs/origin/" add:[[NSDate new] getCurrentTimestamp]]add:@".png"]];
    NSMutableDictionary *data=[NSMutableDictionary new];
    NSMutableDictionary *item=[NSMutableDictionary new];
    [item setValue:[PREFIX_SDCARD add:path] forKey:@"path"];
    
    NSMutableArray *ary=[NSMutableArray new];
    [ary addObject:item];
//    if(count==assets.count){
//        callback(data);
//    }
    data[@"res"]=ary;
    _returnImgPath(data);
    [weexInstance.viewController dismissViewControllerAnimated:YES completion:nil];
//    [weexInstance.viewController pop];
//self.imageView.image = croppedImage;

//[self.navigationController popViewControllerAnimated:YES];

}

// The original image will be cropped.

- (void)imageCropViewController:(RSKImageCropViewController *)controller

willCropImage:(UIImage *)originalImage
{
    NSLog(@"will");
// Use when `applyMaskToCroppedImage` set to YES.

//[SVProgressHUD show];

}
 
@end

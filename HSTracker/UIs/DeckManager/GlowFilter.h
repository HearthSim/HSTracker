//
//  GlowFilter.h
//  HSTracker
//
//  Created by Istvan Fehervari on 09/11/2016.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreImage/CoreImage.h>

@interface GlowFilter : CIFilter

@property (strong, nonatomic) CIColor *glowColor;
@property (strong, nonatomic) CIImage *inputImage;
@property (strong, nonatomic) NSNumber *inputRadius;
@property (nonatomic) CGFloat  strength;
@property (strong, nonatomic) CIVector *inputCenter;

@end

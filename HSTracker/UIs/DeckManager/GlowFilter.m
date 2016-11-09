//
//  GlowFilter.m
//  HSTracker
//
//  Created by Istvan Fehervari on 09/11/2016.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

#import "GlowFilter.h"

@implementation GlowFilter

-(id)init
{
    self = [super init];
    if (self)
    {
        _glowColor = [CIColor whiteColor];
        _strength = 0;
    }
    return self;
}

- (NSArray *)attributeKeys {
    return @[@"inputRadius", @"inputCenter", @"strength"];
}

- (CIImage *)outputImage {
    CIImage *inputImage = [self valueForKey:@"inputImage"];
    if (!inputImage)
        return nil;
    
    if (self.strength == 0.0) return inputImage;
    
    // Monochrome
    CIFilter *monochromeFilter = [CIFilter filterWithName:@"CIColorMatrix"];
    CGFloat red = self.glowColor.red;
    CGFloat green = self.glowColor.green;
    CGFloat blue = self.glowColor.blue;
    CGFloat alpha = /*self.opacity;//*/self.glowColor.alpha;
    
    [monochromeFilter setDefaults];
    [monochromeFilter setValue:[CIVector vectorWithX:0 Y:0 Z:0 W:red] forKey:@"inputRVector"];
    [monochromeFilter setValue:[CIVector vectorWithX:0 Y:0 Z:0 W:green] forKey:@"inputGVector"];
    [monochromeFilter setValue:[CIVector vectorWithX:0 Y:0 Z:0 W:blue] forKey:@"inputBVector"];
    [monochromeFilter setValue:[CIVector vectorWithX:0 Y:0 Z:0 W:alpha] forKey:@"inputAVector"];
    [monochromeFilter setValue:[CIVector vectorWithX:0 Y:0 Z:0 W:self.strength] forKey:@"inputBiasVector"];
    [monochromeFilter setValue:inputImage forKey:@"inputImage"];
    CIImage *glowImage = [monochromeFilter valueForKey:@"outputImage"];
    
    // Scale
    float centerX = [self.inputCenter X];
    float centerY = [self.inputCenter Y];
    if (centerX > 0) {
        CGAffineTransform transform = CGAffineTransformIdentity;
        transform = CGAffineTransformTranslate(transform, centerX, centerY);
        transform = CGAffineTransformScale(transform, 1.2, 1.2);
        transform = CGAffineTransformTranslate(transform, -centerX, -centerY);
        
        CIFilter *affineTransformFilter = [CIFilter filterWithName:@"CIAffineTransform"];
        [affineTransformFilter setDefaults];
        //[affineTransformFilter setValue:[NSValue valueWithCGAffineTransform:transform] forKey:@"inputTransform"]; is missing in osx, see:
        // https://openradar.appspot.com/25507932
        [affineTransformFilter setValue:[NSValue valueWithBytes:&transform objCType:@encode(CGAffineTransform)] forKey:@"inputTransform"];
        
        [affineTransformFilter setValue:glowImage forKey:@"inputImage"];
        glowImage = [affineTransformFilter valueForKey:@"outputImage"];
    }
    
    // Blur
    CIFilter *gaussianBlurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [gaussianBlurFilter setDefaults];
    [gaussianBlurFilter setValue:glowImage forKey:@"inputImage"];
    [gaussianBlurFilter setValue:self.inputRadius ?: @10.0 forKey:@"inputRadius"];
    glowImage = [gaussianBlurFilter valueForKey:@"outputImage"];
    
    // Blend
    CIFilter *blendFilter = [CIFilter filterWithName:@"CISourceOverCompositing"];
    [blendFilter setDefaults];
    [blendFilter setValue:glowImage forKey:@"inputBackgroundImage"];
    [blendFilter setValue:inputImage forKey:@"inputImage"];
    glowImage = [blendFilter valueForKey:@"outputImage"];
    
    return glowImage;
}

@end

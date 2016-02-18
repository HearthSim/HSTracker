/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 17/02/16.
 */
//
// Created by Benjamin Michotte on 17/02/16.
// Copyright (c) 2016 Benjamin Michotte. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (HSTracker)
- (BOOL)isEmpty;
- (BOOL)tryParse:(NSInteger *)out;
@end

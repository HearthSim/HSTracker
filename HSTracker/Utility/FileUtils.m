//
//  FileUtils.m
//  HSTracker
//
//  Created by Istvan Fehervari on 15/01/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

#import "FileUtils.h"
#import <libproc.h>
#import <AppKit/AppKit.h>

@implementation FileUtils

+(bool)isFileOpenByHearthstone:(NSString*)filePath {
    
    // get Hearthstone PID
    NSArray *runningApps = [[NSWorkspace sharedWorkspace] runningApplications];
    
    pid_t hsPid = 0;
    for (NSRunningApplication* nsapp in runningApps) {
        if ([[nsapp localizedName] isEqualToString:@"Hearthstone"]) {
            hsPid = [nsapp processIdentifier];
            break;
        }
    }
    
    if (hsPid == 0) return NO;
    
    int listpidspathResult = 0;
    listpidspathResult = proc_listpidspath(PROC_ALL_PIDS, 0,
                                           [filePath cStringUsingEncoding:NSUTF8StringEncoding], PROC_LISTPIDSPATH_EXCLUDE_EVTONLY, nil, 0);
    
    if (listpidspathResult <= 1) return NO;
    
    // check if really Hearthstone is writing the file and not some other process (unlikely)
    
    int pidsSize = (listpidspathResult ? listpidspathResult : 1);
    pid_t *pids = malloc(pidsSize);
    
    listpidspathResult = proc_listpidspath(PROC_ALL_PIDS, 0,
                                           [filePath cStringUsingEncoding:NSUTF8StringEncoding], PROC_LISTPIDSPATH_EXCLUDE_EVTONLY, pids,
                                           pidsSize);
    
    NSUInteger pidsCount = (listpidspathResult / sizeof(*pids));
    NSMutableSet* result = [NSMutableSet set];
    
    for (int i = 0; i < pidsCount; i++) {
        [result addObject: [NSNumber numberWithInt: pids[i]]];
        if (hsPid == pids[i]) {
            free(pids);
            return YES;
        }
    }
    
    free(pids);
    return NO;
}

@end

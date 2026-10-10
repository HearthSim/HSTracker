//
//  FileUtils.m
//  HSTracker
//
//  Created by Istvan Fehervari on 15/01/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

#import "FileUtils.h"
#import <libproc.h>
#import <sys/stat.h>
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
    
    struct stat fileStat;
    if (stat([filePath fileSystemRepresentation], &fileStat) != 0) return NO;
    
    // Only Hearthstone's own descriptors are looked at. This used to be
    // proc_listpidspath(PROC_ALL_PIDS, ...), which walks the open files of every
    // process on the machine and, called on the main thread at startup, hung
    // the app for a minute on busy machines (Sentry HSTRACKER-1QB). Matching by
    // device and inode rather than by path keeps symlinked paths matching, as
    // proc_listpidspath did.
    int bufferSize = proc_pidinfo(hsPid, PROC_PIDLISTFDS, 0, NULL, 0);
    if (bufferSize <= 0) return NO;
    
    struct proc_fdinfo *fds = malloc(bufferSize);
    if (fds == NULL) return NO;
    
    bufferSize = proc_pidinfo(hsPid, PROC_PIDLISTFDS, 0, fds, bufferSize);
    int fdCount = bufferSize > 0 ? bufferSize / PROC_PIDLISTFD_SIZE : 0;
    
    bool isOpen = NO;
    for (int i = 0; i < fdCount && !isOpen; i++) {
        if (fds[i].proc_fdtype != PROX_FDTYPE_VNODE) continue;
        
        struct vnode_fdinfowithpath vnodeInfo;
        int size = proc_pidfdinfo(hsPid, fds[i].proc_fd, PROC_PIDFDVNODEPATHINFO,
                                  &vnodeInfo, PROC_PIDFDVNODEPATHINFO_SIZE);
        if (size != PROC_PIDFDVNODEPATHINFO_SIZE) continue;
        
        struct vinfo_stat vnodeStat = vnodeInfo.pvip.vip_vi.vi_stat;
        isOpen = vnodeStat.vst_dev == fileStat.st_dev && vnodeStat.vst_ino == fileStat.st_ino;
    }
    
    free(fds);
    return isOpen;
}

@end

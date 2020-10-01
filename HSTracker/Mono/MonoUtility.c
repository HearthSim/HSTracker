//
//  MonoUtility.c
//  HSTracker
//
//  Created by Francisco Moraes on 8/19/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

#include <stdio.h>

extern void mono_jit_init (const char *file) __attribute__((weak_import));

int isMonoAvailable(void)
{
    return mono_jit_init != NULL;
}

//
//  JALLog.h
//  JALAudioSampler
//
//  Created by Jason Lew on 8/18/15.
//  Copyright (c) 2015 Jason Lew. All rights reserved.
//

#ifdef DEBUG
#   define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#   define DLog(...)
#endif

#import <Foundation/Foundation.h>

const int FREE = -1;
const int FILESIZELIMIT = 10;

// == Interfaces ==

@interface FileObj : NSObject {
    FileObj *left;
    FileObj *right;
    int fileId;
    int size;
    bool hasMoved;
}
@property (assign, readwrite) FileObj *left;
@property (assign, readwrite) FileObj *right;
@property (assign, readwrite) int fileId;
@property (assign, readwrite) int size;
@property (assign, readwrite) bool hasMoved;
- (id) init;
+ (instancetype) newFile:(int) i ofSize:(int) n;
@end

@interface FSObj : NSObject {
    FileObj *firstFile;
    FileObj *lastFile;
    NSMutableArray *freePtrs;
}
@property (assign, readwrite) FileObj *firstFile;
@property (assign, readwrite) FileObj *lastFile;
@property (assign, readwrite) NSMutableArray *freePtrs;
- (id) init;
- (void) appendFile:(int) fileId ofSize:(int) size;
- (bool) moveFileLeft:(FileObj*) f;
- (void) compact;
- (long) checksum;
+ (instancetype) create;
@end

// == Implementations ==

@implementation FileObj
@synthesize left;
@synthesize right;
@synthesize fileId;
@synthesize size;
@synthesize hasMoved;
- (id) init {
    self = [super init];
    return self;
}
+ (instancetype) newFile:(int) i ofSize:(int) n {
    FileObj *result = [[FileObj alloc] init];
    result.fileId = i;
    result.size = n;
    result.left = nil;
    result.right = nil;
    result.hasMoved = false;
    return result;
}
@end


@implementation FSObj
@synthesize firstFile;
@synthesize lastFile;
@synthesize freePtrs;
- (id) init {
    self = [super init];
    if (self) {
        firstFile = nil;
        lastFile = nil;
        freePtrs = [NSMutableArray array];
        FileObj *dummy = [FileObj newFile: FREE ofSize: 0];
        for (int i = 0; i < FILESIZELIMIT; i++) {
            [freePtrs addObject: dummy];
        }
    }
    return self;
}
- (void) appendFile:(int) fileId ofSize:(int) size {
    if (size == 0) { return; }
    FileObj *newFile = [FileObj newFile: fileId ofSize: size];
    if (fileId == FREE) {
        FileObj *dummy = [freePtrs objectAtIndex: 0];
        for (int i = 1; i <= size; i++) {
            if ([freePtrs objectAtIndex: i] == dummy) {
                [freePtrs replaceObjectAtIndex: i withObject: newFile];
            }
        }
    }
    if (!firstFile) {
        firstFile = newFile;
        lastFile = newFile;
    } else {
        [lastFile setRight: newFile];
        [newFile setLeft: lastFile];
        lastFile = newFile;
    }
    return;
}
- (bool) moveFileLeft:(FileObj *) f {
    // Don't try to move the same block twice
    if ([f hasMoved]) { return false; }

    FileObj *dest = [freePtrs objectAtIndex: [f size]];
    // Don't try to move block if there's no room for it to the left
    if (dest == [freePtrs objectAtIndex: 0]) { return false; }

    // update the "free" slot
    [dest setSize: ([dest size] - [f size])];
    // shift file to just before this "free" slot
    FileObj *newFile = [FileObj newFile: [f fileId] ofSize: [f size]];
    [newFile setHasMoved: true];
    [newFile setLeft: [dest left]];
    [newFile setRight: dest];
    [[dest left] setRight: newFile];
    [dest setLeft: newFile];
    [f setFileId: FREE];
    // Don't need to merge this with adjacent free space
    // since files can only move left and we're taking them
    // in reverse fileId order

    // update the freePtrs
    [self updateFreePtrsUntil: [f left]];
    return true;
}
- (void) compact {
    // To compact this:
    // - for each file, get the span of free memory of that file's size
    // - move the file there
    // - for each ptr whose location matches this file's location,
    //   advance it forward until it points at the right span
    for (FileObj *f = lastFile; f; f = [f left]) {
        if ([f fileId] == FREE) { continue; }
        [self moveFileLeft: f];
        [self updateFreePtrsUntil: [f left]];
        //[self logAllFiles];
    }
    // Totally optional, but leaves the FSObj in a "nicer" state
    [self cleanup];
    return;
}
- (void) cleanup {
    // Remove rightmost FREE files
    for (FileObj *p = lastFile; p && [p fileId] == FREE; p = [p left]) {
        [[p left] setRight: nil];
        lastFile = [p left];
    }

    for (FileObj *p = firstFile; p; p = [p right]) {
        // Remove empty files
        if ([p size] == 0) {
            if ([p left]) {
                [[p left] setRight: [p right]];
            }
            if ([p right]) {
                [[p right] setLeft: [p left]];
            }
            continue;
        }
        // Reset hasMoved flag
        [p setHasMoved: false];
        // Merge FREE files
        while ([p fileId] == FREE && [p right] && [[p right] fileId] == FREE) {
            [p setSize: ([p size] + [[p right] size])];
            if ([[p right] right]) {
                [[[p right] right] setLeft: p];
            }
            [p setRight: [[p right] right]];
        }
    }

    // Reset FreePtrs
    for (int i = 1; i < FILESIZELIMIT; i++) {
        [freePtrs replaceObjectAtIndex: i withObject: firstFile];
    }
    [self updateFreePtrsUntil: lastFile];
    return;
}
- (void) updateFreePtrsUntil:(FileObj *) limit {
    // FreePtrs that would go to the right of limit are set to [FreePtrs 0]
    FileObj *dummy = [freePtrs objectAtIndex: 0];
    for (int i = 1; i < FILESIZELIMIT; i++) {
        FileObj *p = [freePtrs objectAtIndex: i];
        if (p == dummy) { continue; }
        while (p && p != limit && ([p fileId] != FREE || [p size] < i)) {
            p = [p right];
        }
        if (p == limit || p == nil) { p = dummy; }
        [freePtrs replaceObjectAtIndex: i withObject: p];
    }
    return;
}
- (long) checksum {
    long total = 0;
    int fsIndex = 0;
    for (FileObj *item = firstFile; item; item = [item right]) {
        if ([item fileId] != FREE) {
            for (int j = 0; j < [item size]; j++) {
                total += ((fsIndex + j) * [item fileId]);
            }
        }
        fsIndex += [item size];
    }
    return total;
}
- (void) logAllFiles {
    for (FileObj *f = firstFile; f; f = [f right]) {
        if ([f fileId] == FREE) {
            NSLog(@"(free) size %d", [f size]);
        } else {
            NSLog(@"id=%2d  size %d", [f fileId], [f size]);
        }
    }
}
+ (instancetype) create {
    FSObj *result = [[FSObj alloc] init];
    return result;
}
@end

// == Functions ==

FSObj *dataToFileSystem1(NSConstantString *data) {
    FSObj *fs = [FSObj create];
    for (int i = 0; i < [data length]; i++) {
        char val = [data characterAtIndex: i] - '0';
        if (val >= 0 && val < FILESIZELIMIT) {
            for (char j = 0; j < val; j++) {
                [fs appendFile: (i % 2 == 0 ? (i / 2) : FREE) ofSize: 1];
            }
        }
    }
    return fs;
}

FSObj *dataToFileSystem2(NSConstantString *data) {
    FSObj *fs = [FSObj create];
    for (int i = 0; i < [data length]; i++) {
        char val = [data characterAtIndex: i] - '0';
        if (val >= 0 && val < FILESIZELIMIT) {
            [fs appendFile: ((i % 2 == 0) ? (i / 2) : FREE) ofSize: val];
        }
    }
    return fs;
}

int main(void) {
    @autoreleasepool {
        NSConstantString *fname = (NSConstantString *) @"input09.txt";
        NSConstantString *data = (NSConstantString *) [
            NSString stringWithContentsOfFile: fname
            encoding: NSUTF8StringEncoding
            error: (NSError **) nil
        ];
        @autoreleasepool {
            FSObj *fs1 = dataToFileSystem1(data);
            [fs1 compact];
            NSLog(@"%ld", [fs1 checksum]);
            // Example should give 1928.
        }
        @autoreleasepool {
            FSObj *fs2 = dataToFileSystem2(data);
            [fs2 compact];
            NSLog(@"%ld", [fs2 checksum]);
            // Example should give 2858.
        }
    }
    return 0;
}

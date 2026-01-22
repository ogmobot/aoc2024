#import <Foundation/Foundation.h>

const int FREE = -1;

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
- (bool) boolValue;
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
- (bool) boolValue {
    return true;
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
        for (int i = 0; i < 10; i++) {
            [freePtrs addObject: @false];
        }
    }
    return self;
}
- (void) appendFile:(int) fileId ofSize:(int) size {
    if (size == 0) { return; }
    FileObj *newFile = [FileObj newFile: fileId ofSize: size];
    if (fileId == FREE) {
        for (int i = 1; i <= size; i++) {
            if (![[freePtrs objectAtIndex: i] boolValue]) {
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
    //[self logAllFiles];
    //NSLog(@"==");
    return;
}
- (bool) moveFileLeft:(FileObj *) f {
    FileObj *dest = [freePtrs objectAtIndex: [f size]];
    if ([f hasMoved]) { return false; }
    if (![dest boolValue]) { return false; }
    // freePtrs become @false if they move to the right of the "working end"
    //NSLog(@"f id = %d, size = %d", [f fileId], [f size]);

    // update the "free" slot
    [dest setSize: ([dest size] - [f size])];
    // shift file
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
    return;
}
- (void) updateFreePtrsUntil:(FileObj *) limit {
    // FreePtrs that would go to the right of limit are set to @false
    for (int i = 1; i < 10; i++) {
        FileObj *p = [freePtrs objectAtIndex: i];
        if (![p boolValue]) { continue; }
        while (p && p != limit && ([p fileId] != FREE || [p size] < i)) {
            p = [p right];
        }
        if (p == limit || p == nil) { p = @false; }
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

NSMutableArray *dataToFileSystem1(NSConstantString *data) {
    // TODO use FSObj instead
    NSMutableArray *fs = [NSMutableArray array];
    for (int i = 0; i < [data length]; i++) {
        char val = [data characterAtIndex: i] - '0';
        if (val < 0 || val > 9) { continue; }
        for (char j = 0; j < val; j++) {
            [fs addObject:
                [NSNumber numberWithInt: (i % 2 == 0 ? (i / 2) : FREE)]];
        }
    }
    return fs;
}

void compactor1(NSMutableArray *fs) {
    int ptr = 0;
    while (
        ptr < [fs count]
        && [[fs objectAtIndex: ptr] intValue] != FREE
    ) {
        ptr++;
    }

    while (ptr < [fs count]) {
        if ([[fs lastObject] intValue] == FREE) {
            [fs removeLastObject];
        } else {
            [fs replaceObjectAtIndex: ptr withObject: [fs lastObject]];
            [fs removeLastObject];
            while (
                ptr < [fs count]
                && [[fs objectAtIndex: ptr] intValue] != FREE
            ) {
                ptr++;
            }
        }
    }
    return;
}

long checksum1(NSMutableArray *fs) {
    long total = 0;
    for (int i = 0; i < [fs count]; i++) {
        int item = [[fs objectAtIndex: i] intValue];
        // After compacting, there's no empty space remaining
        total += i * item;
    }
    return total;
}

FSObj *dataToFileSystem2(NSConstantString *data) {
    FSObj *fs = [FSObj create];
    for (int i = 0; i < [data length]; i++) {
        char val = [data characterAtIndex: i] - '0';
        if (val >= 0 && val <= 9) {
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
            NSMutableArray *fs1 = dataToFileSystem1(data);
            compactor1(fs1);
            NSLog(@"%ld", checksum1(fs1));
            // Example should give 1928.
        }
        @autoreleasepool {
            FSObj *fs2 = dataToFileSystem2(data);
            [fs2 compact];
            NSLog(@"%ld", [fs2 checksum]);
            // Example should give 2858.
            //[fs2 logAllFiles];
        }
    }
    return 0;
}

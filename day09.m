#import <Foundation/Foundation.h>

const int FREE = -1;

// == Interfaces ==

@interface FileObj : NSObject {
    int fileId;
    int size;
}
@property (assign, readwrite) int fileId;
@property (assign, readwrite) int size;
- (id) init;
+ (instancetype) newFile:(int) i ofSize:(int) n;
@end

@interface FSObj : NSObject {
    NSMutableArray *files;
    NSMutableArray *freePtrs;
}
@property (assign, readwrite) NSMutableArray *files;
@property (assign, readwrite) NSMutableArray *freePtrs;
- (id) init;
- (void) appendFile:(int) fileId ofSize:(int) size;
- (bool) moveFileLeft:(int) fileId;
- (long) checksum;
+ (instancetype) create;
@end

// == Implementations ==

@implementation FileObj
@synthesize fileId;
@synthesize size;
- (id) init {
    self = [super init];
    return self;
}
+ (instancetype) newFile:(int) i ofSize:(int) n {
    FileObj *result = [[FileObj alloc] init];
    result.fileId = i;
    result.size = n;
    return result;
}
@end


@implementation FSObj
@synthesize files;
@synthesize freePtrs;
- (id) init {
    self = [super init];
    if (self) {
        files = [NSMutableArray array];
        freePtrs = [NSMutableArray array];
        for (int i = 0; i < 10; i++) {
            [freePtrs addObject: @-1];
        }
    }
    return self;
}
- (void) appendFile:(int) fileId ofSize:(int) size {
    if (size == 0) { return; }
    if (fileId == FREE) {
        for (int i = 1; i <= size; i++) {
            if ([[freePtrs objectAtIndex: i] isEqual: @-1]) {
                [freePtrs
                    replaceObjectAtIndex: i
                    withObject: [NSNumber numberWithInt: [files count]]];
            }
        }
    }
    [files addObject: [FileObj newFile: fileId ofSize: size]];
    return;
}
- (bool) moveFileLeft:(int) fileId {
    // It's the caller's responsibility to ensure fileId exists!
    int fileIndex = [files count] - 1;
    for (; fileIndex >= 0; fileIndex--) {
        if ([[files objectAtIndex: fileIndex] fileId] == fileId) {
            break;
        }
    }
    const FileObj *f = [files objectAtIndex: fileIndex];
    const int newIndex = [[freePtrs objectAtIndex: [f size]] intValue];
    //NSLog(@"f id = %d, size = %d", [f fileId], [f size]);
    if (newIndex != -1 && newIndex < fileIndex) {
        // update nearby "free" slots
        FileObj *freeslot = [files objectAtIndex: newIndex];
        [freeslot setSize: ([freeslot size] - [f size])];
        // shift file
        FileObj *newFile = [FileObj newFile: [f fileId] ofSize: [f size]];
        [f setFileId: FREE];
        // Don't need to merge this with adjacent free space
        // since files can only move left and we're taking them
        // in reverse fileId order
        [files insertObject: newFile atIndex: newIndex];
        // update all freePtrs (noting the insertion that just happened
        // might mean they're off by 1)
        for (int i = 1; i < 10; i++) {
            int p = [[freePtrs objectAtIndex: i] intValue];
            while (p < [files count]
                && ([[files objectAtIndex: p] fileId] != FREE
                    || [[files objectAtIndex: p] size] < i)
            ) {
                p++;
            }
            [freePtrs
                replaceObjectAtIndex: i
                withObject: [NSNumber numberWithInt: p]];
        }
        return true;
    } else {
        return false;
    }
}
- (long) checksum {
    long total = 0;
    int fsIndex = 0;
    for (int i = 0; i < [files count]; i++) {
        const FileObj *item = [files objectAtIndex: i];
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
    for (FileObj *f in files) {
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

void compactor2(FSObj *fs) {
    // To compact this:
    // - for each file, get the span of free memory of that file's size
    // - move the file there
    // - for each ptr whose location matches this file's location,
    //   advance it forward until it points at the right span
    int idToMove = [[[fs files] lastObject] fileId];
    while (idToMove >= 0) {
        [fs moveFileLeft: idToMove];
        idToMove--;
    }
    return;
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
            compactor2(fs2);
            NSLog(@"%ld", [fs2 checksum]);
            // Example should give 2858.
            //[fs2 logAllFiles];
        }
    }
    return 0;
}

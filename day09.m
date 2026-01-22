#import <Foundation/Foundation.h>

const int EMPTY = -1;

NSMutableArray *dataToFileSystem1(NSConstantString *data) {
    NSMutableArray *fs = [NSMutableArray array];
    for (int i = 0; i < [data length]; i++) {
        char val = [data characterAtIndex: i] - '0';
        for (char j = 0; j < val; j++) {
            [fs addObject:
                [NSNumber numberWithInt: (i % 2 == 0 ? (i / 2) : EMPTY)]];
        }
    }
    return fs;
}

void compactor1(NSMutableArray *fs) {
    int ptr = 0;
    while (
        ptr < [fs count]
        && [[fs objectAtIndex: ptr] intValue] != EMPTY
    )
        ptr++;

    while (ptr < [fs count]) {
        if ([[fs lastObject] intValue] == EMPTY) {
            [fs removeLastObject];
        } else {
            [fs replaceObjectAtIndex: ptr withObject: [fs lastObject]];
            [fs removeLastObject];
            while (
                ptr < [fs count]
                && [[fs objectAtIndex: ptr] intValue] != EMPTY
            )
                ptr++;
        }
    }
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
        }
    }
    return 0;
}

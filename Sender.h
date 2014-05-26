//
//  Sender.h
//  SpeakHere
//
//  Created by ShaoLing on 5/24/14.
//
//

#import <Foundation/Foundation.h>

@interface Sender : NSObject <NSStreamDelegate>

- (void)stopSendWithStatus:(NSString *)statusString;
- (void)didStartNetworkOperation;
- (void)didStopNetworkOperation;
- (void)startSend;
- (BOOL)isSending;
- (void)cancel;

@property (nonatomic, assign, readonly ) BOOL               isSending;
@property (nonatomic, strong, readwrite) NSOutputStream *   networkStream;
@property (nonatomic, strong, readwrite) NSInputStream *    fileStream;
@property (nonatomic, assign, readonly ) uint8_t *          buffer;
@property (nonatomic, assign, readwrite) size_t             bufferOffset;
@property (nonatomic, assign, readwrite) size_t             bufferLimit;
@property (nonatomic, assign, readwrite) int                totalFrames;
@property (nonatomic, assign, readwrite) BOOL                canSendNow;
@property (nonatomic, assign, readwrite) NSMutableArray      *inBufferArray;

- (NSMutableArray *)inBufferArray;
+ (Sender *)getSharedInstance;

@end

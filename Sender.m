//
//  Sender.m
//  SpeakHere
//
//  Created by ShaoLing on 5/24/14.
//
//

#import "Sender.h"
#import "NetworkManager.h"
#import "QNetworkAdditions.h"

enum {
    kSendBufferSize = 32768
};

@interface Sender ()

@end

@implementation Sender
{
    uint8_t _buffer[kSendBufferSize];
}
@synthesize networkStream = _networkStream;
@synthesize fileStream    = _fileStream;
@synthesize bufferOffset  = _bufferOffset;
@synthesize bufferLimit   = _bufferLimit;


// Because buffer is declared as an array, you have to use a custom getter.
// A synthesised getter doesn't compile.

- (uint8_t *)buffer
{
    return self->_buffer;
}

#pragma mark * Status management

// These methods are used by the core transfer code to update the UI.



#pragma mark * Core transfer code

// This is the code that actually does the networking.

- (BOOL)isSending
{
    return (self.networkStream != nil);
}

- (void)startSend
{
    NSOutputStream *    output;
    BOOL                success;
    NSNetService *      netService;
    
    //assert(filePath != nil);
    
    assert(self.networkStream == nil);      // don't tap send twice in a row!
    //assert(self.fileStream == nil);         // ditto
    
    // Open a stream for the file we're going to send.
    
    //self.fileStream = [NSInputStream inputStreamWithFileAtPath:filePath];
    //assert(self.fileStream != nil);
    
    //[self.fileStream open];
    
    // Open a stream to the server, finding the server via Bonjour.  Then configure
    // the stream for async operation.
    
    netService = [[NSNetService alloc] initWithDomain:@"local." type:@"_x-SNSUpload._tcp." name:@"Test"];
    assert(netService != nil);
    
    // Until <rdar://problem/6868813> is fixed, we have to use our own code to open the streams
    // rather than call -[NSNetService getInputStream:outputStream:].  See the comments in
    // QNetworkAdditions.m for the details.
    
    success = [netService qNetworkAdditions_getInputStream:NULL outputStream:&output];
    assert(success);
    
    self.networkStream = output;
    self.networkStream.delegate = self;
    [self.networkStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [self.networkStream open];
    
    // Tell the UI we're sending.
    
    //[self sendDidStart];
}

- (void)stopSendWithStatus:(NSString *)statusString
{
    if (self.networkStream != nil) {
        self.networkStream.delegate = nil;
        [self.networkStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.networkStream close];
        self.networkStream = nil;
    }
    if (self.fileStream != nil) {
        [self.fileStream close];
        self.fileStream = nil;
    }
    self.bufferOffset = 0;
    self.bufferLimit  = 0;
    //[self sendDidStopWithStatus:statusString];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
// An NSStream delegate callback that's called when events happen on our
// network stream.
{
    assert(aStream == self.networkStream);
#pragma unused(aStream)
    
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            [self updateStatus:@"Opened connection"];
        } break;
        case NSStreamEventHasBytesAvailable: {
            assert(NO);     // should never happen for the output stream
        } break;
        case NSStreamEventHasSpaceAvailable: {
            [self updateStatus:@"Sending"];
            
            // If we don't have any data buffered, go read the next chunk of data.
            
            /*if (self.bufferOffset == self.bufferLimit) {
                NSInteger   bytesRead;
                
                bytesRead = [self.fileStream read:self.buffer maxLength:kSendBufferSize];
                
                if (bytesRead == -1) {
                    [self stopSendWithStatus:@"File read error"];
                } else if (bytesRead == 0) {
                    [self stopSendWithStatus:nil];
                } else {
                    self.bufferOffset = 0;
                    self.bufferLimit  = bytesRead;
                }
            }*/
            
            // If we're not out of data completely, send the next chunk.
            
            if (self.bufferOffset != self.bufferLimit) {
                NSInteger   bytesWritten;
                
                bytesWritten = [self.networkStream write:&self.buffer[self.bufferOffset] maxLength:self.bufferLimit - self.bufferOffset];
                assert(bytesWritten != 0);
                if (bytesWritten == -1) {
                    [self stopSendWithStatus:@"Network write error"];
                } else {
                    self.bufferOffset += bytesWritten;
                }
            }
        } break;
        case NSStreamEventErrorOccurred: {
            [self stopSendWithStatus:@"Stream open error"];
        } break;
        case NSStreamEventEndEncountered: {
            // ignore
        } break;
        default: {
            assert(NO);
        } break;
    }
}


- (void)didStartNetworkOperation {
    [[NetworkManager sharedInstance] didStartNetworkOperation];
}

- (void)didStopNetworkOperation {
    [[NetworkManager sharedInstance] didStopNetworkOperation];
}

#pragma mark * Actions


- (void)cancel
{
    [self stopSendWithStatus:@"Cancelled"];
}

- (void)updateStatus:(NSString *)status {
    NSLog(@"%@", status);
}


@end

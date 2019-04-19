//
//  AdminTransferMessage.m
//  SealMeeting
//
//  Created by Sin on 2019/3/14.
//  Copyright © 2019年 RongCloud. All rights reserved.
//

#import "AdminTransferMessage.h"

@implementation AdminTransferMessage
- (NSData *)encode {
    return nil;
}

- (void)decodeWithData:(NSData *)data {
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    if(dic) {
        self.operatorId = dic[@"opUserId"];
        self.toUserId = dic[@"toUserId"];
    }
}
+ (NSString *)getObjectName {
    return AdminTransferMessageIdentifier;
}
- (NSArray<NSString *> *)getSearchableWords {
    return nil;
}
+ (RCMessagePersistent)persistentFlag {
    return MessagePersistent_NONE;
}
- (NSString *)conversationDigest {
    return AdminTransferMessageIdentifier;
}
@end

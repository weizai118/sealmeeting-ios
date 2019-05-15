//
//  VideoListView.m
//  SealMeeting
//
//  Created by liyan on 2019/3/5.
//  Copyright © 2019年 RongCloud. All rights reserved.
//

#import "VideoListView.h"
#import "VideoListCell.h"
#import "ClassroomService.h"
#import "RTCService.h"

@interface VideoListView ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *videoListTableView;
@property (nonatomic, strong) NSMutableArray *videoDataSource;
@property (nonatomic, strong) dispatch_queue_t videoListQueue;

@end

@implementation VideoListView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self addSubview:self.videoListTableView];
        [self getDataSource];
        self.showAdminPrompt = NO;
        self.showSpeakerPrompt = NO;
    }
    return self;
}

- (void)getDataSource {
    //主讲人第一，自己第二
    dispatch_async(self.videoListQueue, ^{
        NSArray *tempArray = [ClassroomService sharedService].currentRoom.memberList;
        if (tempArray.count <= 0) {
            return;
        }
        NSSortDescriptor * des = [[NSSortDescriptor alloc] initWithKey:@"joinTime" ascending:YES];
        NSMutableArray *sortArray = [[tempArray sortedArrayUsingDescriptors:@[des]] mutableCopy];
        RoomMember *currentMember = [ClassroomService sharedService].currentRoom.currentMember;
//        RoomMember *speaker = [ClassroomService sharedService].currentRoom.speaker;
//        __block NSInteger speakerIdx = -1;
        __block  NSInteger meIdx = -1;
        NSMutableIndexSet *set = [[NSMutableIndexSet alloc]init];
        
        for (int i = 0; i < [sortArray count]; i++ ) {
            RoomMember *member = (RoomMember *)[sortArray objectAtIndex:i];
            if ([member.userId isEqualToString:currentMember.userId]) {
                meIdx = i;
            }
            else {
//                if (member.role == RoleSpeaker) {
//                    speakerIdx = i;
//                }
                if (member.role == RoleObserver) {
                    [set addIndex:i];//旁观者不能被任何他人看见，如果自己是旁观者自己可以看见自己
                }
            }
        }
        
        NSMutableArray *lastArray = [[NSMutableArray alloc] init];
//        if (speakerIdx >= 0) {
//            [lastArray addObject:speaker];
//            [set addIndex:speakerIdx];
//        }
        if (meIdx >= 0) {
            [lastArray addObject:currentMember];
            [set addIndex:meIdx];
        }
        if (set.count >0) {
            [sortArray removeObjectsAtIndexes:set];
        }
        [lastArray addObjectsFromArray:sortArray];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.videoDataSource = [lastArray mutableCopy];
            [self.videoListTableView reloadData];
        });
    });
    
}

- (void)updateUserVideo:(NSString *)userId {
    dispatch_async(self.videoListQueue, ^{
        for(int i=0;i<self.videoDataSource.count;i++) {
            RoomMember *member = self.videoDataSource[i];
            if([member.userId isEqualToString:userId]) {
                NSIndexPath *index = [NSIndexPath indexPathForRow:i inSection:0];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.videoListTableView reloadRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationNone];
                });
            }
        }
    });
}

- (void)reloadVideoList {
    [self getDataSource];
}

- (void)showAdminPrompt:(BOOL)showAdminPrompt showSpeakerPrompt:(BOOL)showSpeakerPrompt {
    self.showAdminPrompt = showAdminPrompt;
    self.showSpeakerPrompt = showSpeakerPrompt;
    [self reloadVideoList];
}

#pragma mark - tableViewDelegate
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * cellName = @"VideoListCell";
    VideoListCell * cell = [tableView dequeueReusableCellWithIdentifier:cellName];
    if (cell == nil) {
        cell = [[VideoListCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellName];
    }
    if (self.videoDataSource.count > 0) {
        [cell setModel:[self.videoDataSource objectAtIndex:indexPath.row] showAdminPrompt:self.showAdminPrompt showSpeakerPrompt:self.showSpeakerPrompt];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    RoomMember *mem = [self.videoDataSource objectAtIndex:indexPath.row];
    if([self.delegate respondsToSelector:@selector(videoListView:didTap:)]) {
        [self.delegate videoListView:self didTap:mem];
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.videoDataSource != nil) {
        return self.videoDataSource.count;
    }
    return 0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 94.0;
}

- (UITableView *)videoListTableView {
    if(!_videoListTableView) {
        CGSize size = self.bounds.size;
        _videoListTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height) style:UITableViewStylePlain];
        _videoListTableView.backgroundColor = [UIColor clearColor];
        _videoListTableView.delegate = self;
        _videoListTableView.dataSource = self;
        _videoListTableView.bounces = NO;
        if (@available(iOS 11.0, *)) {
            _videoListTableView.insetsContentViewsToSafeArea = NO;
        }
        _videoListTableView.separatorColor=[UIColor clearColor];
        _videoListTableView.showsVerticalScrollIndicator = NO;
        UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, 10)];
        footerView.backgroundColor = [UIColor clearColor];
        _videoListTableView.tableFooterView = footerView;
    }
    return _videoListTableView;
}

- (NSArray *)videoDataSource {
    if(!_videoDataSource) {
        _videoDataSource = [[NSMutableArray alloc] init];
    }
    return _videoDataSource;
}

- (dispatch_queue_t)videoListQueue {
    if(!_videoListQueue) {
        _videoListQueue = dispatch_queue_create("cn.rongcloud.seal.videolist", DISPATCH_QUEUE_SERIAL);
    }
    return _videoListQueue;
}
@end

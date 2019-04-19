//
//  PersonListView.m
//  SealMeeting
//
//  Created by Sin on 2019/2/28.
//  Copyright © 2019年 RongCloud. All rights reserved.
//

#import "PersonListView.h"
#import "PersonListSectionView.h"
#import "PersonListCell.h"
#import "ClassroomService.h"
#import "NormalAlertView.h"

#define RTitleViewWidth   100
#define RLeftMargin   20
#define RTableViewHeaderViewHeight   50
#define RTableViewSectionViewHeight   60

@interface PersonListView ()<UITableViewDelegate, UITableViewDataSource, PersonListSectionViewDelegate, PersonListCellDelegate>

@property (nonatomic, strong) UITableView *personListTableView;
@property (nonatomic, strong) NSMutableArray *personDataSource;
@property (nonatomic, assign) NSInteger currentSection;
@property (nonatomic, strong) dispatch_queue_t personListQueue;

@end

@implementation PersonListView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithHexString:@"131B23" alpha:0.9];
        [self addSubview:self.personListTableView];
        [self getDataSource];
        self.currentSection = -1;
        self.curMemberApplying = NO;
        
    }
    return self;
}

- (void)getDataSource {
    // 第一个是自己，第二个是主讲人，第三个是主持人
    dispatch_async(self.personListQueue, ^{
        NSArray *tempArray = [ClassroomService sharedService].currentRoom.memberList;
        if (tempArray.count <= 0) {
            return;
        }
        NSSortDescriptor * des = [[NSSortDescriptor alloc] initWithKey:@"joinTime" ascending:YES];
        NSMutableArray *sortArray = [[tempArray sortedArrayUsingDescriptors:@[des]] mutableCopy];
        RoomMember *currentMember = [ClassroomService sharedService].currentRoom.currentMember;
        __block NSInteger adminIdx = -1;
        __block NSInteger speakerIdx = -1;
        __block NSInteger meIdx = -1;
        NSMutableArray *participants = [[NSMutableArray alloc] init];
        NSMutableArray *observers = [[NSMutableArray alloc] init];
        for ( int i = 0; i < [sortArray count]; i++) {
            RoomMember *member = [sortArray objectAtIndex:i];
            if ([member.userId isEqualToString:currentMember.userId]) {
                meIdx = i;
            }else {
                switch (member.role) {
                    case RoleAdmin:
                        adminIdx = i;
                        break;
                    case RoleSpeaker:
                        speakerIdx = i;
                        break;
                    case RoleParticipant:
                        [participants addObject:member];
                        break;
                    case RoleObserver:
                        [observers addObject:member];
                        break;
                }
            }
        }
        NSMutableArray *lastArray = [[NSMutableArray alloc] init];
        if (meIdx != -1) {
            [lastArray addObject:currentMember];
        }
        if (speakerIdx != -1) {
            [lastArray addObject:[sortArray objectAtIndex:speakerIdx]];
        }
        if (adminIdx != -1) {
            [lastArray addObject:[sortArray objectAtIndex:adminIdx]];
        }
        [lastArray addObjectsFromArray:participants];
        [lastArray addObjectsFromArray:observers];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.personDataSource = lastArray;
            [self.personListTableView reloadData];
        });
    });
    
}

- (void)reloadPersonList {
    [self getDataSource];
}

- (void)reloadPersonList:(RoomMember *)member tag:(RefreshPersonListTag)tag {
    if (!member || self.personDataSource.count <= 0) {
        return;
    }
    switch (tag) {
        case RefreshPersonListTagRemove:{
            dispatch_async(self.personListQueue, ^{
                for(int i = 0;i < self.personDataSource.count; i++) {
                    RoomMember *sourceMember = self.personDataSource[i];
                    if([member.userId isEqualToString:sourceMember.userId]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.personDataSource removeObjectAtIndex:i];
                            [self.personListTableView reloadData];
                        });
                        break;
                    }
                }
            });
            
        }
            break;
        case RefreshPersonListTagRefresh: {
            dispatch_async(self.personListQueue, ^{
                for(int i = 0;i < self.personDataSource.count; i++) {
                    RoomMember *sourceMember = self.personDataSource[i];
                    if([member.userId isEqualToString:sourceMember.userId]) {
                        NSIndexSet *indexSet=[[NSIndexSet alloc] initWithIndex:i];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.personListTableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
                        });
                        break;
                    }
                }
            });
            
        }
            break;
    }
}

//申请发言
- (void)didTapApplySpearker:(PersonListSectionView *)personListSectionView {
    self.curMemberApplying = YES;
    [[ClassroomService sharedService] applyUpgrade];
}

#pragma mark - PersonListCellDelegate
- (void)PersonListCell:(PersonListCell *)cell didTapButton:(UIButton *)button {
    switch (button.tag) {
        case PersonListCellActionTagAdminTransfer:
        {
            [NormalAlertView showAlertWithTitle:NSLocalizedStringFromTable(@"ConfirmTransfer", @"SealMeeting", nil) leftTitle:NSLocalizedStringFromTable(@"Cancel", @"SealMeeting", nil) rightTitle:NSLocalizedStringFromTable(@"Confirm", @"SealMeeting", nil) cancel:^{
                
            } confirm:^{
                [[ClassroomService sharedService] transferAdmin:cell.member.userId];
            }];
            break;
        }
        case PersonListCellActionTagSetSpeaker:
        {
            [NormalAlertView showAlertWithTitle:NSLocalizedStringFromTable(@"ConfirmSetSpeaker", @"SealMeeting", nil) leftTitle:NSLocalizedStringFromTable(@"Cancel", @"SealMeeting", nil) rightTitle:NSLocalizedStringFromTable(@"Confirm", @"SealMeeting", nil) cancel:^{
                
            } confirm:^{
                [[ClassroomService sharedService] assignSpeaker:cell.member.userId];
            }];
            break;
        }
        case PersonListCellActionTagSetVoice:
        {
            if (!cell.member.microphoneEnable) {
                [NormalAlertView showAlertWithTitle:NSLocalizedStringFromTable(@"确认打开成员的麦克风吗？", @"SealMeeting", nil) leftTitle:NSLocalizedStringFromTable(@"Cancel", @"SealMeeting", nil) rightTitle:NSLocalizedStringFromTable(@"Confirm", @"SealMeeting", nil) cancel:^{
                    
                } confirm:^{
                    [[ClassroomService sharedService] enableDevice:YES type:DeviceTypeMicrophone forUser:cell.member.userId];
                }];
            }else {
                [NormalAlertView showAlertWithTitle:NSLocalizedStringFromTable(@"ConfirmProhibitMicrophone", @"SealMeeting", nil) leftTitle:NSLocalizedStringFromTable(@"Cancel", @"SealMeeting", nil) rightTitle:NSLocalizedStringFromTable(@"Confirm", @"SealMeeting", nil) cancel:^{
                    
                } confirm:^{
                    [[ClassroomService sharedService] enableDevice:NO type:DeviceTypeMicrophone forUser:cell.member.userId];
                }];
            }
        }
            break;
        case PersonListCellActionTagSetCamera:
        {
            if (!cell.member.cameraEnable) {
                [NormalAlertView showAlertWithTitle:NSLocalizedStringFromTable(@"确认打开成员的摄像头吗？", @"SealMeeting", nil) leftTitle:NSLocalizedStringFromTable(@"Cancel", @"SealMeeting", nil) rightTitle:NSLocalizedStringFromTable(@"Confirm", @"SealMeeting", nil) cancel:^{
                    
                } confirm:^{
                    [[ClassroomService sharedService] enableDevice:YES type:DeviceTypeCamera forUser:cell.member.userId];
                }];
                
            }else {
                [NormalAlertView showAlertWithTitle:NSLocalizedStringFromTable(@"ConfirmProhibitCamera", @"SealMeeting", nil) leftTitle:NSLocalizedStringFromTable(@"Cancel", @"SealMeeting", nil) rightTitle:NSLocalizedStringFromTable(@"Confirm", @"SealMeeting", nil) cancel:^{
                    
                } confirm:^{
                    [[ClassroomService sharedService] enableDevice:NO type:DeviceTypeCamera forUser:cell.member.userId];
                }];
            }
            
            break;
        }
        case PersonListCellActionTagDownGrade:
        {
            SealMeetingLog(@"cell.memberId = %@ ,cell.member.role = %lu",cell.member.userId,(unsigned long)cell.member.role);
            if (cell.member.role == RoleObserver) {
                NSArray *memberArray =  [ClassroomService sharedService].currentRoom.memberList;
                NSInteger count = 0;
                for (RoomMember *member in memberArray) {
                    if (member.role != RoleObserver) {
                        count ++;
                    }
                }
                if (count > 16) {
                    [ NormalAlertView showAlertWithTitle:NSLocalizedStringFromTable(@"Above", @"SealMeeting", nil) confirmTitle:NSLocalizedStringFromTable(@"GotIt", @"SealMeeting", nil) confirm:^{
                    }];
                }else {
                    [NormalAlertView showAlertWithTitle:NSLocalizedStringFromTable(@"UpgradeObserver", @"SealMeeting", nil) leftTitle:NSLocalizedStringFromTable(@"Cancel", @"SealMeeting", nil) rightTitle:NSLocalizedStringFromTable(@"Confirm", @"SealMeeting", nil) cancel:^{
                        
                    } confirm:^{
                        [[ClassroomService sharedService] inviteUpgrade:cell.member.userId];
                    }];
                }
            }else {
                [NormalAlertView showAlertWithTitle:NSLocalizedStringFromTable(@"ConfirmDownGrade", @"SealMeeting", nil) leftTitle:NSLocalizedStringFromTable(@"Cancel", @"SealMeeting", nil) rightTitle:NSLocalizedStringFromTable(@"Confirm", @"SealMeeting", nil) cancel:^{
                    
                } confirm:^{
                    [[ClassroomService sharedService] downgradeMembers:@[cell.member.userId]];
                }];
            }
            break;
        }
        case PersonListCellActionTagDeletelPerson:
            [NormalAlertView showAlertWithTitle:NSLocalizedStringFromTable(@"KickMember", @"SealMeeting", nil) leftTitle:NSLocalizedStringFromTable(@"Cancel", @"SealMeeting", nil) rightTitle:NSLocalizedStringFromTable(@"Confirm", @"SealMeeting", nil) cancel:^{
                
            } confirm:^{
                [[ClassroomService sharedService] kickMember:cell.member.userId];
            }];
            break;
    }
    
}

#pragma mark - PersonListSectionViewDelegate
- (void)didTapPersonListSectionView:(NSInteger)sectionTag {
    CGPoint point  = self.personListTableView.contentOffset;
    if (sectionTag == self.currentSection) {
        self.currentSection = -2;// -2 是为了标记和上次点击的是相同的 ， -1 是为了标记是第一次进入这个列表也面
    } else {
        NSMutableIndexSet *mutableIndexSet = [NSMutableIndexSet new];
        if (self.currentSection != -1 && self.currentSection != -2) {
            [mutableIndexSet addIndex:self.currentSection];
        }
        [mutableIndexSet addIndex:sectionTag];
        self.currentSection = sectionTag;
    }
    [self.personListTableView reloadData];
    if (self.currentSection < 0) {
        return;
    }
    CGRect sectionR = [self.personListTableView rectForSection:self.currentSection];
    //判断当前操作工具栏是否被遮挡，如果被遮挡，需要调整contentOffset,使其显示出来
    if(CGRectGetMaxY(sectionR) - point.y > UIScreenHeight){
        point.y += CGRectGetMaxY(sectionR) - point.y - UIScreenHeight;
    }
    [self.personListTableView setContentOffset:point animated:NO];
}

#pragma mark - tableViewDelegate
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * cellName = @"PersonListCell";
    PersonListCell * cell = [tableView dequeueReusableCellWithIdentifier:cellName];
    if (cell == nil) {
        cell = [[PersonListCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellName];
    }
    cell.delegate = self;
    if (self.personDataSource.count > 0) {
        [cell setModel: [self.personDataSource objectAtIndex:indexPath.section]];
    }
    return cell;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.personDataSource.count > 0) {
        return [self.personDataSource count];
    }
    return 0;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.currentSection == -2) {
        return 0;
    }
    if (self.currentSection == section) {
        return 1;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *view=[[UIView alloc] initWithFrame:CGRectZero];
    return view;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    PersonListSectionView *sectionView = [[PersonListSectionView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, RTableViewSectionViewHeight)];
    sectionView.delegate = self;
    sectionView.tag = section;
    if (self.personDataSource.count > 0) {
        if (section == 0) {
            [sectionView setModel:[self.personDataSource objectAtIndex:section] applySpeaking:self.curMemberApplying];
        }else{
            [sectionView setModel:[self.personDataSource objectAtIndex:section] applySpeaking:NO];
        }
    }
    return sectionView;
}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return RTableViewSectionViewHeight;
}

- (UITableView *)personListTableView {
    if(!_personListTableView) {
        CGSize size = self.bounds.size;
        _personListTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height) style:UITableViewStyleGrouped];
        _personListTableView.backgroundColor = [UIColor clearColor];
        _personListTableView.delegate = self;
        _personListTableView.dataSource = self;
        _personListTableView.bounces = NO;
        _personListTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        _personListTableView.separatorStyle=UITableViewCellSeparatorStyleNone;
        _personListTableView.estimatedRowHeight = 0;
        _personListTableView.estimatedSectionFooterHeight = 0;
        _personListTableView.estimatedSectionHeaderHeight = 0;
        if (@available(iOS 11.0, *)) {
            _personListTableView.insetsContentViewsToSafeArea = NO;
        }
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _personListTableView.bounds.size.width, RTableViewHeaderViewHeight)];
        UILabel * headerLable = [[UILabel alloc] initWithFrame:CGRectMake(RLeftMargin, 0, headerView.bounds.size.width - RLeftMargin, RTableViewHeaderViewHeight)];
        headerLable.text = NSLocalizedStringFromTable(@"OnlinePerson", @"SealMeeting", nil);
        headerLable.textColor = [UIColor colorWithHexString:@"FFFFFF" alpha:1];
        headerLable.textAlignment = NSTextAlignmentLeft;
        headerLable.font = [UIFont systemFontOfSize:16];
        [headerView addSubview:headerLable];
        _personListTableView.tableHeaderView = headerView;
        
    }
    return _personListTableView;
}

- (NSMutableArray *)personDataSource {
    if(!_personDataSource) {
        _personDataSource = [[NSMutableArray alloc] init];
    }
    return _personDataSource;
}

- (dispatch_queue_t)personListQueue {
    if(!_personListQueue) {
        _personListQueue = dispatch_queue_create("cn.rongcloud.seal.personlist", DISPATCH_QUEUE_SERIAL);
    }
    return _personListQueue;
}

@end

//
//  BMLTSendEmailViewController.m
//  BMLT
//
//  Created by Chris Marshall on 5/31/14.
//  Copyright (c) 2014 MAGSHARE. All rights reserved.
//

#import "BMLTSendEmailViewController.h"
#import "BMLTMeetingDetailViewController.h"
#import "BMLT_Meeting.h"

@interface BMLTSendEmailViewController ()

@end

@implementation BMLTSendEmailViewController

- (id)initWithController:(BMLTMeetingDetailViewController*)inController andMeeting:(BMLT_Meeting*)inMeeting
{
    self = [super init];
    
    if ( self )
        {
        _myController = inController;
        _meetingObject = inMeeting;
        }
    
    return self;
}

- (IBAction)emailSaveButtonHit:(UIButton *)inSender
{
}

- (IBAction)sendButtonHit:(UIButton *)inSender
{
}

- (IBAction)cancelButtonHit:(UIButton *)inSender
{
    [[self myController] closeModal];
}
@end

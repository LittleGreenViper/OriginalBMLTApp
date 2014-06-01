//
//  BMLTSendEmailViewController.h
//  BMLT
//
//  Created by Chris Marshall on 5/31/14.
//  Copyright (c) 2014 MAGSHARE. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BMLTMeetingDetailViewController;
@class BMLT_Meeting;

@interface BMLTSendEmailViewController : UIViewController
@property (weak, nonatomic) IBOutlet    UIView                          *emailEntrySection;
@property (weak, nonatomic) IBOutlet    UILabel                         *mainLabel;
@property (weak, nonatomic) IBOutlet    UILabel                         *nameEntryLabel;
@property (weak, nonatomic) IBOutlet    UILabel                         *emailEntryLabel;
@property (weak, nonatomic) IBOutlet    UITextField                     *enterNameTextEntry;
@property (weak, nonatomic) IBOutlet    UITextField                     *enterEmailTextEntry;
@property (weak, nonatomic) IBOutlet    UITextView                      *enterMessageTextField;
@property (weak, nonatomic) IBOutlet    UIButton                        *sendButton;
@property (weak, nonatomic) IBOutlet    UIButton                        *cancelButton;
@property (weak, nonatomic) IBOutlet    UIButton                        *saveEmailButton;
@property (weak, atomic, readwrite)     BMLTMeetingDetailViewController *myController;
@property (strong, atomic, readwrite)   BMLT_Meeting                    *meetingObject;

- (id)initWithController:(BMLTMeetingDetailViewController*)inController andMeeting:(BMLT_Meeting*)inMeeting;
- (IBAction)emailSaveButtonHit:(UIButton *)inSender;
- (IBAction)sendButtonHit:(UIButton *)inSender;
- (IBAction)cancelButtonHit:(UIButton *)inSender;
@end

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

/*****************************************************************/
/**
 \class BMLTSendEmailViewController
 \brief This handles the modal dialog that allows users to send an email to meeting list admins.
 *****************************************************************/
@interface BMLTSendEmailViewController : UIViewController<UITextViewDelegate>
@property (weak, nonatomic) IBOutlet    UIView                          *emailEntrySection;     ///< A view that contains all the email entry stuff. It can be hidden.
@property (weak, nonatomic) IBOutlet    UILabel                         *mainLabel;             ///< The label for the whole screen.
@property (weak, nonatomic) IBOutlet    UILabel                         *nameEntryLabel;        ///< The label for the email name text entry.
@property (weak, nonatomic) IBOutlet    UILabel                         *emailEntryLabel;       ///< The name for the email address text entry.
@property (weak, nonatomic) IBOutlet    UITextField                     *enterNameTextEntry;    ///< The text entry item for the email name.
@property (weak, nonatomic) IBOutlet    UITextField                     *enterEmailTextEntry;   ///< The text entry item for the email address.
@property (weak, nonatomic) IBOutlet    UITextView                      *enterMessageTextField; ///< The main message text field.
@property (weak, nonatomic) IBOutlet    UIButton                        *sendButton;            ///< The "Send Email" button.
@property (weak, nonatomic) IBOutlet    UIButton                        *cancelButton;          ///< The cancel button.
@property (weak, nonatomic) IBOutlet    UIButton                        *saveEmailButton;       ///< The "Save Email In Prefs" button.
@property (weak, atomic, readwrite)     BMLTMeetingDetailViewController *myController;          ///< The controller that invoked this.
@property (weak, atomic, readwrite)     BMLT_Meeting                    *meetingObject;         ///< The meeting object that is the subject of this message.
@property (strong, atomic, readwrite)   NSString                        *emailName;             ///< The sender's name.
@property (strong, atomic, readwrite)   NSString                        *emailAddress;          ///< The sender's email address.

- (id)initWithController:(BMLTMeetingDetailViewController*)inController andMeeting:(BMLT_Meeting*)inMeeting;
- (void)validateUI;
- (void)saveEmailInPrefs;
- (void)hideEmailEntrySection;
- (IBAction)emailNameChanged:(UITextField *)inSender;
- (IBAction)emailAddressChanged:(UITextField *)inSender;
- (IBAction)emailSaveButtonHit:(UIButton *)inSender;
- (IBAction)sendButtonHit:(UIButton *)inSender;
- (IBAction)cancelButtonHit:(UIButton *)inSender;
@end

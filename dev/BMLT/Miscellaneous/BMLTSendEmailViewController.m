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
#import "BMLT_Prefs.h"

/*****************************************************************/
/**
 \class BMLTSendEmailViewController
 \brief This handles the modal dialog that allows users to send an email to meeting list admins.
 *****************************************************************/
@implementation BMLTSendEmailViewController

/*****************************************************************/
/**
 \brief Designated Initializer
 \returns self
 *****************************************************************/
- (id)initWithController:(BMLTMeetingDetailViewController*)inController ///< The Meeting Details controller that invoked this.
              andMeeting:(BMLT_Meeting*)inMeeting                       ///< The meeting object itself.
{
    self = [super init];
    
    if ( self )
        {
        _emailAddress = [BMLT_Prefs getEmailSenderAddress];
        _emailName = [BMLT_Prefs getEmailSenderName];
        _myController = inController;
        _meetingObject = inMeeting;
        }
    
    return self;
}

/*****************************************************************/
/**
 \brief Checks the values of things, and changes the UI accordingly.
 *****************************************************************/
- (void)validateUI
{
    [[self mainLabel] setText:NSLocalizedString ( @"SEND-COMMENT-SCREEN-TITLE", nil )];
    [[self cancelButton] setTitle:NSLocalizedString ( @"SEND-COMMENT-SCREEN-CANCEL-BUTTON", nil ) forState:UIControlStateNormal];
    [[self sendButton] setTitle:NSLocalizedString ( @"SEND-COMMENT-SCREEN-SEND-BUTTON", nil ) forState:UIControlStateNormal];
    [[self nameEntryLabel] setText:NSLocalizedString ( @"SEND-COMMENT-SCREEN-FROM-NAME-TITLE", nil )];
    [[self emailEntryLabel] setText:NSLocalizedString ( @"SEND-COMMENT-SCREEN-FROM-EMAIL-TITLE", nil )];
    
    if ( [BMLT_Prefs isValidEmailAddress:[self emailAddress]] )
        {
        [[self sendButton] setEnabled:(0 < [[[self enterMessageTextField] text] length])];
        [[self saveEmailButton] setEnabled:YES];
        [[self saveEmailButton] setTitle:NSLocalizedString ( @"SEND-COMMENT-SCREEN-KEEP-EMAIL-TITLE", nil ) forState:UIControlStateNormal];
        }
    else
        {
        [[self sendButton] setEnabled:NO];
        [[self saveEmailButton] setEnabled:NO];
        [[self saveEmailButton] setTitle:NSLocalizedString ( @"SEND-COMMENT-SCREEN-INVALID-EMAIL", nil ) forState:UIControlStateNormal];
        }
}

/*****************************************************************/
/**
 \brief Actually saves the email in the persistent preferences.
 *****************************************************************/
- (void)saveEmailInPrefs
{
    [[BMLT_Prefs getBMLT_Prefs] setEmailSenderName:[[self enterNameTextEntry] text]];
    [[BMLT_Prefs getBMLT_Prefs] setEmailSenderAddress:[[self enterEmailTextEntry] text]];
    [BMLT_Prefs saveChanges];
    [self hideEmailEntrySection];
}

/*****************************************************************/
/**
 \brief Hides the email entry section.
 */
- (void)hideEmailEntrySection
{
    if ( [BMLT_Prefs isValidEmailAddress:[self emailAddress]] )
        {
        [[self emailEntrySection] setHidden:YES];
        CGRect  topFrame = [[self mainLabel] frame];
        CGRect  bottomFrame = [[self enterMessageTextField] frame];
        CGFloat delta = bottomFrame.origin.y - (topFrame.origin.y + topFrame.size.height);
        bottomFrame.origin.y -= delta;
        bottomFrame.size.height += delta;
        [[self enterMessageTextField] setFrame:bottomFrame];
        }

    [self validateUI];
}

/*****************************************************************/
/**
 \brief Called when text is changed in the email name text item.
 *****************************************************************/
- (IBAction)emailNameChanged:(UITextField *)inSender
{
    [self setEmailName:[inSender text]];
}

/*****************************************************************/
/**
 \brief Called when text is changed in the email address text item.
 *****************************************************************/
- (IBAction)emailAddressChanged:(UITextField *)inSender
{
    [self setEmailAddress:[inSender text]];
    [self validateUI];
}

/*****************************************************************/
/**
 \brief Called when the "Save Email" button is hit.
 *****************************************************************/
- (IBAction)emailSaveButtonHit:(UIButton *)inSender ///< The button that invoked this.
{
    [self saveEmailInPrefs];
    [self validateUI];
}

/*****************************************************************/
/**
 \brief Called when the "Send Email" button is hit.
 *****************************************************************/
- (IBAction)sendButtonHit:(UIButton *)inSender  ///< The button that invoked this.
{
    [[self myController] closeModal];
}

/*****************************************************************/
/**
 \brief Called when the "Cancel" button is hit.
 *****************************************************************/
- (IBAction)cancelButtonHit:(UIButton *)inSender    ///< The button that invoked this.
{
    [[self myController] closeModal];
}

#pragma mark - Superclass Overload Functions -

/*****************************************************************/
/**
 \brief Called when the view has finished loading.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self hideEmailEntrySection];
    [self validateUI];
}

#pragma mark - UITextViewDelegate Functions -

- (void)textViewDidChange:(UITextView *)inTextView
{
    [self validateUI];
}
@end

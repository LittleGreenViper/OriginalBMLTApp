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

static const    float           sSendEmailURLRequestTimeout = 3.0;  ///< The timeout (in seconds), of the email send.

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
        [[self enterMessageTextField] resignFirstResponder];
        [[self emailEntrySection] setHidden:YES];
        CGRect  topFrame = [[self buttonSection] frame];
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
 \brief Actually sends the email to the server.
 */
- (BOOL)sendEmail
{
    BOOL        ret = NO;
    NSString    *resultAlertString = NSLocalizedString ( @"SEND-COMMENT-SCREEN-RESULT-UH-OH", nil );
    
    // Have to have a valid email address and some text to send.
    if ( [BMLT_Prefs isValidEmailAddress:[self emailAddress]] && (0 < [[[self enterMessageTextField] text] length]) )
        {
        NSString        *serverURI = [NSString stringWithFormat:@"%@/client_interface/contact.php", [[BMLTVariantDefs rootServerURI] absoluteString]];
        serverURI = [serverURI stringByAppendingFormat:@"?meeting_id=%d&service_body_id=%d",
                     [[self meetingObject] getMeetingID],
                     [[self meetingObject] getServiceBodyID]
                     ];
        
        NSString    *fromAddress = [self emailName];
        
        if ( 0 < [fromAddress length] )
            {
            fromAddress = [NSString stringWithFormat:@"\"%@\" <%@>", fromAddress, [self emailAddress]];
            }
        else
            {
            fromAddress = [self emailAddress];
            }
        
        serverURI = [serverURI stringByAppendingFormat:@"&from_address=%@&message=%@", [BMLT_Prefs getURLEncodedString:fromAddress], [BMLT_Prefs getURLEncodedString:[[self enterMessageTextField] text]]];

#ifdef DEBUG
        NSLog ( @"Sending this email: %@", serverURI );
#endif
        
        NSURLRequest    *emailURLRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:serverURI] cachePolicy:NSURLRequestReloadRevalidatingCacheData timeoutInterval:sSendEmailURLRequestTimeout];
        
        if ( emailURLRequest )
            {
            NSURLResponse   *pResponse;
            NSError         *pError;
            NSData          *pResponseData = [NSURLConnection sendSynchronousRequest:emailURLRequest returningResponse:&pResponse error:&pError];
            
            if ( pResponseData && !pError )
                {
                const unsigned char *pdata = [pResponseData bytes];
                
                if ( 2 <= [pResponseData length] )
                    {
                    BOOL    neg = NO;
                    if ( '-' == *pdata )
                        {
                        neg = YES;
                        pdata++;
                        }
                    
                    char value = *pdata - '0';
                    
                    if ( neg )
                        {
                        value = -value;
                        }
                    
                    switch ( value )
                        {
                        case 1:
                            resultAlertString = NSLocalizedString ( @"SEND-COMMENT-SCREEN-RESULT-OK", nil );
                            ret = YES;
                            break;
                            
                        case 0:
                            resultAlertString = NSLocalizedString ( @"SEND-COMMENT-SCREEN-RESULT-NOPE", nil );
                            break;
                            
                        case -1:
                            resultAlertString = NSLocalizedString ( @"SEND-COMMENT-SCREEN-RESULT-NONE", nil );
                            break;
                        
                        case -2:
                            resultAlertString = NSLocalizedString ( @"SEND-COMMENT-SCREEN-RESULT-BAD-EMAIL", nil );
                            break;
                            
                        case -3:
                            resultAlertString = NSLocalizedString ( @"SEND-COMMENT-SCREEN-RESULT-VIKING", nil );
                            break;
                            
                        default:
                            break;
                        }
                    }
                }
            }
        }
    
    UIAlertView *myAlert = [[UIAlertView alloc] initWithTitle:((YES == ret) ? resultAlertString : NSLocalizedString ( @"SEND-COMMENT-ERROR", nil)) message:(YES == ret) ? @"" : resultAlertString delegate:nil cancelButtonTitle:NSLocalizedString ( @"OK-BUTTON",nil ) otherButtonTitles:nil];
    
    [myAlert show];

    return ret;
}

#pragma mark - IB Actions -

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
    [[self enterNameTextEntry] resignFirstResponder];
    [[self enterEmailTextEntry] resignFirstResponder];
    [[self enterMessageTextField] resignFirstResponder];
    [self validateUI];
}

/*****************************************************************/
/**
 \brief Called when the "Send Email" button is hit.
 *****************************************************************/
- (IBAction)sendButtonHit:(UIButton *)inSender  ///< The button that invoked this.
{
    [[self enterNameTextEntry] resignFirstResponder];
    [[self enterEmailTextEntry] resignFirstResponder];
    [[self enterMessageTextField] resignFirstResponder];
    [self sendEmail];
    [[self myController] closeModal];
}

/*****************************************************************/
/**
 \brief Called when the "Cancel" button is hit.
 *****************************************************************/
- (IBAction)cancelButtonHit:(UIButton *)inSender    ///< The button that invoked this.
{
    [[self enterNameTextEntry] resignFirstResponder];
    [[self enterEmailTextEntry] resignFirstResponder];
    [[self enterMessageTextField] resignFirstResponder];
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

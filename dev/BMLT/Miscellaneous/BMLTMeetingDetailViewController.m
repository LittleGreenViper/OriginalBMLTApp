//
//  BMLTMeetingDetailViewController.m
//  BMLT
//
//  Created by MAGSHARE on 8/13/11.
//  Copyright 2011 MAGSHARE. All rights reserved.
//
//  This is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//  
//  BMLT is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//  
//  You should have received a copy of the GNU General Public License
//  along with this code.  If not, see <http://www.gnu.org/licenses/>.
//

#import "BMLT_Results_MapPointAnnotationView.h"
#import "BMLTMeetingDetailViewController.h"
#import "BMLT_Meeting.h"
#import "BMLT_Format.h"
#import "BMLTAppDelegate.h"
#import "BMLT_DetailsPrintPageRenderer.h"
#import "BMLTSendEmailViewController.h"

@interface BMLTMeetingDetailViewController ()
@property (strong, atomic)  UIBarButtonItem *_toggleButton;
@end

@implementation BMLTMeetingDetailViewController
@synthesize addressButton;
@synthesize commentsTextView;
@synthesize frequencyTextView;
@synthesize formatsContainerView;
@synthesize meetingMapView, myMeeting = _myMeeting;
@synthesize myModalController;
@synthesize meetingNameLabel;
@synthesize _toggleButton;

static int List_Meeting_Format_Circle_Size_Big = 30;
static int Detail_Meeting_AddressFontSize = 13;

static const    NSInteger   sActionButtonIndex_SendEmail    = 0;    ///< This is the action button index for the "Send Comment" button.
static const    NSInteger   sActionButtonIndex_PrintScreen  = 1;    ///< This is the action button index for the "Print Screen" button

#pragma mark - View lifecycle

/*****************************************************************/
/**
 \brief Sets up the view, with all its parts.
 *****************************************************************/
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ( ![[[self navigationController] navigationBar] respondsToSelector:@selector(setBarTintColor:)] )
        {
        [[[self navigationController] navigationBar] setTintColor:[[[self view] window] backgroundColor]];
        [[[self navigationItem] rightBarButtonItem] setTintColor:nil];
        }
    
    [[self navigationItem] setTitle:NSLocalizedString(@"MEETING-DETAILS", nil)];
    [[[self navigationItem] titleView] sizeToFit];
    
    [[self meetingNameLabel] setText:[_myMeeting getBMLTName]];
    UIBarButtonItem *theButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionItemClicked:)];
    // iPad has enough room for us to add a "Directions" button.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
        UIBarButtonItem *dirButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"DIRECTIONS-BUTTON-TITLE",nil) style:UIBarButtonItemStylePlain target:self action:@selector(callForDirections:)];
            
        NSArray *buttons = [NSArray arrayWithObjects:theButton, dirButton, nil];
        [[self navigationItem] setRightBarButtonItems:buttons];
        }
    else    // iPhone does not.
        {
        [[self navigationItem] setRightBarButtonItem:theButton];
        }
    
    [self setMeetingFrequencyText];
    
    CGRect  address_frame = [addressButton frame];
    CGRect  map_frame = CGRectZero;
    map_frame.size.width = [self.view bounds].size.width;
    
    if ( [_myMeeting getBMLTDescription] )
        {
        [commentsTextView setHidden:NO];
        [self setMeetingCommentsText];
        CGRect  comments_frame = [commentsTextView frame];
        map_frame.origin.y = comments_frame.origin.y + comments_frame.size.height;
        }
    else
        {
        [commentsTextView setHidden:YES];
        CGRect  frequency_frame = [frequencyTextView frame];
        map_frame.origin.y = frequency_frame.origin.y + frequency_frame.size.height;
        }

    map_frame.size.height = address_frame.origin.y - map_frame.origin.y;
    [[self meetingMapView] setFrame:map_frame];
    
    if ( [self directionsButton] )  // Some variants may have an additional button for directions.
        {
        [[self directionsButton] setTitle:NSLocalizedString(@"DIRECTIONS-BUTTON-TITLE",nil) forState:UIControlStateNormal];
        }
    
    [self setMeetingLocationText];
    [self setFormats];
    [self addToggleMapButton];
    [[BMLTAppDelegate getBMLTAppDelegate] toggleThisMapView:[self meetingMapView] fromThisButton:nil];
}

/*****************************************************************/
/**
 \brief  This just makes sure that the print popover goes away.
 *****************************************************************/
- (void)viewWillDisappear:(BOOL)animated
{
    [[UIPrintInteractionController sharedPrintController] dismissAnimated:YES];    
}

#pragma mark - Custom Functions -

/*****************************************************************/
/**
 \brief  This adds the map toggle button to the navbar.
 *****************************************************************/
- (void)addToggleMapButton
{
    if ( YES )
        {
        NSMutableArray  *buttons = [[NSMutableArray alloc]initWithArray:[[self navigationItem] rightBarButtonItems]];
        [buttons removeObject:[self _toggleButton]];
    
        NSString    *label = NSLocalizedString ( ([[BMLTAppDelegate getBMLTAppDelegate] mapType] == MKMapTypeStandard ? @"TOGGLE-MAP-LABEL-SATELLITE" : @"TOGGLE-MAP-LABEL-MAP" ), nil);
    
        if ( ![self _toggleButton] )
            {
            [self set_toggleButton:[[UIBarButtonItem alloc] initWithTitle:label style:UIBarButtonItemStylePlain target:self action:@selector(toggleMapView:)]];
            }
        else
            {
            [[self _toggleButton] setTitle:label];
            }
            
        UIBarButtonItem *flexibleSpace1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        UIBarButtonItem *flexibleSpace2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
        [buttons addObject:flexibleSpace1];
        [buttons addObject:[self _toggleButton]];
        [buttons addObject:flexibleSpace2];
    
        [[self navigationItem] setRightBarButtonItems:buttons animated:NO];
        }
}

/*****************************************************************/
/**
 \brief Set up the display of the format circles.
 *****************************************************************/
- (void)setFormats
{
    NSArray *formats = [_myMeeting getFormats];
    
    for ( UIView *subView in [formatsContainerView subviews] )
        {
        [subView removeFromSuperview];
        }
    
    if ( [formats count] )
        {
        CGRect  formatsBounds = [formatsContainerView frame];
        formatsBounds.size.width = 0;
        
        CGRect  boundsRect = [formatsContainerView bounds];
        
        boundsRect.origin = CGPointZero;
        boundsRect.size.width = boundsRect.size.height = (List_Meeting_Format_Circle_Size_Big);
        boundsRect.origin.y = (formatsBounds.size.height - boundsRect.size.height) / 2;
        
        for ( BMLT_Format *format in formats )
            {
            BMLT_FormatButton   *newButton = [[BMLT_FormatButton alloc] initWithFrame:boundsRect andFormat:format];
            
            if ( newButton )
                {
                [newButton addTarget:[self myModalController] action:@selector(displayFormatDetail:) forControlEvents:UIControlEventTouchUpInside];
                [formatsContainerView addSubview:newButton];
                }
            
            newButton = nil;

            formatsBounds.size.width += boundsRect.size.width + List_Meeting_Format_Line_Padding;
            boundsRect.origin.x += boundsRect.size.width + List_Meeting_Format_Line_Padding;
            }

        formatsBounds.size.width -= List_Meeting_Format_Line_Padding;
        boundsRect = [[self view] bounds];
        formatsBounds.origin.x = (boundsRect.size.width - formatsBounds.size.width) / 2;
        [formatsContainerView setFrame:formatsBounds];
        }
}

/*****************************************************************/
/**
 \brief Set up the display of the text as to when and how long the meeting meets.
 *****************************************************************/
- (void)setMeetingFrequencyText
{
    NSDate              *startTime = [_myMeeting getStartTime];
    NSString            *time = [NSDateFormatter localizedStringFromDate:startTime dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
    NSDateComponents    *dateComp = [[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian] components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:startTime];
    
    if ( [dateComp hour] >= 23 && [dateComp minute] > 45 )
        {
        time = nil;
        time = NSLocalizedString(@"TIME-MIDNIGHT", nil);
        }
    else if ( [dateComp hour] == 12 && [dateComp minute] == 0 )
        {
        time = nil;
        time = NSLocalizedString(@"TIME-NOON", nil);
        }
    
    [frequencyTextView setText:[NSString stringWithFormat:NSLocalizedString ( @"MEETING-DETAILS-FREQUENCY-FORMAT", nil ), [_myMeeting getWeekday], time]];
}

/*****************************************************************/
/**
 \brief Display the comments for the meeting.
 *****************************************************************/
- (void)setMeetingCommentsText
{
    [commentsTextView setText:[_myMeeting getBMLTDescription]];
}

/*****************************************************************/
/**
 \brief Creates and displays a location string, based on the location coordinates of the meeting.
 *****************************************************************/
- (void)setMeetingLocationText
{
    NSString    *townAndState = nil;
    
    if ( [_myMeeting getValueFromField:@"location_city_subsection"] || [_myMeeting getValueFromField:@"location_municipality"] )
        {
        townAndState = ([_myMeeting getValueFromField:@"location_city_subsection"]) ? (NSString *)[_myMeeting getValueFromField:@"location_city_subsection"] : (NSString *)[_myMeeting getValueFromField:@"location_municipality"];
        }
    
    if ([_myMeeting getValueFromField:@"location_province"])
        {
        townAndState = (nil != townAndState) ? [townAndState stringByAppendingFormat:@", %@", (NSString *)[_myMeeting getValueFromField:@"location_province"]] : (NSString *)[_myMeeting getValueFromField:@"location_province"];
        }
    
    NSString    *meetingLocationString = nil;
    
    if ( [_myMeeting getValueFromField:@"location_text"] || [_myMeeting getValueFromField:@"location_street"] )
        {
        meetingLocationString = [NSString stringWithFormat:@"%@%@", (([_myMeeting getValueFromField:@"location_text"]) ? [NSString stringWithFormat:@"%@, ", (NSString *)[_myMeeting getValueFromField:@"location_text"]] : @""), [_myMeeting getValueFromField:@"location_street"]];
        }
    
    NSString    *theAddress = @"";
    
    if ( meetingLocationString && townAndState )
        {
        theAddress = [NSString stringWithFormat:@"%@, %@", meetingLocationString, townAndState];
        }
    else if ( meetingLocationString )
        {
        theAddress = meetingLocationString;
        }
    else if ( townAndState )
        {
        theAddress = townAndState;
        }
    
    [addressButton setTitle:theAddress forState:UIControlStateNormal];
    
    [[addressButton titleLabel] setFont:[UIFont systemFontOfSize:Detail_Meeting_AddressFontSize]];
}

/*****************************************************************/
/**
 \brief Sets up the location of the meeting on the map view.
 *****************************************************************/
- (void)setMapLocation
{
    CLLocationCoordinate2D  center = [[_myMeeting getMeetingLocationCoords] coordinate];
    CLLocationDistance      distance = [NSLocalizedString(@"INITIAL-PROJECTION", nil) doubleValue] * 10.0;

    // If the meeting doesn't yet have its marker, it needs setting up.
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance ( center, distance, distance );
    
    if ( ![[meetingMapView annotations] count] )
        {
        if ( [BMLTVariantDefs meetingDetailBackgroundColor] )
            {
            [[self view] setBackgroundColor:[BMLTVariantDefs meetingDetailBackgroundColor]];    // This is here to make sure it's only called once.
            }
        
        BMLT_Results_MapPointAnnotation *marker = [[BMLT_Results_MapPointAnnotation alloc] initWithCoordinate:[[_myMeeting getMeetingLocationCoords] coordinate] andMeetings:nil andIndex:0];
        
        [meetingMapView addAnnotation:marker];
        [meetingMapView setDelegate:self];
        }
    else
        {
        [[[meetingMapView annotations] objectAtIndex:0] setCoordinate:[[_myMeeting getMeetingLocationCoords] coordinate]];
        [meetingMapView setCenterCoordinate:[[_myMeeting getMeetingLocationCoords] coordinate] animated:NO];
        }
    
    [meetingMapView setRegion:region animated:NO];
}

/*****************************************************************/
/**
 \brief Displays the email comment screen.
 *****************************************************************/
- (void)displayCommentScreen
{
#ifdef DEBUG
    NSLog ( @"Send Comment Button Pressed." );
#endif
    
    [self presentViewController:[[BMLTSendEmailViewController alloc] initWithController:self andMeeting:[self myMeeting]] animated:YES completion:nil];
}

/*****************************************************************/
/**
 \brief Prints the view displayed on the screen.
 *****************************************************************/
- (void)printView
{
#ifdef DEBUG
    NSLog(@"BMLTMeetingDetailViewController::printView");
#endif
    printModal = [UIPrintInteractionController sharedPrintController];
    
    if ( printModal )
        {
        [printModal setPrintPageRenderer:[self getMyPageRenderer]];
        [printModal setPrintFormatter:[[self view] viewPrintFormatter]];
        if ( [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad )
            {
            [printModal presentFromBarButtonItem:[[self navigationItem] rightBarButtonItem] animated:YES completionHandler:
#ifdef DEBUG
             ^(UIPrintInteractionController *printInteractionController, BOOL completed, NSError *error) {
                 if (!completed)
                     {
                     NSLog(@"BMLTMeetingDetailViewController::printView completionHandler: Print FAIL");
                     }
                 else
                     {
                     NSLog(@"BMLTMeetingDetailViewController::printView completionHandler: Print WIN");
                     }
             }
#else
             nil
#endif
             ];
            }
        else
            {
            [printModal presentAnimated:YES completionHandler:
#ifdef DEBUG
             ^(UIPrintInteractionController *printInteractionController, BOOL completed, NSError *error) {
                 if (!completed)
                     {
                     NSLog(@"BMLTMeetingDetailViewController::printView completionHandler: Print FAIL");
                     }
                 else
                     {
                     NSLog(@"BMLTMeetingDetailViewController::printView completionHandler: Print WIN");
                     }
             }
#else
             nil
#endif
             ];
            }
        }
}

/*****************************************************************/
/**
 \brief Called when the "Action Item" in the NavBar is clicked.
 *****************************************************************/
- (IBAction)actionItemClicked:(id)sender
{
#ifdef DEBUG
    NSLog(@"A_BMLTSearchResultsViewController::actionItemClicked:");
#endif
    // If the server is able to send emails to the Meeting List Administrator, we give choices.
    if ( [[BMLTAppDelegate getBMLTAppDelegate] hostHasEmailContactCapability] )
        {
        UIActionSheet *actionChoice = [[UIActionSheet alloc] initWithTitle:NSLocalizedString ( @"DETAIL-ACTION-BUTTON-POPUP-TITLE", nil )
                                                                  delegate:self
                                                         cancelButtonTitle:NSLocalizedString ( @"DETAIL-ACTION-BUTTON-POPUP-CANCEL", nil )
                                                    destructiveButtonTitle:nil
                                                         otherButtonTitles: NSLocalizedString ( @"DETAIL-ACTION-BUTTON-POPUP-CHOICE-1", nil ), NSLocalizedString ( @"DETAIL-ACTION-BUTTON-POPUP-CHOICE-2", nil ), nil
                                ];
        [actionChoice showInView:[[UIApplication sharedApplication] keyWindow]];
        }
    else    // Otherwise, it's just the printer.
        {
        [self printView];
        }
}

/*****************************************************************/
/**
 \brief This toggles the map view between map and satellite.
 *****************************************************************/
- (IBAction)toggleMapView:(id)sender
{
    [[BMLTAppDelegate getBMLTAppDelegate] toggleThisMapView:[self meetingMapView] fromThisButton:[self _toggleButton]];
}

/*****************************************************************/
/**
 \brief This is called to dismiss the modal dialog or popover.
 *****************************************************************/
- (void)closeModal
{
    if (actionPopover)
        {
        [actionPopover dismissPopoverAnimated:YES];
        }
    else
        {
        [self dismissViewControllerAnimated:YES completion:nil];
        }
    
    myModalController = nil;
    actionPopover = nil;
    printModal = nil;
}

/*****************************************************************/
/**
 \brief Instantiates and returns the appropriate page renderer
 \returns an instance of BMLT_DetailsPrintPageRenderer, disguised as a UIPrintPageRenderer
 *****************************************************************/
- (UIPrintPageRenderer *)getMyPageRenderer
{
    return [[BMLT_DetailsPrintPageRenderer alloc] initWithMeetings:[NSArray arrayWithObject:[self myMeeting]] andMapFormatter:[[self meetingMapView] viewPrintFormatter]];
}

#pragma mark - MkMapAnnotationDelegate Functions -

/*****************************************************************/
/**
 \brief Returns the view for the marker in the center of the map.
 \returns an annotation view, representing the marker.
 *****************************************************************/
- (MKAnnotationView *)mapView:(MKMapView *)mapView              ///< The map view
            viewForAnnotation:(id < MKAnnotation >)annotation   ///< The annotation C, in need of a V
{
    MKAnnotationView* ret = [mapView dequeueReusableAnnotationViewWithIdentifier:@"single_meeting_annotation"];
    
    if ( !ret )
        {
        ret = [[BMLT_Results_BlackAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"single_meeting_annotation"];
        [ret setDraggable:NO];
        }
    
    return ret;
}

/*****************************************************************/
/**
 \brief This will use the Web browser to get directions to the
        meeting from the user's current location.
 *****************************************************************/
- (IBAction)callForDirections:(id)sender    ///< The button we use for this URI.
{
    [[BMLTAppDelegate getBMLTAppDelegate] imVisitingRelatives];
    
    CLLocationCoordinate2D  meetingLocation = [_myMeeting getMeetingLocationCoords].coordinate;
    NSURL                   *helpfulGasStationAttendant = [BMLTVariantDefs directionsURITo:meetingLocation];
    
    [[UIApplication sharedApplication] openURL:helpfulGasStationAttendant];
}

#pragma mark - UIActionSheetDelegate Functions -

/*****************************************************************/
/**
 \brief This handles dispatching the action selection popup.
 *****************************************************************/
- (void)actionSheet:(UIActionSheet *)inPopup     ///< The UIActionSheet popup.
clickedButtonAtIndex:(NSInteger)inButtonIndex   ///< The index of the selected button.
{
    switch ( inButtonIndex )
    {
        case sActionButtonIndex_SendEmail:
            [self displayCommentScreen];
            break;
        
        case sActionButtonIndex_PrintScreen:
            [self printView];
            break;
        
        default:
            break;
    }
}
@end

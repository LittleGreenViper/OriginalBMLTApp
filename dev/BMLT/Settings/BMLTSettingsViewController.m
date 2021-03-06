//
//  BMLTSettingsViewController.m
//  BMLT
//
//  Created by MAGSHARE.
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

#import "BMLTSettingsViewController.h"
#import "BMLT_Prefs.h"
#import "BMLTAppDelegate.h"
#import "BMLTAboutViewController.h"

static int _LOG_MIN = 5;       /**< The number of meetings in a search test for the Min level of the slider. */
static int _LOG_MAX = 20;      /**< The number of meetings for the Max level of the slider. */

/*****************************************************************/
/**
 \class  BMLTSnappyLogSlider
 \brief  This is a very simple overload of UISlider to make "detents."
         It also assumes the slider is base-10 logarithmic.
 *****************************************************************/
@implementation BMLTSnappyLogSlider

/*****************************************************************/
/**
 \brief This looks for the nearest integer value (after the log),
        and "snaps" the slider to it.
        This works by intercepting the floating-point input, then
        seeing whether the nearest integer value is closer above or
        below it, then returns a value to the superclass for that
        integer value.
        Since this is a logarithmic slider, with integer "detents,"
        we use base-10 pow to expand the value.
 *****************************************************************/
- (void)setValue:(float)value       ///< The value to set to the slider.
        animated:(BOOL)animated     ///< Whether or not to animate the value setting.
{
    float   powVal = powf(10, value);
    
    [super setValue:log10f((ceilf(powVal) - powVal) < (powVal - floorf(powVal)) ? ceilf (powVal) : floorf(powVal)) animated:animated];
}
@end

/*****************************************************************/
/**
 \class  BMLTSettingsViewController  -Implementation
 \brief  Allows the user to change the settings/preferences.
 *****************************************************************/
@implementation BMLTSettingsViewController

@synthesize lookupLocationLabel;
@synthesize lookUpLocationSwitch;
@synthesize keepUpdatingLabel;
@synthesize keepUpdatingSwitch;
@synthesize retainStateLabel;
@synthesize retainStateSwitch;
@synthesize mapResultsLabel;
@synthesize mapResultsSwitch;
@synthesize distanceSortLabel;
@synthesize distanceSortSwitch;
@synthesize preferredSearchTypeLabel;
@synthesize preferredSearchTypeControl;
@synthesize numMeetingsLabel;
@synthesize numMeetingsSlider;
@synthesize minLabel;
@synthesize updateLocationButton;
@synthesize maxLabel;
@synthesize aboutView;
@synthesize myAboutViewController;

/*****************************************************************/
/**
 \brief This is called before the view appears.
 *****************************************************************/
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ( [[BMLTAppDelegate getBMLTAppDelegate] hostHasEmailContactCapability] && [BMLT_Prefs isValidEmailAddress:[[BMLT_Prefs getBMLT_Prefs] emailSenderAddress]] )
        {
        [[self forgetEmailButton] setHidden:NO];
        }
    else
        {
        // We do this to avoid trashing someone's saved address if the server is temporarily down.
        if ( [BMLT_Prefs isValidEmailAddress:[[BMLT_Prefs getBMLT_Prefs] emailSenderAddress]] )
            {
            [self forgetEmailHit:nil];
            }
        else
            {
            [[self forgetEmailButton] setHidden:YES];
            }
        }
    
    if ( ![[[self navigationController] navigationBar] respondsToSelector:@selector(setBarTintColor:)] )
        {
        [[[self navigationItem] rightBarButtonItem] setTintColor:nil];
        }
}

/*****************************************************************/
/**
 \brief  Called after the controller's view object has loaded.
 *****************************************************************/
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // We set the values of the various controls to reflect the current settings.
    BMLT_Prefs  *myPrefs = [BMLT_Prefs getBMLT_Prefs];
    [lookUpLocationSwitch setOn:[myPrefs lookupMyLocation]];
    [keepUpdatingSwitch setOn:[myPrefs keepUpdatingLocation]];
    [retainStateSwitch setOn:[myPrefs preserveAppStateOnSuspend]];
    [mapResultsSwitch setOn:[myPrefs preferSearchResultsAsMap]];
    [distanceSortSwitch setOn:[myPrefs preferDistanceSort]];

    if ( ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) && ([preferredSearchTypeControl numberOfSegments] > 2) )
        {
        [preferredSearchTypeControl removeSegmentAtIndex:1 animated:NO];
        }

    switch ( [myPrefs searchTypePref] )
    {
        default:
        case _PREFER_SIMPLE_SEARCH:
        [preferredSearchTypeControl setSelectedSegmentIndex:_PREFER_SIMPLE_SEARCH];
        break;
      
        case _PREFER_ADVANCED_SEARCH:
        [preferredSearchTypeControl setSelectedSegmentIndex:_PREFER_ADVANCED_SEARCH];
        break;
    }
    // The slider is a logarithmic scale between 5 and 20. Nominal is 10.
    float   min_val = log10f(_LOG_MIN);
    float   max_val = log10f(_LOG_MAX);
    
    [numMeetingsSlider setMinimumValue:min_val];
    [numMeetingsSlider setMaximumValue:max_val];
    
    [numMeetingsSlider setValue:log10f([[NSNumber numberWithInt:[myPrefs resultCount]] floatValue])];
    
    // We make sure that the displayed strings reflect the localized values.
    [lookupLocationLabel setText:NSLocalizedString([lookupLocationLabel text], nil)];
    [keepUpdatingLabel setText:NSLocalizedString([keepUpdatingLabel text], nil)];
    [retainStateLabel setText:NSLocalizedString([retainStateLabel text], nil)];
    [mapResultsLabel setText:NSLocalizedString([mapResultsLabel text], nil)];
    [distanceSortLabel setText:NSLocalizedString([distanceSortLabel text], nil)];
    [preferredSearchTypeLabel setText:NSLocalizedString([preferredSearchTypeLabel text], nil)];
    [numMeetingsLabel setText:NSLocalizedString([numMeetingsLabel text], nil)];
    [minLabel setText:NSLocalizedString([minLabel text], nil)];
    [maxLabel setText:NSLocalizedString([maxLabel text], nil)];
    [[self forgetEmailButton] setTitle:NSLocalizedString(@"PREF-SCREEN-FORGET-BUTTON-TITLE", nil) forState:UIControlStateNormal];
    
    for ( NSUInteger i = 0; i < [preferredSearchTypeControl numberOfSegments]; i++ )
        {
        [preferredSearchTypeControl setTitle:NSLocalizedString([preferredSearchTypeControl titleForSegmentAtIndex:i], nil) forSegmentAtIndex:i];
        }
    
    [[self updateLocationButton] setTitle:NSLocalizedString([[self updateLocationButton] titleForState:UIControlStateNormal], nil) forState:UIControlStateNormal];
    
    // No location services, no lookup.
    if ( ![BMLTAppDelegate locationServicesAvailable] )
        {
        [[self updateLocationButton] setEnabled:NO];
        }
    
    if ( [self aboutView] )
        {
        [self setMyAboutViewController:[[self storyboard] instantiateViewControllerWithIdentifier:@"info-window-view"]];
        
        if ( myAboutViewController )
            {
#ifdef DEBUG
            NSLog(@"BMLTSettingsViewController::viewDidLoad: Loading the about view into the big view");
#endif
            [[myAboutViewController view] setFrame:[[self aboutView] bounds]];
            
            [[self aboutView] addSubview:[myAboutViewController view]];
            }
        }
}

/*****************************************************************/
/**
 \brief  Called when the user flicks the lookup on startup switch.
 *****************************************************************/
- (IBAction)lookupLocationChanged:(id)inSender    ///< The switch in question
{
    UISwitch  *myControl = (UISwitch *)inSender;  // Get the sender as a switch
    [[BMLT_Prefs getBMLT_Prefs] setLookupMyLocation:[myControl isOn]];
    [BMLT_Prefs saveChanges];
}

/*****************************************************************/
/**
 \brief  Called when the user flicks the keep updating location switch.
 *****************************************************************/
- (IBAction)keepUpdatingChanged:(id)inSender  ///< The switch in question
{
    UISwitch  *myControl = (UISwitch *)inSender;  // Get the sender as a switch
    [[BMLT_Prefs getBMLT_Prefs] setKeepUpdatingLocation:[myControl isOn]];
    [BMLT_Prefs saveChanges];
}

/*****************************************************************/
/**
 \brief  Called when the user flicks the saved state switch.
 *****************************************************************/
- (IBAction)retainStateChanged:(id)inSender   ///< The switch in question
{
    UISwitch  *myControl = (UISwitch *)inSender;  // Get the sender as a switch
    [[BMLT_Prefs getBMLT_Prefs] setPreserveAppStateOnSuspend:[myControl isOn]];
    [BMLT_Prefs saveChanges];
}

/*****************************************************************/
/**
 \brief  Called when the user flicks the return results as a map switch.
 *****************************************************************/
- (IBAction)mapResultsChanged:(id)inSender    ///< The switch in question
{
    UISwitch  *myControl = (UISwitch *)inSender;  // Get the sender as a switch
    [[BMLT_Prefs getBMLT_Prefs] setPreferSearchResultsAsMap:[myControl isOn]];
    [BMLT_Prefs saveChanges];
}

/*****************************************************************/
/**
 \brief  Called when the user flicks the prefer distance sort switch.
 *****************************************************************/
- (IBAction)distanceSortChanged:(id)inSender    ///< The switch in question
{
    UISwitch  *myControl = (UISwitch *)inSender;  // Get the sender as a switch
    [[BMLT_Prefs getBMLT_Prefs] setPreferDistanceSort:[myControl isOn]];
    [BMLT_Prefs saveChanges];
}

/*****************************************************************/
/**
 \brief  Called when the user selects a preffered search type.
 *****************************************************************/
- (IBAction)preferredSearchChanged:(id)inSender   ///< The search type segmented control
{
    UISegmentedControl  *myControl = (UISegmentedControl *)inSender;  // Get the sender as a segmented control
    [[BMLT_Prefs getBMLT_Prefs] setSearchTypePref:(int)[myControl selectedSegmentIndex]];
    [BMLT_Prefs saveChanges];
    
    if ( [[BMLT_Prefs getBMLT_Prefs] searchTypePref] != _PREFER_ADVANCED_SEARCH )
        {
        [[BMLTAppDelegate getBMLTAppDelegate] selectInitialSearchAndForce:YES];
        }

}

/*****************************************************************/
/**
 \brief  Called when the user selects a new meeting count.
 *****************************************************************/
- (IBAction)numMeetingsChanged:(id)inSender   ///< The meeting count slider
{
    UISlider  *myControl = (UISlider *)inSender;  // Get the sender as a slider control
    [[BMLT_Prefs getBMLT_Prefs] setResultCount:floorf(powf(10, [myControl value]))];
    [BMLT_Prefs saveChanges];
}

/*****************************************************************/
/**
 \brief  Called when the user wants to forget a saved email address.
 *****************************************************************/
- (IBAction)forgetEmailHit:(UIButton *)inSender
{
    [[BMLT_Prefs getBMLT_Prefs] setEmailSenderName:@""];
    [[BMLT_Prefs getBMLT_Prefs] setEmailSenderAddress:@""];
    [BMLT_Prefs saveChanges];
    [[self forgetEmailButton] setHidden:YES];
}

/*****************************************************************/
/**
 \brief  Called when the user wants to update their location now.
 *****************************************************************/
- (IBAction)updateUserLocationNow:(id)inSender    ///< The update Location button.
{
    [[BMLTAppDelegate getBMLTAppDelegate] lookupMyLocationWithAccuracy:kCLLocationAccuracyBest];
}
@end

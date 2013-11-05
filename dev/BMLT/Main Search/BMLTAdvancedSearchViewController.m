//
//  BMLTAdvancedSearchViewController.m
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

#import "BMLTAdvancedSearchViewController.h"
#import "BMLTAppDelegate.h"
#import "BMLT_Prefs.h"
#import "BMLT_Parser.h"

static BOOL geocodeInProgress = NO;     ///< Used to look for a successful geocode.
static BOOL searchAfterLookup = NO;     ///< Used for the iPhone to make sure a search happens after the lookup for the return key (Handled differently for the iPad).

/*****************************************************************/
/**
 \class  BMLTAdvancedSearchViewController    -Private Interface
 \brief  This class will present the user with a powerful search specification interface.
 *****************************************************************/
@interface BMLTAdvancedSearchViewController ()
{
    BOOL dontLookup;
}
@end

/*****************************************************************/
/**
 \class  BMLTAdvancedSearchViewController    -Implementation
 \brief  This class will present the user with a powerful search specification interface.
 *****************************************************************/
@implementation BMLTAdvancedSearchViewController
@synthesize myParams, currentElement;
@synthesize weekdaysLabel, weekdaysSelector, sunLabel, monLabel, tueLabel, wedLabel, thuLabel, friLabel, satLabel;
@synthesize searchLocationLabel, searchSpecSegmentedControl, searchSpecAddressTextEntry;
@synthesize goButton;

/*****************************************************************/
/**
 \brief Initializer -allocates our parameter dictionary.
 \returns self
 *****************************************************************/
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if ( self )
        {
        myParams = [[NSMutableDictionary alloc] init];
        dontLookup = NO;
        }
    
    return self;
}

/*****************************************************************/
/**
 \brief The only reason we intercept this, is to stop lookups.
 *****************************************************************/
- (void)viewWillDisappear:(BOOL)animated    ///< YES, if this is an animated disappearance (we don't care).
{
    dontLookup = YES;   // We set this to avoid lookups when we close.
}

/*****************************************************************/
/**
 \brief Make sure that the text box is shown, if there is no choice.
 *****************************************************************/
- (void)viewWillAppear:(BOOL)animated
{
    dontLookup = NO;
    
    if ( ![BMLTAppDelegate locationServicesAvailable] && ![self mapSearchView] )
        {
        [searchSpecSegmentedControl setEnabled:NO forSegmentAtIndex:0];
        [searchSpecSegmentedControl setSelectedSegmentIndex:1];
        [searchSpecAddressTextEntry setAlpha:1.0];
        [searchSpecAddressTextEntry setEnabled:YES];
        dontLookup = NO;
        [searchSpecAddressTextEntry becomeFirstResponder];
        [goButton setEnabled:NO];
        }
    
    [self addToggleMapButton];
    
    [super viewWillAppear:animated];
    
    [self weekdaySelectionChanged:nil];
}

/*****************************************************************/
/**
 \brief Makes sure that the checkboxes are correct.
 *****************************************************************/
- (void)viewDidAppear:(BOOL)animated
{
    [self setParamsForWeekdaySelection];
}

/*****************************************************************/
/**
 \brief Sets up all the localized strings and whatnot.
 *****************************************************************/
- (void)viewDidLoad
{
    [weekdaysLabel setText:NSLocalizedString([weekdaysLabel text], nil)];
    
    for ( NSUInteger i = 0; i < [weekdaysSelector numberOfSegments]; i++ )
        {
        [weekdaysSelector setTitle:NSLocalizedString([weekdaysSelector titleForSegmentAtIndex:i], nil) forSegmentAtIndex:i];
        }
    
    for ( UIView *sub in [[self weekdaySearchContainer] subviews] )
        {
        if ( [sub isKindOfClass:[UILabel class]] )
            {
            NSInteger   startDay = [BMLTVariantDefs weekStartDay];
            NSString    *pText = [(UILabel*)sub text];
            NSInteger   labelVal = [pText integerValue] + (startDay - 1);
            
            if ( labelVal > 7 )
                {
                labelVal -= 7;
                }
            
            if ( labelVal-- )
                {
                NSString    *pLabel = nil;
                
                if ( ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) )
                    {
                    pLabel = [NSString stringWithFormat:@"WEEKDAY-NAME-%d", labelVal];
                    }
                else
                    {
                    pLabel = [NSString stringWithFormat:@"WEEKDAY-SHORT-NAME-%d", labelVal];
                    }
                    
                [(UILabel*)sub setText:NSLocalizedString ( pLabel, nil )];
                }
            }
        }
    
    [searchLocationLabel setText:NSLocalizedString([searchLocationLabel text], nil)];
    
    for ( NSUInteger i = 0; i < [searchSpecSegmentedControl numberOfSegments]; i++ )
        {
        [searchSpecSegmentedControl setTitle:NSLocalizedString([searchSpecSegmentedControl titleForSegmentAtIndex:i], nil) forSegmentAtIndex:i];
        }
    
    [searchSpecAddressTextEntry setPlaceholder:NSLocalizedString([searchSpecAddressTextEntry placeholder], nil)];
    
    [goButton setTitle:NSLocalizedString([goButton titleForState:UIControlStateNormal], nil) forState:UIControlStateNormal];
    
    [super viewDidLoad];
}

/*****************************************************************/
/**
 \brief Called when the weekday selection segmented control is changed.
 *****************************************************************/
- (IBAction)weekdaySelectionChanged:(id)sender  ///< The segmented control.
{
    if ( [weekdaysSelector selectedSegmentIndex] == kWeekdaySelectWeekdays )
        {
        [[self enabledWeekdaysCheckBoxes] setHidden:NO];
        [[self disabledWeekdaysCheckBoxes] setHidden:YES];
        }
    else
        {
        [[self enabledWeekdaysCheckBoxes] setHidden:YES];
        [[self disabledWeekdaysCheckBoxes] setHidden:NO];
        }
    
    [self setParamsForWeekdaySelection];
}

/*****************************************************************/
/**
 \brief Called when the search button is pressed.
 *****************************************************************/
- (IBAction)doSearchButtonPressed:(id)sender    ///< The search button.
{
#ifdef DEBUG
    NSLog(@"BMLTAdvancedSearchViewController doSearchButtonPressed");
#endif
    [searchSpecAddressTextEntry resignFirstResponder];
    [[BMLTAppDelegate getBMLTAppDelegate] clearAllSearchResultsNo];
    
    // If we have an address, then we need to make sure that we resolve it.
    if ( [[searchSpecAddressTextEntry text] length] && ([searchSpecSegmentedControl selectedSegmentIndex] == 1) )
        {
        searchAfterLookup = YES;
        [self geocodeLocationFromAddressString:[searchSpecAddressTextEntry text]];
        }
    else
        {
        [[BMLTAppDelegate getBMLTAppDelegate] searchForMeetingsNearMe:[[BMLTAppDelegate getBMLTAppDelegate] searchMapMarkerLoc] withParams:myParams];
        }
}

/*****************************************************************/
/**
 \brief Called when there is a click in the background.
 *****************************************************************/
- (IBAction)backgroundClicked:(id)sender
{
#ifdef DEBUG
    NSLog(@"BMLTAdvancedSearchViewController backgroundClicked");
#endif
    geocodeInProgress = NO;
    dontLookup = YES;
    [searchSpecAddressTextEntry resignFirstResponder];
}

/*****************************************************************/
/**
 \brief Called when one of the weekday checkboxes is selected.
 *****************************************************************/
- (IBAction)weekdayChanged:(id)sender   //< The checkbox
{
    [self setParamsForWeekdaySelection];
}

/*****************************************************************/
/**
 \brief Called when the search spec segmented control changes.
 *****************************************************************/
- (IBAction)searchSpecChanged:(id)sender    ///< The segmented control
{
#ifdef DEBUG
    NSLog(@"BMLTAdvancedSearchViewController searchSpecChanged: %d.", [(UISegmentedControl *)sender selectedSegmentIndex] );
#endif
    geocodeInProgress = NO;
    dontLookup = YES;
    searchAfterLookup = NO;
    if ( [(UISegmentedControl *)sender selectedSegmentIndex] == 0 ) // Near Me/Marker?
        {
        if ( ![self myMarker] )
            {
            [[BMLTAppDelegate getBMLTAppDelegate] lookupMyLocationWithAccuracy:kCLLocationAccuracyBest];
            }
        [searchSpecAddressTextEntry setAlpha:0.0];
        [searchSpecAddressTextEntry setEnabled:NO];
        }
    else
        {
        [searchSpecAddressTextEntry setAlpha:1.0];
        [searchSpecAddressTextEntry setEnabled:YES];
        dontLookup = NO;
        [searchSpecAddressTextEntry becomeFirstResponder];
        }
}

/*****************************************************************/
/**
 \brief Called when the user has entered an address.
 *****************************************************************/
- (IBAction)addressTextEntered:(id)sender   ///< The text entry field.
{
#ifdef DEBUG
    NSLog(@"BMLTAdvancedSearchViewController addressTextEntered: \"%@\".", [searchSpecAddressTextEntry text] );
#endif
    if ( !dontLookup && [searchSpecAddressTextEntry text] && ([searchSpecSegmentedControl selectedSegmentIndex] == 1) )
        {
        [self geocodeLocationFromAddressString:[searchSpecAddressTextEntry text]];
        }
    else if ( ![BMLTAppDelegate locationServicesAvailable] && ![self mapSearchView] )
        {
        [goButton setEnabled:NO];
        }
    dontLookup = NO;
}

/*****************************************************************/
/**
 \brief Sets up the parameters for the search, based on the state of the checkboxes.
 *****************************************************************/
- (void)setParamsForWeekdaySelection
{
    [myParams removeObjectForKey:@"weekdays"];  // Start with a clean slate.
    [myParams removeObjectForKey:@"StartsAfterH"];
    [myParams removeObjectForKey:@"StartsAfterM"];
    
    int   wd = 0;
    
    int position_1 = [BMLTVariantDefs weekStartDay];
    int position_2 = ((position_1 + 1) < 8) ? (position_1 + 1) : 1;
    int position_3 = ((position_2 + 1) < 8) ? (position_2 + 1) : 1;
    int position_4 = ((position_3 + 1) < 8) ? (position_3 + 1) : 1;
    int position_5 = ((position_4 + 1) < 8) ? (position_4 + 1) : 1;
    int position_6 = ((position_5 + 1) < 8) ? (position_5 + 1) : 1;
    int position_7 = ((position_6 + 1) < 8) ? (position_6 + 1) : 1;
    
    // What we're doing here, is seeing if either the "Later Today" or "Tomorrow" checkboxes are selected. If so, we then set the wd variable to the chosen weekday. Otherwise, it is 0.
    if ( ([weekdaysSelector selectedSegmentIndex] == kWeekdaySelectTomorrow) || ([weekdaysSelector selectedSegmentIndex] == kWeekdaySelectToday) )
        {
        NSDate              *date = [BMLTAppDelegate getLocalDateAutoreleaseWithGracePeriod:YES];
        NSCalendar          *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents    *weekdayComponents = [gregorian components:(NSWeekdayCalendarUnit) fromDate:date];
        wd = (int)[weekdayComponents weekday] + position_1;
            
        weekdayComponents = [gregorian components:(NSHourCalendarUnit) fromDate:date];
        NSInteger           hr = [weekdayComponents hour];
        weekdayComponents = [gregorian components:(NSMinuteCalendarUnit) fromDate:date];
        NSInteger           mn = [weekdayComponents minute];
        
        if ( [weekdaysSelector selectedSegmentIndex] == kWeekdaySelectTomorrow )
            {
            wd++;
            }
        else
            {
            [myParams setObject:[NSString stringWithFormat:@"%d",hr] forKey:@"StartsAfterH"];
            [myParams setObject:[NSString stringWithFormat:@"%d",mn] forKey:@"StartsAfterM"];
            }
            
        if ( wd > 7 )
            {
            wd -= 7;
            }
        }
    
    NSString        *weekday = @"";
    NSMutableArray  *pTags = [[NSMutableArray alloc] init];
    
    // If we are on the chosen weekday, or our button is enabled, and our button is on, then add this day to the list.
    NSString    *wdS = nil;
    if ( (wd == position_1) || [self isWeekdaySelected:@"1"] )
        {
        wdS = [NSString stringWithFormat:@"%d", position_1];
        weekday = wdS;
        [pTags addObject:wdS];
        }
    
    if ( (wd == position_2) || [self isWeekdaySelected:@"2"] )
        {
        wdS = [NSString stringWithFormat:@"%d", position_2];
        weekday = [weekday stringByAppendingString:[weekday length] > 0 ? [NSString stringWithFormat:@",%@", wdS] : wdS];
        [pTags addObject:wdS];
        }
    
    if ( (wd == position_3) || [self isWeekdaySelected:@"3"] )
        {
        wdS = [NSString stringWithFormat:@"%d", position_3];
        weekday = [weekday stringByAppendingString:[weekday length] > 0 ? [NSString stringWithFormat:@",%@", wdS] : wdS];
        [pTags addObject:wdS];
        }
    
    if ( (wd == position_4) || [self isWeekdaySelected:@"4"] )
        {
        wdS = [NSString stringWithFormat:@"%d", position_4];
        weekday = [weekday stringByAppendingString:[weekday length] > 0 ? [NSString stringWithFormat:@",%@", wdS] : wdS];
        [pTags addObject:wdS];
        }
    
    if ( (wd == position_5) || [self isWeekdaySelected:@"5"] )
        {
        wdS = [NSString stringWithFormat:@"%d", position_5];
        weekday = [weekday stringByAppendingString:[weekday length] > 0 ? [NSString stringWithFormat:@",%@", wdS] : wdS];
        [pTags addObject:wdS];
        }
    
    if ( (wd == position_6)  || [self isWeekdaySelected:@"6"] )
        {
        wdS = [NSString stringWithFormat:@"%d", position_6];
        weekday = [weekday stringByAppendingString:[weekday length] > 0 ? [NSString stringWithFormat:@",%@", wdS] : wdS];
        [pTags addObject:wdS];
        }
    
    if ( (wd == position_7)  || [self isWeekdaySelected:@"7"] )
        {
        wdS = [NSString stringWithFormat:@"%d", wd];
        weekday = [weekday stringByAppendingString:[weekday length] > 0 ? [NSString stringWithFormat:@",%@", wdS] : wdS];
        [pTags addObject:wdS];
        }
    
    [[self disabledWeekdaysCheckBoxes] setTagArray:pTags];
    
    // We have an array of chosen weekdays (integers). Set them to the parameter.
    if ( [weekday length] )
        {
        [myParams setObject:weekday forKey:@"weekdays"];
        }
    
    if ( [weekdaysSelector selectedSegmentIndex] == kWeekdaySelectAllDays )
    {
        NSArray *pAllTags = @[@"1", @"2", @"3", @"4", @"5", @"6", @"7"];
        
        [[self disabledWeekdaysCheckBoxes] setTagArray:pAllTags];
    }
}

/*****************************************************************/
/**
 \brief See if a weekday checkbox is selected.
 
 \returns a BOOL. YES, if the checkbox is selected, and visible.
 *****************************************************************/
- (BOOL)isWeekdaySelected:(NSString*)inTag
{
    BOOL    ret = NO;
    
    NSArray *pTags = [[self enabledWeekdaysCheckBoxes] isHidden] ? nil : [[self enabledWeekdaysCheckBoxes] tagArray];
    
    if ( pTags )
    {
        for ( NSString* pTag in pTags )
        {
            if ( [pTag isEqualToString:inTag] )
            {
                ret = YES;
                break;
            }
        }
    }
    return ret;
}

/*****************************************************************/
/**
 \brief Starts an asynchronous geocode from a given address string.
 *****************************************************************/
- (void)geocodeLocationFromAddressString:(NSString *)inLocationString   ///< The location, as a readable address string.
{
    if ( !dontLookup )  // Don't lookup if we are closing up shop.
        {
        CLLocationCoordinate2D centerLoc = [BMLTVariantDefs mapDefaultCenter];  // We center on the app's specified starting location
        
        // Create a bias region.
        CLRegion *region = [[CLRegion alloc] initCircularRegionWithCenter:centerLoc radius:1.0 identifier:@"Default App Location"];
        
        CLGeocoder  *myGeocoder = [[CLGeocoder alloc] init];    // We temporarily create a geocoder for this.
        
        [myGeocoder geocodeAddressString:inLocationString
                                inRegion:region
                       completionHandler:^(NSArray* placemarks, NSError* error) // The completion handler deals with the result of the geocode.
                                        {
                                        // If we failed to geocode, we alert the user.
                                        if ( !placemarks || ![placemarks count] )
                                            {
                                            searchAfterLookup = NO;
                                            geocodeInProgress = NO;
                                            dontLookup = NO;
                                            UIAlertView *myAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"GEOCODE-FAILURE",nil) message:nil delegate:nil cancelButtonTitle:NSLocalizedString(@"OK-BUTTON",nil) otherButtonTitles:nil];
                                            [myAlert show];
                                            
                                            if ( ![BMLTAppDelegate locationServicesAvailable] && ![self mapSearchView] )
                                                {
                                                [goButton setEnabled:NO];
                                                }
                                            }
                                        else    // Otherwise, we find the nearest geocoded place, and use that.
                                            {
                                            CLLocation  *currentLoc = [[CLLocation alloc] initWithLatitude:centerLoc.latitude longitude:centerLoc.longitude];
                                            CLLocation  *centerLocation = currentLoc;
                                            
                                            float       lastDistance = MAXFLOAT;
                                            
                                            for (CLPlacemark* aPlacemark in placemarks)
                                                {
                                                CLLocationDistance meters = [[aPlacemark location] distanceFromLocation:centerLocation];
                                                
                                                if ( meters < lastDistance )
                                                    {
                                                    lastDistance = meters;
                                                    currentLoc = [aPlacemark location];

#ifdef DEBUG
                                                    NSLog(@"BMLTAdvancedSearchViewController::geocodeLocationFromAddressString: completionBlock: Setting the marker location to (%f, %f).", [currentLoc coordinate].longitude, [currentLoc coordinate].latitude);
#endif
                                                    }
                                                }
                                        
                                            [[BMLTAppDelegate getBMLTAppDelegate] setSearchMapMarkerLoc:[currentLoc coordinate]];
                                            
                                            [goButton setEnabled:YES];
                                            
                                            [self performSelectorOnMainThread:@selector(updateMap) withObject:nil waitUntilDone:NO];
                                            
                                            if ( searchAfterLookup )
                                                {
#ifdef DEBUG
                                                NSLog(@"BMLTAdvancedSearchViewController geocodeLocationFromAddressString completionBlock:. Starting a Search." );
#endif
                                                searchAfterLookup = NO;
                                                [[BMLTAppDelegate getBMLTAppDelegate] searchForMeetingsNearMe:[[BMLTAppDelegate getBMLTAppDelegate]
                                                                                                               searchMapMarkerLoc] withParams:myParams];
                                                }
                                            }
                                        }
         ];
        }
}

#pragma mark - UITextFieldDelegate Functions -
/*****************************************************************/
/**
 \brief This is called when the user presses the "Enter" button on the text field editor.
 *****************************************************************/
- (BOOL)textFieldShouldReturn:(UITextField *)textField  ///< The text field object.
{
    geocodeInProgress = NO;
    if ( ![self mapSearchView] )
        {
        searchAfterLookup = YES;
        }
#ifdef DEBUG
    NSLog(@"BMLTAdvancedSearchViewController textFieldShouldReturn: searchAfterLookup = \"%@\".", searchAfterLookup ? @"YES" : @"NO");
#endif
    [self geocodeLocationFromAddressString:[textField text]];
    return NO;
}

/*****************************************************************/
/**
 \brief When the text is done editing, we do the same thing, but
 without the subsequent search.
 *****************************************************************/
- (void)textFieldDidEndEditing:(UITextField *)textField ///< The text field object.
{
    searchAfterLookup = NO;
    if ( [[textField text] length] && ([searchSpecSegmentedControl selectedSegmentIndex] > 0) && !([[self view] isHidden]) )
        {
        [self geocodeLocationFromAddressString:[textField text]];
        }
}
@end

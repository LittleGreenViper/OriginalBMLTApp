//
//  BMLTAppDelegate.m
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

#import "BMLTAppDelegate.h"
#import "Reachability.h"
#import "BMLT_Prefs.h"
#import "BMLT_Meeting.h"
#import "BMLT_Parser.h"
#import "BMLTDisplayListResultsViewController.h"
#import "BMLTMapResultsViewController.h"
#import "BMLTSimpleSearchViewController.h"
#import "BMLTAdvancedSearchViewController.h"
#import "BMLTMeetingDetailViewController.h"
#import "BMLTAnimationScreenViewController.h"
#import "BMLTSettingsViewController.h"
#ifdef _TESTFLIGHT_
    #import "TestFlight.h"
#endif

static          BMLTAppDelegate *g_AppDelegate = nil;                   ///< This holds the SINGLETON instance of the application delegate.
static const    float           sTestEmailURLRequestTimeout = 1.5;      ///< The timeout (in seconds), of the contact test.
static const    float           s90Minutes                  = 5400.0;   ///< 90 minutes' worth of seconds.
static const    float           sHowManyMeters              = 100.0;    ///< This is the radius, in meters, for the "Where Am I Now?" search.

#ifdef _TESTFLIGHT_ /* Used for the TesFlightApp.com utility. */
static NSString *kTestFlightTeamToken = @"89521cfd695fa615cc412b7048699107_ODQ2NTYyMDEyLTA0LTI2IDEwOjQ0OjM5LjU2NjA4OQ"; 
#endif

enum    ///< These are the tab indexes in the array.
{
    kSearchTabIndex = 0,    /**< The index of the Search tab. */
    kListResultsTabIndex,   /**< The index of the list results tab. */
    kMapResultsTabIndex,    /**< The index of the map results tab. */
    kSettingsTabIndex       /**< The index of the settings tab. */
};

enum    ///< These enums reflect values set by the storyboard, and govern the transition between selected tabs.
{
    kTransition_LeavingSettings = -2,   ///< Going out of the settings tab to another tab.
    kTransition_RightToLeft,            ///< Going from a right tab to a left tab.
    kTransition_Nothing,                ///< Not used.
    kTransition_LeftToRight,            ///< Going from a left tab to a right tab.
    kTransition_EnteringSettings        ///< Coming from another tab to the settings tab.
};

/*****************************************************************/
/**
 \class  BMLTAppDelegate -Private Interface
 \brief  This is the main application delegate class for the BMLT application
 *****************************************************************/
@interface BMLTAppDelegate ()
{
    BOOL                    _findMeetings;              ///< If this is YES, then a meeting search will be done.
    BOOL                    _amISick;                   ///< If true, it indicates that the alert for connectivity problems should not be shown.
    BOOL                    _visitingRelatives;         ///< If true, then we will retain the app state, despite the flag that says we shouldn't.
    BMLT_Meeting_Search     *mySearch;                  ///< The current meeting search in progress.
    BOOL                    deferredSearch;             ///< A semaphore that is set, in order to allow the animation to appear before the search starts.
    NSURLRequest            *testEmailURLRequest;       ///< This is used to find out if the server supports email.
}

- (void)transitionBetweenThisView:(UIView *)srcView andThisView:(UIView *)dstView direction:(int)dir;   ///< Do a nice transition between tab views.
- (void)callInSick;                                     ///< Display an alert, informing the user that network connectivity is unavailable.
- (void)sorryCharlie;                                   ///< Display an alert for no meetings found.
- (void)displaySearchResults;                           ///< Display the results of a search, according to the user preferences.
- (void)stopAnimations;                                 ///< Stops the animations in the two results screens.
- (void)simpleClearSearch;                              ///< Just clears the search results with no frou-frou.
@end

/*****************************************************************/
/**
 \class  BMLTAppDelegate
 \brief  This is the main application delegate class for the BMLT application
 *****************************************************************/
@implementation BMLTAppDelegate

#pragma mark - Synthesize Class Properties -
@synthesize lastLocation;               ///< This will hold the last location for the user (as opposed to the search center). This is used for directions.
@synthesize window      = _window;      ///< This will hold the window associated with this application instance.
@synthesize locationManager;            ///< This holds the location manager instance.
@synthesize hostActive;                 ///< Set to YES, if the network test says that the root server is available.
@synthesize myPrefs;                    ///< This will have a reference to the global prefs object.
@synthesize searchResults;              ///< This will hold the latest search results.
@synthesize searchParams;               ///< This will hold the parameters to be used for the next search.
@synthesize activeSearchController;     ///< This will point to the active search controller. Nil, if none.
@synthesize searchMapRegion;            ///< Used to track the state of the search spec maps.
@synthesize lastSearchParams;           ///< This saves the exact pameters used for the last search.
@synthesize searchMapMarkerLoc = _markerLoc;    /**<    This contains the location used for the search marker.
                                                        This is the central location for all searches and results displays. This is where the black marker sits.
                                                        It may well be a different place from the user's location (for example, if they entered an address, or
                                                        moved the marker in a map search). IT is not set in many places, but is referenced throughout the app.
                                                */
@synthesize searchNavController;        ///< This is the tab controller for all the searches.
@synthesize listResultsViewController;  ///< This will point to our list results main controller.
@synthesize mapResultsViewController;   ///< This will point to our map results main controller.
@synthesize settingsViewController;     ///< This will point to our settings/info main controller.
@synthesize reusableMeetingDetails = _details;     ///< This will hold an instance of our meeting details view controller that we will re-use.
@synthesize currentAnimation;           ///< This will hold our current active animation (nil, otherwise).
@synthesize mapType;                    ///< The current displayed map type.

#pragma mark - Class Methods -
/*****************************************************************/
/**
 \brief  This class method allows access to the application delegate object (SINGLETON)
 *****************************************************************/
+ (BMLTAppDelegate *)getBMLTAppDelegate
{
    return g_AppDelegate;
}

/*****************************************************************/
/**
 \brief Check to make sure that Location Services are available
 \returns YES, if Location Services are available
 *****************************************************************/
+ (BOOL)locationServicesAvailable
{
    return ([CLLocationManager locationServicesEnabled] != NO)
            && ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied);
}

/*****************************************************************/
/**
 \brief Check to make sure that we can reach the root server.
 \returns YES, if the server is available.
 *****************************************************************/
+ (BOOL)canReachRootServer
{
    return [g_AppDelegate hostActive];
}

/*****************************************************************/
/**
 \brief returns the date/time of the "too late" meeting start time.
 \returns an NSDate, set to the time (either now, or with the grace period)
 *****************************************************************/
+ (NSDate *)getLocalDateWithGracePeriod:(BOOL)useGracePeriod ///< YES, if the grace period is to be included.
{
    NSTimeInterval  interval = -(useGracePeriod ? [[g_AppDelegate getMyPrefs] gracePeriod] * 60 : 0);
    
    return [NSDate dateWithTimeIntervalSinceNow:interval];
}

/*****************************************************************/
/**
 \brief Pushes the meeting details screen onto the current nav stack.
 *****************************************************************/
+ (void)viewMeetingDetails:(BMLT_Meeting *)inMeeting            ///< The object for the meeting to be displayed.
                 inContext:(UIViewController *)inController     ///< The controller that will be given responsibility for modal dialogs.
{
    // If no controller was supplied, we assume that this was a map results popover.
    if ( !inController )
        {
        inController = [g_AppDelegate mapResultsViewController];
        }
    
    // Make sure we close the door behind us...
    [[g_AppDelegate listResultsViewController] closeModal];      ///< Make sure we close any open modals or popovers, first.
    [[g_AppDelegate mapResultsViewController] dismissListPopover];
    [[g_AppDelegate mapResultsViewController] closeModal];
    
    BMLTMeetingDetailViewController *details = [g_AppDelegate reusableMeetingDetails];
    
    [[details navigationController] popViewControllerAnimated:NO];    // Make sure that we are not leaving our mudflap open.
    
    if ( !details )
        {
        // Get the storyboard, then instantiate the details view from the independent view controller.
        UIStoryboard    *st = [inController storyboard];
        details = (BMLTMeetingDetailViewController *)[st instantiateViewControllerWithIdentifier:@"meeting-details-sheet"];
        [g_AppDelegate setReusableMeetingDetails:details];
        }

    // Set the basics.
    [details setMyModalController:inController];
    [details setMyMeeting:inMeeting];
    
    // Push the new details controller onto the stack.
    [[inController navigationController] pushViewController:details animated:YES];
    [details setMapLocation];
}

/*****************************************************************/
/**
 \brief Sorts a meeting list results array by weekday and time.
 \returns an array of BMLT_Meeting objects, sorted the desired way.
 *****************************************************************/
+ (NSArray *)sortMeetingListByWeekdayAndTime:(NSArray *)inMeetings  ///< An array of BMLT_Meeting objects to be sorted.
{
#ifdef DEBUG
    NSLog(@"BMLTAppDelegate::sortMeetingListByWeekdayAndTime start.");
#endif
    NSArray *sortedArray = [inMeetings sortedArrayUsingComparator: ^(id obj1, id obj2) {
        BMLT_Meeting    *meeting_A = (BMLT_Meeting *)obj1;
        BMLT_Meeting    *meeting_B = (BMLT_Meeting *)obj2;
        
        NSInteger       position_1 = [BMLTVariantDefs weekStartDay];
        NSInteger       meetingAWeekday = [meeting_A getWeekdayOrdinal];
        meetingAWeekday -= (position_1 - 1);
        
        if ( meetingAWeekday < 1 )
            {
            meetingAWeekday += 7;
            }
        
        NSInteger       meetingBWeekday = [meeting_B getWeekdayOrdinal];
        meetingBWeekday -= (position_1 - 1);

        if ( meetingBWeekday < 1 )
            {
            meetingBWeekday += 7;
            }
        
#ifdef DEBUG
        NSLog(@"\tBMLTAppDelegate::sortMeetingListByWeekdayAndTime: Sort Block. Meeting A: %@ (%d, %ld) Meeting B: %@ (%d, %ld)", [meeting_A getBMLTName],[meeting_A getStartTimeOrdinal], (long)meetingAWeekday, [meeting_B getBMLTName], [meeting_B getStartTimeOrdinal], (long)meetingBWeekday);
#endif
        if ( meetingAWeekday < meetingBWeekday )
            return NSOrderedAscending;
        else if (meetingAWeekday > meetingBWeekday)
            return NSOrderedDescending;
        else if ( [meeting_A getStartTimeOrdinal] < [meeting_B getStartTimeOrdinal] )
            return NSOrderedAscending;
        else if ( [meeting_A getStartTimeOrdinal] > [meeting_B getStartTimeOrdinal] )
            return NSOrderedDescending;
        else
            return NSOrderedSame;
    }];
#ifdef DEBUG
    NSLog(@"BMLTAppDelegate::sortMeetingListByWeekdayAndTime end.");
#endif
    
    return sortedArray;
}

/*****************************************************************/
/**
 \brief Sorts a meeting list results array by distance.
 \returns an array of BMLT_Meeting objects, sorted the desired way.
 *****************************************************************/
+ (NSArray *)sortMeetingListByDistance:(NSArray *)inMeetings  ///< An array of BMLT_Meeting objects to be sorted.
{
#ifdef DEBUG
    NSLog(@"BMLTAppDelegate::sortMeetingListByDistance start.");
#endif
    NSArray *sortedArray = [inMeetings sortedArrayUsingComparator: ^(id obj1, id obj2) {
        BMLT_Meeting    *meeting_A = (BMLT_Meeting *)obj1;
        BMLT_Meeting    *meeting_B = (BMLT_Meeting *)obj2;
        
        double   distance1 = [(NSString *)[meeting_A getValueFromField:@"distance_in_km"] doubleValue];
        double   distance2 = [(NSString *)[meeting_B getValueFromField:@"distance_in_km"] doubleValue];
        
#ifdef DEBUG
        NSLog(@"\tBMLTAppDelegate::sortMeetingListByDistance: Sort Block. Meeting A: %@ (%f KM) Meeting B: %@ (%f KM)", [meeting_A getBMLTName], distance1, [meeting_B getBMLTName], distance2);
#endif
        
        if (distance1 < distance2)
            return NSOrderedAscending;
        else if (distance1 > distance2)
            return NSOrderedDescending;
        else
            return NSOrderedSame;
    }];
#ifdef DEBUG
    NSLog(@"BMLTAppDelegate::sortMeetingListByDistance end.");
#endif
    return sortedArray;
}

#pragma mark - Private methods -
/*****************************************************************/
/**
 \brief Return the prefs object for this app.
 \returns the app delegate's BMLT_Prefs instance.
 *****************************************************************/
- (BMLT_Prefs *)getMyPrefs
{
    return myPrefs;
}

/*****************************************************************/
/**
 \brief Manages the transition from one view to another. Just like
        it says on the tin.
 *****************************************************************/
- (void)transitionBetweenThisView:(UIView *)srcView ///< The view object we're transitioning away from
                      andThisView:(UIView *)dstView ///< The view object we're going to
                        direction:(int)dir          /**< The direction. One of these:
                                                        - -2 Going out of the settings pages.
                                                        - -1 Going from right to left
                                                        -  1 Going from left to right
                                                        -  2 Going into the settings pages
                                                        The value is set in the storyboard as a negative or positive integer.
                                                    */
{
    if ( dir && (srcView != dstView) )
        {
        UIViewAnimationOptions  option = 0;
        
        switch ( dir )
            {
                case kTransition_LeavingSettings:   // Going from the settings to another tab.
                option = UIViewAnimationOptionTransitionCurlDown;
                break;
                
                case kTransition_RightToLeft:       // Going from a right tab to a left tab.
                option = UIViewAnimationOptionTransitionFlipFromLeft;
                break;
                
                case kTransition_LeftToRight:       // Going from a left tab to a right tab.
                option = UIViewAnimationOptionTransitionFlipFromRight;
                break;
                
                case kTransition_EnteringSettings:  // Going into the settings pages.
                option = UIViewAnimationOptionTransitionCurlUp;
                break;
            }
        
        [UIView transitionFromView:srcView
                            toView:dstView
                          duration:0.25
                           options:option
                        completion:nil];
        }
}

/*****************************************************************/
/**
 \brief Displays an alert, mentioning that there is no valid connection.
 *****************************************************************/
- (void)callInSick
{
#ifdef DEBUG
    NSLog(@"BMLTAppDelegate::callInSick Calling in sick.");
#endif
    if ( !_amISick )    // This makes sure we only call it once.
        {
        _amISick = YES;
        UIAlertView *myAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"COMM-ERROR",nil) message:NSLocalizedString(@"ERROR-CANT-LOAD-DRIVER",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK-BUTTON",nil) otherButtonTitles:nil];
        [myAlert show];
        }
}

/*****************************************************************/
/**
 \brief Displays an alert for no meetings found.
 *****************************************************************/
- (void)sorryCharlie
{
#ifdef DEBUG
    NSLog(@"BMLTAppDelegate::sorryCharlie No meetings found.");
#endif
    [[currentAnimation messageLabel] setText:NSLocalizedString(@"NO-SEARCH-RESULTS",nil)];
}

/*****************************************************************/
/**
 \brief This is called to tell the app to display the search results.
 *****************************************************************/
- (void)displaySearchResults
{
#ifdef DEBUG
    NSLog(@"BMLTAppDelegate::displaySearchResults start.");
#endif
    if ( [[self searchResults] count] )
        {
        [mapResultsViewController setMapInit:NO];
        [listResultsViewController addClearSearchButton];
        [mapResultsViewController addClearSearchButton];
        [listResultsViewController setIncludeSortRow:YES];
        
        assert ( myPrefs != nil );
        
        if ( [myPrefs preferDistanceSort] )
            {
#ifdef DEBUG
            NSLog(@"\tBMLTAppDelegate::displaySearchResults The meetings will be sorted by distance.");
#endif
            [self sortMeetingsByDistance];
            }
        else
            {
#ifdef DEBUG
            NSLog(@"\tBMLTAppDelegate::displaySearchResults The meetings will be sorted by time.");
#endif
            [self sortMeetingsByWeekdayAndTime];
            }
        
        [listResultsViewController setDataArrayFromData:[self searchResults]];
        [mapResultsViewController setDataArrayFromData:[self searchResults]];
        [self stopAnimations];
        [self setUpTabBarItems];
        
        UITabBarController  *tabController = (UITabBarController *)self.window.rootViewController;
        [tabController setSelectedIndex:((![self whereAmISearchInProgress] && [myPrefs preferSearchResultsAsMap]) ? kMapResultsTabIndex : kListResultsTabIndex)];
        
        if ( [self whereAmISearchInProgress] && (1 == [[self searchResults] count]) )
            {
            [listResultsViewController selectMeeting:0];
            }
        else
            {
            [[listResultsViewController sortControl] setSelectedSegmentIndex:([[BMLT_Prefs getBMLT_Prefs] preferDistanceSort] ? 0 : 1)];
            }
        }
    else
        {
#ifdef DEBUG
        NSLog(@"\tBMLTAppDelegate::displaySearchResults No search results to display.");
#endif
        [self clearAllSearchResultsNo];
        [self sorryCharlie];
        }
    
    _whereAmISearchInProgress = NO;
#ifdef DEBUG
    NSLog(@"BMLTAppDelegate::displaySearchResults end.");
#endif
}

/*****************************************************************/
/**
 \brief This clears the search without resetting the view.
 *****************************************************************/
- (void)simpleClearSearch
{
    searchResults = nil;
    mySearch = nil;
}

/*****************************************************************/
/**
 \brief This sets the search map (iPad only) to the default size and location.
 *****************************************************************/
- (void)setDefaultMapRegion
{
    float   projection = [BMLTVariantDefs initialMapProjection] * 1000.0;
    CLLocationCoordinate2D center = [BMLTVariantDefs mapDefaultCenter];
    
    MKCoordinateRegion  region = MKCoordinateRegionMakeWithDistance(center, projection, projection);
    
#ifdef DEBUG
    NSLog(@"BMLTAppDelegate::setDefaultMapRegion Initializing the map region and center point to the server default.");
#endif
    [self setSearchMapRegion:region];
    [self setSearchMapMarkerLoc:center];
    
    [(A_BMLT_SearchViewController *)searchNavController setUpMap];
}

#pragma mark - Standard Instance Methods -
/*****************************************************************/
/**
 \brief  Initialize the object
 \returns    self
 *****************************************************************/
- (id)init
{
    self = [super init];
    
    if ( self )
        {
        // If we absolutely MUST use a SINGLETON, then it should be done this way.
        static dispatch_once_t just_this_one_time_then;
        dispatch_once ( &just_this_one_time_then, ^{ g_AppDelegate = self; } );
        locationManager = [[CLLocationManager alloc] init];
        [locationManager setDistanceFilter:kCLDistanceFilterNone];
        [locationManager setDelegate:self];
        
        if ( [locationManager respondsToSelector:@selector ( requestWhenInUseAuthorization )] )
            {
            [locationManager requestWhenInUseAuthorization];
            }
        
        searchParams = [[NSMutableDictionary alloc] init];
        mapType = MKMapTypeStandard;
        previousAccuracy = 0;
        }
    
    return self;
}

/*****************************************************************/
/**
 \brief Just make sure that we stop the netmon service and the
        location lookup.
 *****************************************************************/
- (void)dealloc
{
    [searchParams removeAllObjects];
    [self stopNetworkMonitor];
    [locationManager stopUpdatingLocation];
}

/*****************************************************************/
/**
 \brief  Called when the app has finished its launch setup.
 \returns    a BOOL. The app is go for launch.
 *****************************************************************/
- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#ifdef DEBUG
    NSLog(@"BMLTAppDelegate::didFinishLaunchingWithOptions: called.");
#endif
    myPrefs = [BMLT_Prefs getBMLT_Prefs];

    UITabBarController *tabController = (UITabBarController *)self.window.rootViewController;

#ifdef _TESTFLIGHT_
#ifdef DEBUG
    NSLog(@"BMLTAppDelegate::application: didFinishLaunchingWithOptions: TestFlight Startup.");
#endif
    [TestFlight takeOff:kTestFlightTeamToken];
#endif
    
    [tabController setSelectedIndex:kSearchTabIndex];
    [tabController setDelegate:self];
    
    for ( NSInteger i = kSearchTabIndex; i < [[tabController viewControllers] count]; i++ )
        {
        UITabBarItem    *theItem = [[[tabController viewControllers] objectAtIndex:i] tabBarItem];
        [theItem setTitle:NSLocalizedString([theItem title], nil)];
        }
    
    // We keep track of these in private data members for convenience.
    searchNavController = (UINavigationController *)[(UINavigationController *)[[tabController viewControllers] objectAtIndex:kSearchTabIndex] topViewController];
    listResultsViewController = (BMLTDisplayListResultsViewController *)[(UINavigationController *)[[tabController viewControllers] objectAtIndex:kListResultsTabIndex] topViewController];
    mapResultsViewController = (BMLTMapResultsViewController *)[(UINavigationController *)[[tabController viewControllers] objectAtIndex:kMapResultsTabIndex] topViewController];
    
    if ( [BMLTVariantDefs windowBackgroundColor] )
        {
        [[tabController tabBar] setBackgroundColor:[UIColor clearColor]];
        UIColor *myBGColor = [[UIColor alloc] initWithCGColor:[[BMLTVariantDefs windowBackgroundColor] CGColor]];
        [_window setBackgroundColor:myBGColor];

        if ( [[tabController tabBar] respondsToSelector:@selector(setBarTintColor:)] )
            {
            [[tabController tabBar] setBarTintColor:myBGColor];
            [[tabController tabBar] setTintColor:[BMLTVariantDefs barItemTintColor]];
            }
        else
            {
            [[tabController tabBar] setTintColor:myBGColor];
            }
        }

    if ( [[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad )
        {
        settingsViewController = (BMLTSettingsViewController *)[(UINavigationController *)[[tabController viewControllers] objectAtIndex:kSettingsTabIndex] topViewController];
        }
    else
        {
        settingsViewController = nil;
        }
    
    [self clearAllSearchResults:YES];
    [self startNetworkMonitor];
    [self setDefaultMapRegion];
    
    if ( [myPrefs lookupMyLocation] )
        {
#ifdef DEBUG
        NSLog(@"BMLTAppDelegate::setDefaultMapRegion We will update our location.");
#endif
        
        if ( [locationManager respondsToSelector:@selector ( requestWhenInUseAuthorization )] )
            {
            [locationManager requestWhenInUseAuthorization];
            }

        [locationManager startUpdatingLocation];
        }
    
    return YES;
}

/*****************************************************************/
/**
 \brief Called when the app is about to go into the background.
        We suspend the location and network availability updates
        while the app is in the background.
*****************************************************************/
- (void)applicationWillResignActive:(UIApplication *)application
{
#ifdef DEBUG
    NSLog(@"BMLTAppDelegate::applicationWillResignActive called.");
#endif
    _amISick = NO;  // Make sure the user is informed of network outages when they come back.
    [locationManager stopUpdatingLocation]; // Stop updating for now.
}

/*****************************************************************/
/**
 \brief Called when the app is about to show up.
        We renew the updates (check if we have keep location up to
        date pref on before doing that one).
 *****************************************************************/
- (void)applicationWillEnterForeground:(UIApplication *)application
{
#ifdef DEBUG
    NSLog(@"BMLTAppDelegate::applicationWillEnterForeground: called.");
#endif
    
    // If we are not preserving the state (we are resetting the app each time it starts or re-enters the foreground), then we "clear the slate."
    // "_visitingRelatives" means that we don't even twitch. We ran out for some eggs, and we'll be right back.
    if ( ![myPrefs preserveAppStateOnSuspend] && !_visitingRelatives )
        {
#ifdef DEBUG
        NSLog(@"BMLTAppDelegate::applicationWillEnterForeground: The app state will be reset to initial.");
#endif
        [self clearAllSearchResults:YES];
        
        if ( settingsViewController )
            {
#ifdef DEBUG
            NSLog(@"BMLTAppDelegate::applicationWillEnterForeground: popping settings to root view controller.");
#endif
            [[settingsViewController navigationController] popToRootViewControllerAnimated:NO];
            }
        
        [self setDefaultMapRegion];
        
        if ( [myPrefs lookupMyLocation] )
            {
#ifdef DEBUG
            NSLog(@"BMLTAppDelegate::setDefaultMapRegion We will update our location.");
#endif
            
            if ( [locationManager respondsToSelector:@selector ( requestWhenInUseAuthorization )] )
                {
                [locationManager requestWhenInUseAuthorization];
                }

            [locationManager startUpdatingLocation];
            }
        }
    else
        {
#ifdef DEBUG
        NSLog(@"BMLTAppDelegate::applicationWillEnterForeground: The app state will be left completely alone.");
#endif
        _visitingRelatives = NO;    // This means that we won't "freeze" the app state.
        }
    
#ifdef DEBUG
    NSLog(@"BMLTAppDelegate::applicationWillEnterForeground We will start the network monitor update..");
#endif
    [self startNetworkMonitor];
    [self testForEmailAvailability];
}

#pragma mark - Custom Instance Methods -

/*****************************************************************/
/**
 \brief Selects the initial search screen, depending on the user's choice.
 *****************************************************************/
- (void)selectInitialSearchAndForce:(BOOL)force         ///< If YES, then the screen will be set to the default, even if we were already set to one.
{
#ifdef DEBUG
    NSLog(@"BMLTAppDelegate::selectInitialSearchAndForce called.");
#endif
    if ( force )
        {
#ifdef DEBUG
        NSLog(@"BMLTAppDelegate::selectInitialSearchAndForce popping search to root view controller.");
#endif
        
        [[searchNavController navigationController] popToRootViewControllerAnimated:NO];
        
        if ( [myPrefs searchTypePref] == _PREFER_ADVANCED_SEARCH )
            {
            [[searchNavController navigationController] pushViewController:[[[[self window] rootViewController] storyboard] instantiateViewControllerWithIdentifier:@"advanced-search"] animated:NO];
            }
        
        A_BMLT_SearchViewController *topController = (A_BMLT_SearchViewController *)[[searchNavController navigationController] topViewController];
        if ( [searchResults count] )
            {
            [topController addClearSearchButton];
            }
        else
            {
            [[topController navigationItem] setLeftBarButtonItem:nil];
            }
        
        [topController addToggleMapButton];
        }
}

/*****************************************************************/
/**
 \brief This is the base search. Params are passed in.
 *****************************************************************/
- (void)searchForMeetingsNearMe:(CLLocationCoordinate2D)inMyLocation
                     withParams:(NSDictionary *)params 
{
#ifdef DEBUG
    NSLog(@"BMLTAppDelegate::searchForMeetingsNearMe withParams called.");
#endif
    
    if ( [self hostActive] )
        {
        [self setLastSearchParams:params];
        
        // Remember that we have a pref for result count.
        if ( params )
            {
            [self clearAllSearchResults:NO];
            [searchParams removeAllObjects];
            [searchParams setValuesForKeysWithDictionary:params];
            }
        
        // If we are not explicitly defining a radius, we use the default auto-radius
        if ( ![searchParams valueForKey:@"geo_width"] && ![searchParams valueForKey:@"geo_width_km"] )
            {
            [searchParams setObject:[NSString stringWithFormat:@"%d", -[myPrefs resultCount]] forKey:@"geo_width"];
            }
        
#ifdef DEBUG
        NSLog(@"BMLTAppDelegate::searchForMeetingsNearMe withParams called. These are the parameters:");
        
        for(id key in searchParams)
            {
            NSLog(@"key=\"%@\", value=\"%@\"", key, [searchParams objectForKey:key]);
            }
#endif

        [self startAnimations];
        if ( inMyLocation.longitude == 0 && inMyLocation.latitude == 0 )
            {
            _findMeetings = YES;   // This is a semaphore, that tells the app to do a search, once it has settled on a location.
#ifdef DEBUG
            NSLog(@"BMLTAppDelegate::searchForMeetingsNearMe withParams Starting a new location-based search after a lookup.");
#endif
            
            if ( [locationManager respondsToSelector:@selector ( requestWhenInUseAuthorization )] )
                {
                [locationManager requestWhenInUseAuthorization];
                }

            [locationManager startUpdatingLocation];
            }
        else
            {
            [self setSearchMapMarkerLoc:inMyLocation];
            _findMeetings = NO;   // Clear the semaphore.
            // We give the new search our location.
            [searchParams setObject:[NSString stringWithFormat:@"%f", inMyLocation.longitude] forKey:@"long_val"];
            [searchParams setObject:[NSString stringWithFormat:@"%f", inMyLocation.latitude] forKey:@"lat_val"];
#ifdef DEBUG
            NSLog(@"BMLTAppDelegate::searchForMeetingsNearMe withParams Starting a new location-based search immediately.");
#endif
            [self executeSearchWithParams:searchParams];    // Start the search.
            }
        }
    else
        {
        _amISick = NO;  // Make sure the alert is shown.
        [self callInSick];  // Put up an alert, saying that we can't reach the server.
        }
}

/*****************************************************************/
/**
 \brief Begins a lookup search, in which a location is found first,
        then all meetings near there are returned.
 *****************************************************************/
- (void)searchForMeetingsNearMe:(CLLocationCoordinate2D)inMyLocation
{
#ifdef DEBUG
    NSLog(@"BMLTAppDelegate::searchForMeetingsNearMe called.");
#endif
    [self searchForMeetingsNearMe:inMyLocation withParams:nil];
}

/*****************************************************************/
/**
 \brief Looks for the meeting I'm at now.
 *****************************************************************/
- (void)whereTheHellAmI:(CLLocationCoordinate2D)inMyLocation
{
#ifdef DEBUG
    NSLog(@"BMLTAppDelegate::whereTheHellAmI called.");
#endif
    NSDate              *startDate = [NSDate dateWithTimeIntervalSinceNow:-s90Minutes];
    
    NSCalendar          *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents    *weekdayComponents = [gregorian components:(NSCalendarUnitWeekday) fromDate:startDate];
    NSInteger           wd = [weekdayComponents weekday];
    
    weekdayComponents = [gregorian components:(NSCalendarUnitHour) fromDate:startDate];
    NSInteger           hr1 = [weekdayComponents hour];
    weekdayComponents = [gregorian components:(NSCalendarUnitMinute) fromDate:startDate];
    NSInteger           mn1 = [weekdayComponents minute];
    
    startDate = [NSDate dateWithTimeIntervalSinceNow:s90Minutes];
    weekdayComponents = [gregorian components:(NSCalendarUnitHour) fromDate:startDate];
    NSInteger           hr2 = [weekdayComponents hour];
    weekdayComponents = [gregorian components:(NSCalendarUnitMinute) fromDate:startDate];
    NSInteger           mn2 = [weekdayComponents minute];
    
    [searchParams setObject:[NSString stringWithFormat:@"%ld",(long)wd] forKey:@"weekdays"];
    [searchParams setObject:[NSString stringWithFormat:@"%ld",(long)hr1] forKey:@"StartsAfterH"];
    [searchParams setObject:[NSString stringWithFormat:@"%ld",(long)mn1] forKey:@"StartsAfterM"];
    [searchParams setObject:[NSString stringWithFormat:@"%ld",(long)hr2] forKey:@"StartsBeforeH"];
    [searchParams setObject:[NSString stringWithFormat:@"%ld",(long)mn2] forKey:@"StartsBeforeM"];
    [searchParams setObject:[NSString stringWithFormat:@"%f", sHowManyMeters / 1000.0] forKey:@"geo_width_km"];
    
    _whereAmISearchInProgress = YES;
    [self searchForMeetingsNearMe:inMyLocation];
}

/*****************************************************************/
/**
 \brief Same as above, except we only look for meetings later today.
 *****************************************************************/
- (void)searchForMeetingsNearMeLaterToday:(CLLocationCoordinate2D)inMyLocation
{
#ifdef DEBUG
    NSLog(@"BMLTAppDelegate::searchForMeetingsNearMeLaterToday called.");
#endif
    NSDate              *date = [BMLTAppDelegate getLocalDateWithGracePeriod:YES];
    NSCalendar          *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents    *weekdayComponents = [gregorian components:(NSCalendarUnitWeekday) fromDate:date];
    NSInteger           wd = [weekdayComponents weekday];
    weekdayComponents = [gregorian components:(NSCalendarUnitHour) fromDate:date];
    NSInteger           hr = [weekdayComponents hour];
    weekdayComponents = [gregorian components:(NSCalendarUnitMinute) fromDate:date];
    NSInteger           mn = [weekdayComponents minute];
    
    [searchParams setObject:[NSString stringWithFormat:@"%ld",(long)wd] forKey:@"weekdays"];
    [searchParams setObject:[NSString stringWithFormat:@"%ld",(long)hr] forKey:@"StartsAfterH"];
    [searchParams setObject:[NSString stringWithFormat:@"%ld",(long)mn] forKey:@"StartsAfterM"];
    
    [self searchForMeetingsNearMe:inMyLocation];
}

/*****************************************************************/
/**
 \brief Same as above, except we only look for meetings tomorrow.
 *****************************************************************/
- (void)searchForMeetingsNearMeTomorrow:(CLLocationCoordinate2D)inMyLocation
{
#ifdef DEBUG
    NSLog(@"BMLTAppDelegate::searchForMeetingsNearMeTomorrow called.");
#endif
    NSCalendar          *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents    *weekdayComponents = [gregorian components:(NSCalendarUnitWeekday) fromDate:[BMLTAppDelegate getLocalDateWithGracePeriod:NO]];
    NSInteger           wd = [weekdayComponents weekday] + 1;
    
    if ( wd > 7 )
        {
        wd = 1;
        }
    
    [searchParams setObject:[NSString stringWithFormat:@"%ld",(long)wd] forKey:@"weekdays"];
    
    [self searchForMeetingsNearMe:inMyLocation];
}

/*****************************************************************/
/**
 \brief Enables and Disables the UITabBar items in accordance with the current state.
 *****************************************************************/
- (void)setUpTabBarItems
{
    UITabBarController  *tabController = (UITabBarController *)self.window.rootViewController;
    UITabBarItem        *listResultsItem = [[[tabController viewControllers] objectAtIndex:1] tabBarItem];
    UITabBarItem        *mapResultsItem = [[[tabController viewControllers] objectAtIndex:2] tabBarItem];
    
    // If we have valid search results, or there's a search under way, we enable both results tabs.
    if ((searchResults && [searchResults count]) || (mySearch && [mySearch searchInProgress]))
        {
#ifdef DEBUG
        NSLog(@"BMLTAppDelegate::setUpTabBarItems called. We are enabling the search results tabs.");
#endif
        [listResultsItem setEnabled:YES];
        [mapResultsItem setEnabled:YES];
        }
    else
        {
#ifdef DEBUG
        NSLog(@"BMLTAppDelegate::setUpTabBarItems called. We are disabling the search results tabs, and selecting the search tab.");
#endif
        [listResultsItem setEnabled:NO];
        [mapResultsItem setEnabled:NO];
        [tabController setSelectedIndex:kSearchTabIndex];
        }
}

/*****************************************************************/
/**
 \brief Clears all the search results, and the results views.
 *****************************************************************/
- (void)clearAllSearchResults:(BOOL)inForce ///< YES, if we will force the search to switch.
{
    [self simpleClearSearch];
    _whereAmISearchInProgress = NO;
    [locationManager stopUpdatingLocation];
    previousAccuracy = 0;
    
    [mapResultsViewController closeModal];      ///< Make sure we close any open modals or popovers, first.
    [mapResultsViewController dismissListPopover];
    [mapResultsViewController setDataArrayFromData:nil];
    [mapResultsViewController clearMapCompletely];
#ifdef DEBUG
    NSLog(@"BMLTAppDelegate::clearAllSearchResults popping map results to root view controller.");
#endif
    [[mapResultsViewController navigationController] popToRootViewControllerAnimated:NO];
    
    [listResultsViewController closeModal];
    [listResultsViewController setDataArrayFromData:nil];
#ifdef DEBUG
    NSLog(@"BMLTAppDelegate::clearAllSearchResults popping list results to root view controller.");
#endif
    [[listResultsViewController navigationController] popToRootViewControllerAnimated:NO];
    
    [self selectInitialSearchAndForce:inForce];
    
    [(UITabBarController *)self.window.rootViewController setSelectedIndex:kSearchTabIndex]; // Set the tab bar to the search screens.
    [self setUpTabBarItems];
}

/*****************************************************************/
/**
 \brief Clears all the search results, and the results views.
 This version assumes YES, and is a shorthand for the button.
 *****************************************************************/
- (void)clearAllSearchResultsYes
{
    [self clearAllSearchResults:YES];
}

/*****************************************************************/
/**
 \brief Clears all the search results, and the results views.
 This version assumes NO, and is a shorthand for the button.
 *****************************************************************/
- (void)clearAllSearchResultsNo
{
    [self clearAllSearchResults:NO];
}

#ifdef DEBUG
/*****************************************************************/
/**
 \brief Debug-only accessor, so we can log assignment to this data member.
 *****************************************************************/
- (void)setSearchMapMarkerLoc:(CLLocationCoordinate2D)inLocation
{
    NSLog(@"BMLTAppDelegate::setSearchMapMarkerLoc: (%f, %f)", inLocation.latitude, inLocation.longitude);
    _markerLoc = inLocation;
}
#endif

/*****************************************************************/
/**
 \brief Starts the animation.
 *****************************************************************/
- (void)startAnimations
{
    if ( !currentAnimation )
        {
#ifdef DEBUG
        NSLog(@"BMLTAppDelegate::startAnimations pushing new animation.");
#endif
        currentAnimation = [[[[self window] rootViewController] storyboard] instantiateViewControllerWithIdentifier:@"animation-screen"];
        [[currentAnimation navigationItem] setTitle:NSLocalizedString(@"SEARCH-ANIMATION-TITLE", nil)];
        [[searchNavController navigationController] pushViewController:currentAnimation animated:YES];
        [[currentAnimation navigationItem] setHidesBackButton:YES];
        }
}

/*****************************************************************/
/**
 \brief Stops the animation.
 *****************************************************************/
- (void)stopAnimations
{
    if ( currentAnimation )
        {
#ifdef DEBUG
        NSLog(@"BMLTAppDelegate::stopAnimations popping current animation.");
#endif
        [[currentAnimation navigationController] popViewControllerAnimated:NO];
        }
    
    currentAnimation = nil;
}

/*****************************************************************/
/**
 \brief This is called by other instances to prevent the app from
        having its state changed between calls.
        It is a "One-shot" operation that loses persistency between calls.
 *****************************************************************/
- (void)imVisitingRelatives
{
    _visitingRelatives = YES;
}

/*****************************************************************/
/**
 \brief Tells the app to do a CL lookup. The map (if there is one)
        will be updated when the location is updated.
        This will force the map to update, and will set the main
        location to the found location.
 *****************************************************************/
- (void)lookupMyLocationWithAccuracy:(CLLocationAccuracy)accuracy    ///< The desired accuracy
{
    previousAccuracy = 0;
    [locationManager stopUpdatingLocation]; // Just in case we are currently looking...
    // If we need to get a bit fuzzier, we will.
    [locationManager setDesiredAccuracy:accuracy];
    
    if ( [locationManager respondsToSelector:@selector ( requestWhenInUseAuthorization )] )
        {
        [locationManager requestWhenInUseAuthorization];
        }

    [locationManager startUpdatingLocation];
}

/*****************************************************************/
/**
 \brief If there is an external search abort, it is sent here.
 *****************************************************************/
- (void)executeDeferredSearch
{
    deferredSearch = NO;
    [mySearch setDelegate:self];
    [mySearch doSearch];
}

/*****************************************************************/
/**
 \brief This tries successively less accurate location searches.
        If it gives up, then it returns NO.
 \returns a BOOL. NO, if it has given up.
 *****************************************************************/
- (BOOL)tryLocationStaged
{
    BOOL ret = YES;
    
    // In this case, we try again, but at a fuzzier distance
    if ( [locationManager desiredAccuracy] == kCLLocationAccuracyBest )
        {
        [self lookupMyLocationWithAccuracy:kCLLocationAccuracyNearestTenMeters];
        }
    else if ( [locationManager desiredAccuracy] == kCLLocationAccuracyNearestTenMeters )
        {
        [self lookupMyLocationWithAccuracy:kCLLocationAccuracyHundredMeters];
        }
    else if ( [locationManager desiredAccuracy] == kCLLocationAccuracyHundredMeters )
        {
        ret = NO;   // Give up, if we couldn't even get in the ball park.
        }
    
    return ret;
}

#pragma mark - Core Location Delegate Methods -
/*****************************************************************/
/**
 \brief Called when the location manager has a failure.
 *****************************************************************/
- (void)locationManager:(CLLocationManager *)manager    ///< The location manager in troubkle.
       didFailWithError:(NSError *)error                ///< Oh, Lord, the trouble I'm in...
{
    UIAlertView *myAlert = nil;
    
    switch ( [error code] )
        {
        case kCLErrorDenied:    // If denied, we give the user a special error alert, instructing them as to the issue.
            myAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"LOC-ERROR",nil) message:NSLocalizedString(@"LOC-ERROR-DENIED",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK-BUTTON",nil) otherButtonTitles:nil];
            [myAlert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
            break;
        
        case kCLErrorLocationUnknown:   // We can ignore this one.
#ifdef DEBUG
                NSLog(@"BMLTAppDelegate::locationManager: didFailWithError: (kCLErrorLocationUnknown) %@", [error localizedDescription]);
#endif
                break;
        
        case kCLErrorHeadingFailure:    // We don't care about this one. Try again.
#ifdef DEBUG
                NSLog(@"BMLTAppDelegate::locationManager: didFailWithError: (kCLErrorHeadingFailure) %@", [error localizedDescription]);
#endif
                [self lookupMyLocationWithAccuracy:kCLLocationAccuracyBest];
                break;
        
        case kCLErrorDeferredAccuracyTooLow:
#ifdef DEBUG
                NSLog(@"BMLTAppDelegate::locationManager: didFailWithError: (kCLErrorDeferredAccuracyTooLow) %@", [error localizedDescription]);
#endif
            if ( ![self tryLocationStaged] )
                {
                [locationManager stopUpdatingLocation]; // We just give up.
                myAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"LOC-ERROR",nil) message:[error localizedDescription] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK-BUTTON",nil) otherButtonTitles:nil];
                [myAlert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
                }
            break;
        
        default:
#ifdef DEBUG
                NSLog(@"BMLTAppDelegate::locationManager: didFailWithError: %@", [error localizedDescription]);
#endif
            [locationManager stopUpdatingLocation]; // We just give up.
            myAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"LOC-ERROR",nil) message:[error localizedDescription] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK-BUTTON",nil) otherButtonTitles:nil];
            [myAlert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
            break;
        }
    
    [self simpleClearSearch];
    _whereAmISearchInProgress = NO;
}

/*****************************************************************/
/**
 \brief Called when the location manager updates. Makes sure that
        the update is fresh.
 *****************************************************************/
- (void)locationManager:(CLLocationManager *)manager    ///< The localtion manager that is doing the search
     didUpdateLocations:(NSArray *)locations            ///< The latest updated locations.
{
#ifdef DEBUG
    NSLog(@"BMLTAppDelegate::didUpdateLocations:%@", locations);
#endif
    assert ( manager == locationManager );
    
    CLLocation  *newLocation = [locations lastObject];
    
    // NSTimeInterval is a double that contains seconds
    const NSTimeInterval interval = [[newLocation timestamp] timeIntervalSinceNow];
    
    // this is in meters
    const CLLocationAccuracy accuracy = [newLocation horizontalAccuracy];
    
    // if this is less than half a minute old, or if the location isn't getting any better, it's OK for us
    if ( (interval > -30) || (previousAccuracy <= accuracy) )
        {
        [locationManager stopUpdatingLocation]; // Make double sure.
    
#ifdef DEBUG
        NSLog(@"BMLTAppDelegate::didUpdateToLocation I'm at (%f, %f), the horizontal accuracy is %f.", newLocation.coordinate.longitude, newLocation.coordinate.latitude, newLocation.horizontalAccuracy);
#endif
        
        if ( newLocation.coordinate.longitude != 0 && newLocation.coordinate.latitude != 0 )
            {
            [self setSearchMapMarkerLoc:[newLocation coordinate]];
            // Make sure that we have a setup that encourages a location-based meeting search (no current search, and a geo_width that will constrain the search).
            if ( _findMeetings && ([searchParams objectForKey:@"geo_width"] || [searchParams objectForKey:@"geo_width_km"]) )
                {
                // We give the new search our location.
                [searchParams setObject:[NSString stringWithFormat:@"%f", newLocation.coordinate.longitude] forKey:@"long_val"];
                [searchParams setObject:[NSString stringWithFormat:@"%f", newLocation.coordinate.latitude] forKey:@"lat_val"];
#ifdef DEBUG
                NSLog(@"BMLTAppDelegate::didUpdateToLocation: Starting a new location-based search.");
#endif
                [self performSelectorOnMainThread:@selector(executeSearchWithParams:) withObject:searchParams waitUntilDone:YES];
                [self performSelectorOnMainThread:@selector(setUpTabBarItems) withObject:nil waitUntilDone:NO];
                }
            
#ifdef DEBUG
            NSLog(@"BMLTAppDelegate::didUpdateToLocation Setting the marker location to (%f, %f).", newLocation.coordinate.longitude, newLocation.coordinate.latitude);
            NSLog(@"BMLTAppDelegate::didUpdateToLocation Second time around. Stopping the update.");
#endif
            [activeSearchController performSelectorOnMainThread:@selector(updateMap) withObject:nil waitUntilDone:NO];
            
            [self setLastLocation:newLocation]; // Record for posterity
            }
#ifdef DEBUG
        else    // Something's wrong. We cannot be at exactly 0,0. Try again.
            {
            NSLog(@"BMLTAppDelegate::didUpdateToLocation Location Error: (%@)", newLocation);
            
            if ( [locationManager respondsToSelector:@selector ( requestWhenInUseAuthorization )] )
                {
                [locationManager requestWhenInUseAuthorization];
                }

            [locationManager startUpdatingLocation];
            }
#endif
        }
    
    previousAccuracy = accuracy;
}

#pragma mark - UITabBarControllerDelegate code -
/*****************************************************************/
/**
 \brief This animates the view transitions, and also sets up anything
        that needs doing between views. It stops the tab bar controller
        from managing the transition, and does it manually.
 \returns a BOOL. Always NO.
 *****************************************************************/
- (BOOL)tabBarController:(UITabBarController *)inTabBarController
shouldSelectViewController:(UIViewController *)inViewController
{
    int newIndex = (int)[[inTabBarController viewControllers] indexOfObject:inViewController];
    int oldIndex = (int)[inTabBarController selectedIndex];
    
    // This is how we tell the transition routine what effect to use when switching between views.
    // An ascending index means that we are going left to right, and vice-versa.
    // However, we use a different transition when going into the and away from the settings (the last item), so we indicate that.
    int dir = (newIndex == ([[inTabBarController viewControllers] count] - 1)) ? 2 : ((oldIndex == ([[inTabBarController viewControllers] count] - 1)) ? -2 : ((newIndex < oldIndex) ? -1 : ((newIndex == oldIndex) ? 0 : 1)));
    
    if ( dir )  // Don't bother if there's no change.
        {
            // I have no idea why I needed to switch to dot-notation here...
        [self transitionBetweenThisView:[inTabBarController selectedViewController].view andThisView:inViewController.view direction:dir];
        [inTabBarController setSelectedIndex:newIndex];
        }
    
    return NO;  // Let the controller know that we handled it.
}

#pragma mark - Network Monitor Methods -
/*****************************************************************/
/**
 \brief This method starts an asynchronous test of the network,
        ensuring that we can reach the root server. This is running
        continuously, so we will get callbacks to keep us apprised
        of our connectivity status.
 *****************************************************************/
- (void)startNetworkMonitor
{
    [self stopNetworkMonitor];  // We stop first, in order to establish a "clean slate."
    
#ifdef DEBUG
    NSLog(@"BMLTAppDelegate::startNetworkMonitor Starting the network status check.");
#endif
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    // check for internet connection
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStatusCallback:) name:kReachabilityChangedNotification object:nil];
    
    // check if a pathway to our root server exists
    NSURL       *test_uri = [BMLTVariantDefs rootServerURI];
    NSString    *root_uri = [test_uri host];
    
    hostReachable = [Reachability reachabilityWithHostName:root_uri];
    [hostReachable startNotifier];
}

/*****************************************************************/
/**
 \brief This stops the network monitoring service.
 *****************************************************************/
- (void)stopNetworkMonitor
{
#ifdef DEBUG
    NSLog(@"BMLTAppDelegate::stopNetworkMonitor Stopping the network status check.");
#endif
    hostActive = NO;
    [hostReachable stopNotifier];
    hostReachable = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

/*****************************************************************/
/**
 \brief This is the connectivity test callback.
        The BMLT servers will only be instantiated if the network is OK.
        If the network becomes disconnected, the servers will be uninstantiated.
 *****************************************************************/
- (void)networkStatusCallback:(NSNotification *)notice
{
#ifdef DEBUG
    NSLog(@"BMLTAppDelegate::networkStatusCallback: called");
#endif
    
    switch ( [hostReachable currentReachabilityStatus] )
        {
        default:
            {
#ifdef DEBUG
            NSLog(@"BMLTAppDelegate::networkStatusCallback: The gateway to the root server is down.");
#endif
            hostActive = NO;
            
            break;
            }
        
        case ReachableViaWiFi:
            {
#ifdef DEBUG
            NSLog(@"BMLTAppDelegate::networkStatusCallback: A gateway to the root server is working via WIFI.");
#endif
            hostActive = YES;
            [self testForEmailAvailability];
            
            break;
            }
        
        case ReachableViaWWAN:
            {
#ifdef DEBUG
            NSLog(@"BMLTAppDelegate::networkStatusCallback: A gateway to the root server is working via WWAN.");
#endif
            hostActive = YES;
            
            break;
            }
        }
    
    // The driver sets up the servers when we have a connection, and takes them down, when we don't.
    
    NSArray *validServers = [BMLT_Driver getValidServers];
    
    if ( ![validServers count] && hostActive )
        {
#ifdef DEBUG
        NSLog(@"BMLTAppDelegate::networkStatusCallback: The network connection is fine, and we don't have valid servers, so we'll set up the server.");
#endif
        [BMLT_Driver setUpServers];
        }
    else if ( !hostActive )
        {
#ifdef DEBUG
        NSLog(@"BMLTAppDelegate::networkStatusCallback: The network connection is not usable, so we'll make sure we delete our servers.");
#endif
        for ( NSInteger c = [validServers count]; 0 < c; c-- )
            {
            BMLT_Server *server = (BMLT_Server*)[validServers objectAtIndex:c - 1];
            
            if ( server )
                {
                [[BMLT_Driver getBMLT_Driver] removeServerObject:server];
                }
            }
        
        [self callInSick];  // Put up an alert, if one has not already been shown.
        }
    else
        {
#ifdef DEBUG
        NSLog(@"BMLTAppDelegate::networkStatusCallback: The network connection is fine, and we already have valid servers.");
#endif
        }
}

/*****************************************************************/
/**
 \brief This starts a quick connection to a particular file on the
        root server. If the file is there, we will receive either
        "1" or "0". It may also receive a 404 or other error.
 *****************************************************************/
- (void)testForEmailAvailability
{
    if ( [self hostActive] )    // Have to have a server connection.
        {
        NSString    *serverURI = [NSString stringWithFormat:@"%@/client_interface/contact.php", [[BMLTVariantDefs rootServerURI] absoluteString]];
        _hostHasEmailContactCapability = NO;    // We're pessimists.
        
        testEmailURLRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:serverURI] cachePolicy:NSURLRequestReloadRevalidatingCacheData timeoutInterval:sTestEmailURLRequestTimeout];
        
        if ( testEmailURLRequest )
            {
            NSURLResponse   *pResponse;
            NSError         *pError;
            NSData          *pResponseData = [NSURLConnection sendSynchronousRequest:testEmailURLRequest returningResponse:&pResponse error:&pError];
            
            // Immediate failure if the server crapped out.
            if ( pResponseData && !pError )
                {
                // See if we can send email.
                const unsigned char *pdata = [pResponseData bytes];
                unsigned char       value = *pdata;
                _hostHasEmailContactCapability = (1 == [pResponseData length]) && ((unsigned char)'1' == value); // We specifically look for a '1' character. Nothing else.
                }
            }
        }
    else
        {
        _hostHasEmailContactCapability = NO;
        }
}

#pragma mark - SearchDelegate Functions -
/*****************************************************************/
/**
 \brief If there is an external search abort, it is sent here.
 *****************************************************************/
- (void)abortSearch
{
#ifdef DEBUG
    NSLog(@"BMLTAppDelegate::abortSearch called.");
#endif
    [self simpleClearSearch];
    _whereAmISearchInProgress = NO;
}

/*****************************************************************/
/**
 \brief This starts the search going, which is an XML parser
        transaction with the root server. We are the search delegate,
        and will be called upon completion or error.
 *****************************************************************/
- (void)executeSearchWithParams:(NSDictionary *)inSearchParams  ///< These are the search criteria to be sent to the server.
{
    _findMeetings = NO; // Clear the semaphore.
#ifdef DEBUG
    NSLog(@"BMLTAppDelegate::executeSearchWithParams: called.");
#endif
    [locationManager stopUpdatingLocation];
    
    if ( ![self hostHasEmailContactCapability] )    // No need to re-test if we already know we can send comments.
        {
        [self testForEmailAvailability];
        }
    
    [self simpleClearSearch];
    mySearch = [[BMLT_Meeting_Search alloc] initWithCriteria:inSearchParams andName:nil andDescription:nil];
    deferredSearch = YES;
}

/*****************************************************************/
/**
 \brief When the XML parse is complete, we get this call, with the
        complete search results.
        We transfer the search results to our internal property, then
        delete the search, and call the routine that displays the
        search results. On the off chance that we are in another
        thread, we use the main thread call.
 *****************************************************************/
- (void)searchCompleteWithError:(NSError *)inError  ///< If there was an error, it is indicated in this parameter.
{
#ifdef DEBUG
    NSLog(@"BMLTAppDelegate::searchCompleteWithError: %@", (inError ? [inError description] : @"No Errors"));
#endif
    if ( inError )
        {
        [self performSelectorOnMainThread:@selector(clearAllSearchResultsNo) withObject:nil waitUntilDone:YES];
        UIAlertView *myAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"COMM-ERROR",nil) message:[inError localizedDescription] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK-BUTTON",nil) otherButtonTitles:nil];
        [myAlert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
        [self simpleClearSearch];
        _whereAmISearchInProgress = NO;
        }
    else
        {
        searchResults = [mySearch getSearchResults];
        mySearch = nil;
        [searchParams removeAllObjects];
        // Since it is possible we are in another thread, make sure that we call the UI routine in the main thread.
        [self performSelectorOnMainThread:@selector(displaySearchResults) withObject:nil waitUntilDone:YES];
        }
}

/*****************************************************************/
/**
 \brief Simply return the search results.
 \returns a A_BMLT_Search reference, with our internal search results.
 *****************************************************************/
- (A_BMLT_Search *)getSearch
{
    return mySearch;
}

#pragma mark - Special Meeting Sort Sauce -

/*****************************************************************/
/**
 \brief Sort the search results by weekday first, then start time.
 *****************************************************************/
- (void)sortMeetingsByWeekdayAndTime
{
#ifdef DEBUG
    NSLog(@"BMLTAppDelegate::sortMeetingsByWeekdayAndTime called.");
#endif
    searchResults = [[self class] sortMeetingListByWeekdayAndTime:searchResults];
}

/*****************************************************************/
/**
 \brief Sort the meetings by distance first, then weekday, then start time.
 *****************************************************************/
- (void)sortMeetingsByDistance
{
#ifdef DEBUG
    NSLog(@"BMLTAppDelegate::sortMeetingsByDistance called.");
#endif
    searchResults = [[self class] sortMeetingListByDistance:searchResults];
}

/*****************************************************************/
/**
 \brief This toggles the map view between map and satellite.
 *****************************************************************/
- (void)toggleThisMapView:(MKMapView *)theMap               ///< The map view that is being switched.
           fromThisButton:(UIBarButtonItem *)theBarButton   ///< The bar button that is triggering the switch.
{
    if ( theMap )
        {
        if ( !theBarButton )    // If we don't supply a bar button item, then this is not a toggle. It is an initial set.
            {
            [theMap setMapType:[self mapType]];
            }
        else
            {
            [theMap setMapType:([theMap mapType] == MKMapTypeStandard) ? MKMapTypeHybrid : MKMapTypeStandard];
            }
        [self setMapType:[theMap mapType]];
        NSString    *label = NSLocalizedString ( ([self mapType] == MKMapTypeStandard ? @"TOGGLE-MAP-LABEL-SATELLITE" : @"TOGGLE-MAP-LABEL-MAP" ), nil);
        [theBarButton setTitle:label];
        }
}

@end

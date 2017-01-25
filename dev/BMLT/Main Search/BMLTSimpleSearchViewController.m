//
//  BMLTSimpleSearchViewController.m
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

#import "BMLTSimpleSearchViewController.h"
#import "BMLTAppDelegate.h"
#import "BMLT_Prefs.h"

/*****************************************************************/
/**
 \class  BMLTSimpleSearchViewController  -Implementation
 \brief  This class will present the user with a simple "one-button" interface.
 *****************************************************************/
@implementation BMLTSimpleSearchViewController
@synthesize updateLocationButton;
@synthesize disabledTextLabel;
@synthesize overallDescriptionLabel;

@synthesize findMeetingsNearMeButton;
@synthesize findMeetingsLaterTodayButton;
@synthesize findMeetingsTomorrowButton;

/*****************************************************************/
/**
 \brief  Called after the controller's view object has loaded.
 *****************************************************************/
- (void)viewWillAppear:(BOOL)animated
{
    [[self navigationController] setNavigationBarHidden:NO];
    [super viewWillAppear:animated];
    
    if ( ![[[self navigationController] navigationBar] respondsToSelector:@selector(setBarTintColor:)] )
        {
        [[[self navigationItem] rightBarButtonItem] setTintColor:nil];
        }
    
    [[self overallDescriptionLabel] setText:NSLocalizedString(@"SEARCH-SPEC-OVERALL-LABEL-TEXT", nil)];
    [[self findMeetingsNearMeButton] setTitle:NSLocalizedString([[self findMeetingsNearMeButton] titleForState:UIControlStateNormal], nil) forState:UIControlStateNormal];
    [[self findMeetingsLaterTodayButton] setTitle:NSLocalizedString([[self findMeetingsLaterTodayButton] titleForState:UIControlStateNormal], nil) forState:UIControlStateNormal];
    [[self findMeetingsTomorrowButton] setTitle:NSLocalizedString([[self findMeetingsTomorrowButton] titleForState:UIControlStateNormal], nil) forState:UIControlStateNormal];
    [[self updateLocationButton] setTitle:NSLocalizedString([[self updateLocationButton] titleForState:UIControlStateNormal], nil) forState:UIControlStateNormal];
    [[self whereAmIButton] setTitle:NSLocalizedString([[self whereAmIButton] titleForState:UIControlStateNormal], nil) forState:UIControlStateNormal];
    [[self disabledTextLabel] setText:NSLocalizedString([[self disabledTextLabel] text], nil)];
    [[self disabledTextLabel] setAlpha:0.0];
    
    // If there's no way for us to search (We're on an iPhone or iPod Touch with no location services, and we have no map on those devices), then we can't use these buttons.
    if ( ![BMLTAppDelegate locationServicesAvailable] && ![self mapSearchView] )
        {
        [[self findMeetingsNearMeButton] setEnabled:NO];
        [[self findMeetingsLaterTodayButton] setEnabled:NO];
        [[self findMeetingsTomorrowButton] setEnabled:NO];
        [[self disabledTextLabel] setAlpha:1.0];
        }
    
    // If this is the iPhone, we always use the user's current location.
    if ( ![self mapSearchView] )
        {
        [[BMLTAppDelegate getBMLTAppDelegate] setSearchMapMarkerLoc:[[BMLTAppDelegate getBMLTAppDelegate] lastLocation].coordinate];
        }
    
    if ( [[[BMLTAppDelegate getBMLTAppDelegate] searchResults] count] )
        {
        [self addClearSearchButton];
        }
    
    [self addToggleMapButton];
    [super viewWillAppear:animated];
    
    if ( [[BMLT_Prefs getBMLT_Prefs] searchTypePref] == _PREFER_ADVANCED_SEARCH )
        {
        [[BMLTAppDelegate getBMLTAppDelegate] selectInitialSearchAndForce:YES];
        }
}

#pragma mark IB Actions
/*****************************************************************/
/**
 \brief  Find out where we are.
 *****************************************************************/
- (IBAction)whereAmIHit:(id)sender  ///< The object that called this.
{
    BMLTAppDelegate *myAppDelegate = [BMLTAppDelegate getBMLTAppDelegate];  // Get the app delegate SINGLETON
    
    [myAppDelegate clearAllSearchResultsNo];
    
#ifdef DEBUG
    NSLog(@"BMLTSimpleSearchViewController findAllMeetingsNearMeLaterToday.");
#endif
    CLLocationCoordinate2D  location = CLLocationCoordinate2DMake(0.0, 0.0);
    
    if ( [self myMarker] ) // If we have a map view, then we'll take the location from there. If not, we use our current location, so we send a 0 location.
        {
        location = [[self myMarker] coordinate];
        }
    [myAppDelegate whereTheHellAmI:location];
}

/*****************************************************************/
/**
 \brief  Do a simple meeting lookup.
 *****************************************************************/
- (IBAction)findAllMeetingsNearMe:(id)sender    ///< The object that called this.
{
    BMLTAppDelegate *myAppDelegate = [BMLTAppDelegate getBMLTAppDelegate];  // Get the app delegate SINGLETON
    
    [myAppDelegate clearAllSearchResultsNo];
    
#ifdef DEBUG
        NSLog(@"BMLTSimpleSearchViewController findAllMeetingsNearMe.");
#endif
    CLLocationCoordinate2D  location = CLLocationCoordinate2DMake(0.0, 0.0);
    
    if ( [self myMarker] ) // If we have a map view, then we'll take the location from there. If not, we use our current location, so we send a 0 location.
        {
        location = [[self myMarker] coordinate];
        }
    [myAppDelegate searchForMeetingsNearMe:location];
}

/*****************************************************************/
/**
 \brief  Do a simple meeting lookup, for meetings later today.
 *****************************************************************/
- (IBAction)findAllMeetingsNearMeLaterToday:(id)sender    ///< The object that called this.
{
    BMLTAppDelegate *myAppDelegate = [BMLTAppDelegate getBMLTAppDelegate];  // Get the app delegate SINGLETON
    
    [myAppDelegate clearAllSearchResultsNo];

#ifdef DEBUG
        NSLog(@"BMLTSimpleSearchViewController findAllMeetingsNearMeLaterToday.");
#endif
    CLLocationCoordinate2D  location = CLLocationCoordinate2DMake(0.0, 0.0);
    
    if ( [self myMarker] ) // If we have a map view, then we'll take the location from there. If not, we use our current location, so we send a 0 location.
        {
        location = [[self myMarker] coordinate];
        }
    [myAppDelegate searchForMeetingsNearMeLaterToday:location];
}

/*****************************************************************/
/**
 \brief  Do a simple meeting lookup, for meetings tomorrow.
 *****************************************************************/
- (IBAction)findAllMeetingsNearMeTomorrow:(id)sender    ///< The object that called this.
{
    BMLTAppDelegate *myAppDelegate = [BMLTAppDelegate getBMLTAppDelegate];  // Get the app delegate SINGLETON
    
    [myAppDelegate clearAllSearchResultsNo];

#ifdef DEBUG
        NSLog(@"BMLTSimpleSearchViewController findAllMeetingsNearMeTomorrow.");
#endif
    CLLocationCoordinate2D  location = CLLocationCoordinate2DMake(0.0, 0.0);
    
    if ( [self myMarker] ) // If we have a map view, then we'll take the location from there. If not, we use our current location, so we send a 0 location.
        {
        location = [[self myMarker] coordinate];
        }
    [myAppDelegate searchForMeetingsNearMeTomorrow:location];
}
@end

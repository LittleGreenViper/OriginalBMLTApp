//
//  BMLTVariantDefs.m
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

#import "BMLTVariantDefs.h"
#import "BMLTAppDelegate.h"

/******************************************************************/
/**
 \brief  See the "BMLTVariantDefs.h" file for details.
 *****************************************************************/
@implementation BMLTVariantDefs

/*****************************************************************/
+ (NSString *)distanceUnits
{
    NSString    *plistPath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
    
    return [[NSDictionary dictionaryWithContentsOfFile:plistPath] valueForKey:@"BMLTDistanceUnits"];
}

/*****************************************************************/
+ (float)initialMapProjection
{
    NSString    *plistPath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
    
    return [[[NSDictionary dictionaryWithContentsOfFile:plistPath] valueForKey:@"BMLTInitialProjectionSizeInKM"] floatValue];
}

/*****************************************************************/
+ (CLLocationCoordinate2D)mapDefaultCenter;
{
    NSString    *plistPath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
    float       longitude = [[[NSDictionary dictionaryWithContentsOfFile:plistPath] valueForKey:@"BMLTServerHomeLong"] floatValue];
    float       latitude = [[[NSDictionary dictionaryWithContentsOfFile:plistPath] valueForKey:@"BMLTServerHomeLat"] floatValue];
    
    return CLLocationCoordinate2DMake(latitude, longitude);
}

/*****************************************************************/
+ (UIColor *)windowBackgroundColor
{
    return [UIColor colorWithRed:0 green:0 blue:0.7764705882 alpha:1.0];
}

/*****************************************************************/
+ (UIColor *)searchBackgroundColor
{
    return [[self class] windowBackgroundColor];
}

/*****************************************************************/
+ (UIColor *)listResultsBackgroundColor
{
    return [[self class] windowBackgroundColor];
}

/*****************************************************************/
+ (UIColor *)multiMeetingsBackgroundColor
{
    return [UIColor clearColor];
}

/*****************************************************************/
+ (UIColor *)multiMeetingsTextColor
{
    return [UIColor whiteColor];
}

/*****************************************************************/
+ (UIColor *)mapResultsBackgroundColor
{
    return [[self class] windowBackgroundColor];
}

/*****************************************************************/
+ (UIColor *)meetingDetailBackgroundColor
{
    return [UIColor colorWithRed:0.0588235294 green:0.2235294118 blue:0.3647058824 alpha:1.0];
}

/*****************************************************************/
+ (UIColor *)modalBackgroundColor
{
    return [UIColor colorWithRed:0.0666666667 green:0.2392156863 blue:0.6470588235 alpha:1.0];
}

/*****************************************************************/
+ (UIColor *)popoverBackgroundColor
{
    return [[self class] modalBackgroundColor];
}

/*****************************************************************/
+ (UIColor *)settingsBackgroundColor
{
    return [[self class] meetingDetailBackgroundColor];
}

/*****************************************************************/
+ (UIColor *)infoBackgroundColor
{
    return [[self class] windowBackgroundColor];
}

/*****************************************************************/
+ (UIColor *)getSortOddColor
{
    return [UIColor whiteColor];
}

/*****************************************************************/
+ (UIColor *)getSortEvenColor
{
    return [UIColor colorWithRed:0.9960784314 green:0.8941176471 blue:0.3568627451 alpha:1.0];
}

/*****************************************************************/
+ (CGSize)pdfPageSize
{
    return CGSizeMake(612, 792);
}

/*****************************************************************/
+ (NSString *)pdfTempFileNameFormat
{
    return @"BMLTPDFTemp_%d.pdf";
}

/*****************************************************************/
+ (NSURL *)rootServerURI
{
    NSString    *plistPath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
    NSString    *uriString = [[NSDictionary dictionaryWithContentsOfFile:plistPath] valueForKey:@"BMLTRootServerURI"];
    return [NSURL URLWithString:uriString];
}

/*****************************************************************/
+ (NSURL *)directionsURITo:(CLLocationCoordinate2D)inTo   ///< The long/lat of wehere we are going
{
    NSURL       *ret = nil;
    CLLocation  *lastLoc = [[BMLTAppDelegate getBMLTAppDelegate] lastLocation];
    
    if ( lastLoc )  // If we know where we are, then we add that to the URI, for a richer user experience.
        {
        ret = [NSURL URLWithString:[NSString stringWithFormat:NSLocalizedString(@"DIRECTIONS-URI-FORMAT-ACCURATE",nil), lastLoc.coordinate.latitude, lastLoc.coordinate.longitude, inTo.latitude, inTo.longitude]];
        }
    else    // Otherwise, we let the user figger it out when they get to the page.
        {
        ret = [NSURL URLWithString:[NSString stringWithFormat:NSLocalizedString(@"DIRECTIONS-URI-FORMAT",nil), inTo.latitude, inTo.longitude]];
        }
    
    return ret;
}

/*****************************************************************/
+ (NSInteger)maxNumberOgMeetings
{
    return 500;
}

/*****************************************************************/
+ (NSString *)reverseLookupURIFormat
{
    return @"http://maps.google.com/maps/geo?q=%@&output=xml&sensor=false";
}
@end

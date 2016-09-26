//
//  BMLT_Prefs.m
//  BMLT
//
//  Created by MAGSHARE
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
/*****************************************************************/
/**
 \file  BMLT_Prefs.m
 \brief This file implements two preferences classes for the BMLT
        app. One, is a preference for a single server connection,
        and the other is a global SINGLETON instance with all of the
        prefs.
 *****************************************************************/

#import "BMLT_Prefs.h"
#import <CoreLocation/CoreLocation.h>

static  BMLT_Prefs  *s_thePrefs = nil;    ///< The SINGLETON instance.

static int BMLT_Pref_Default_Value_Grace_Period = 15;   ///< The default grace period, in minutes for a meeting to be declared "too late."

/*****************************************************************/
/**
 \class BMLT_Prefs
 \brief This class is a preference for a single server connection.
 *****************************************************************/
@implementation BMLT_ServerPref

/*****************************************************************/
/**
 \brief     Initialize an instance of BMLT_ServerPref with some initial data.
            The URI is saved as a string.
 \returns   self
 *****************************************************************/
- (id)initWithURI:(NSString *)inURI             ///< The URI to the root server
          andName:(NSString *)inName            ///< The name of the server
   andDescription:(NSString *)inDescription     ///< A longer description of the server
{
    self = [super init];
    
    if ( self )
        {
        [self setServerURI:inURI];
        [self setServerName:inName];
        [self setServerDescription:inDescription];
        }
    
    return self;
}

/*****************************************************************/
/**
 \brief     Initialize an instance of BMLT_ServerPref from an NSCoder
 \returns   self
 *****************************************************************/
-(id)initWithCoder:(NSCoder *)decoder   ///< The decoder with the stored data.
{
    self = [super init];
    
    if ( self && decoder )
        {
        serverName = [decoder decodeObjectForKey:@"serverName"];
        serverDescription = [decoder decodeObjectForKey:@"serverDescription"];
        serverURI = [decoder decodeObjectForKey:@"serverURI"];
        }
    
    return self;
}

/*****************************************************************/
/**
 \brief Saves the state to an NSCoder
 *****************************************************************/
-(void)encodeWithCoder:(NSCoder *)encoder   ///< The coder that will receive the data
{
    [encoder encodeObject:serverName forKey:@"serverName"];
    [encoder encodeObject:serverDescription forKey:@"serverDescription"];
    [encoder encodeObject:serverURI forKey:@"serverURI"];
}

/*****************************************************************/
/**
 \brief Sets the root server URI
 *****************************************************************/
- (void)setServerURI:(NSString *)inURI  ///< The URI, as a string
{
    serverURI = inURI;
}

/*****************************************************************/
/**
 \brief Set the server name.
 *****************************************************************/
- (void)setServerName:(NSString *)inName    ///< The name of the server
{
    serverName = inName;
}

/*****************************************************************/
/**
 \brief Set the server description
 *****************************************************************/
- (void)setServerDescription:(NSString *)inDescription  ///< The server description
{
    serverDescription = inDescription;
}

/*****************************************************************/
/**
 \brief Returns the URI as a string
 \returns a string, containing the textual URI.
 *****************************************************************/
- (NSString *)getServerURI
{
    return serverURI;
}

/*****************************************************************/
/**
 \brief Get the server name
 \returns a string, containing the server name.
 *****************************************************************/
- (NSString *)getServerName
{
    return serverName;
}

/*****************************************************************/
/**
 \brief Get the server description
 \returns a string, containing the server description.
 *****************************************************************/
- (NSString *)getServerDescription
{
    return serverDescription;
}

@end

/*****************************************************************/
/**
 \class BMLT_Prefs
 \brief This class is a global SINGLETON instance with all of the
        prefs.
 *****************************************************************/
@implementation BMLT_Prefs

/*****************************************************************/
/**
 \brief This gets the SINGLETON instance, and creates one, if necessary.
 \returns a reference to a BMLT_Prefs object, whic is the SINGLETON.
 *****************************************************************/
+ (BMLT_Prefs *)getBMLT_Prefs
{
    // This whackiness just makes sure the prefs singleton is thread-safe.
    static dispatch_once_t pred;
    
    dispatch_once(&pred,
        ^{
#ifdef DEBUG
            NSLog(@"BMLT_Prefs getBMLT_Prefs Trying unarchiving");
#endif
            s_thePrefs = [NSKeyedUnarchiver unarchiveObjectWithFile:[BMLT_Prefs docPath]];
            
            if ( !s_thePrefs )
                {
#ifdef DEBUG
                NSLog(@"BMLT_Prefs getBMLT_Prefs Unarchiving didn't work. Allocating anew");
#endif
                s_thePrefs = [[BMLT_Prefs alloc] init];
                NSString    *serverName = NSLocalizedString(@"INITIAL-SERVER-NAME", nil);
                NSString    *serverDescription = NSLocalizedString(@"INITIAL-SERVER-DESCRIPTION", nil);
                NSString    *serverURI = [[BMLTVariantDefs rootServerURI] absoluteString];
                
#ifdef DEBUG
                NSLog(@"BMLT_Prefs getBMLT_Prefs Adding the default server.");
#endif
                [s_thePrefs addServerWithURI:serverURI
                                     andName:serverName
                              andDescription:serverDescription];
                }
        });
    
    return s_thePrefs;
}

/*****************************************************************/
/**
 \brief Returns the path to the prefs storage locker in the app sandbox.
 \returns a string, containing the doc path with the file name.
 *****************************************************************/
+ (NSString *)docPath
{
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [documentDirectories objectAtIndex:0];
    return [documentDirectory stringByAppendingPathComponent:@"BMLT.data"];
}

/*****************************************************************/
/**
 \brief Returns the number of servers available (usually 1).
 \returns an integer. The number of server objects.
 *****************************************************************/
+ (NSInteger)getServerCount
{
    return [[BMLT_Prefs getServers] count];
}

/*****************************************************************/
/**
 \brief Get the instance of a server object at the given index.
 \returns a reference to an instance of BMLT_ServerPref.
 *****************************************************************/
+ (BMLT_ServerPref *)getServerAt:(NSInteger)inIndex ///< The 0-based index of the server pref.
{
    return (BMLT_ServerPref *)[[BMLT_Prefs getServers] objectAtIndex:inIndex];
}

/*****************************************************************/
/**
 \brief returns an array of all the available BMLT_ServerPref objects.
 \returns an array of all the available BMLT_ServerPref objects.
 *****************************************************************/
+ (NSArray *)getServers
{
    return [s_thePrefs servers];
}

/*****************************************************************/
/**
 \brief Returns YES, if the pref for starting with map search is on.
 \returns a boolean, with the state of the pref. YES means start with map search.
 *****************************************************************/
+ (BOOL)getStartWithMap
{
    return [s_thePrefs startWithMap];
}

/*****************************************************************/
/**
 \brief Returns YES, if the user prefers distance sorting for list searches.
 \returns a boolean with YES meaning sort by distance to start.
 *****************************************************************/
+ (BOOL)getPreferDistanceSort
{
    return [s_thePrefs preferDistanceSort];
}

/*****************************************************************/
/**
 \brief Returns YES, if the user wants to look up their location upon startup.
 \returns a boolean. YES means look up on start up.
 *****************************************************************/
+ (BOOL)getLookupMyLocation
{
    return [s_thePrefs lookupMyLocation];
}

/*****************************************************************/
/**
 \brief Returns YES, if the user wants to start a search upon startup.
 \returns a boolean. YES means start up with a search.
 *****************************************************************/
+ (BOOL)getStartWithSearch
{
    return [s_thePrefs startWithSearch];
}

/*****************************************************************/
/**
 \brief Returns YES, if the user wants to start new searches as advanced.
 \returns a boolean. YES means start new searches as advanced.
 *****************************************************************/
+ (BOOL)getPreferAdvancedSearch
{
    return [s_thePrefs preferAdvancedSearch];
}

/*****************************************************************/
/**
 \brief returns the "meeting missed" grace period. This is how many
        minutes must pass before the meeting is not listed in the
        "find nearby meetings now" search.
 \returns an integer, with the number of minutes allowed.
 *****************************************************************/
+ (int)getGracePeriod
{
    return [s_thePrefs gracePeriod];
}

/*****************************************************************/
/**
 \brief Get the name entered by the user for sending emails.
 \returns The name.
 *****************************************************************/
+ (NSString*)getEmailSenderName
{
    return [s_thePrefs emailSenderName];
}

/*****************************************************************/
/**
 \brief Get the email address entered by the user for sending emails.
 \returns The address.
 *****************************************************************/
+ (NSString*)getEmailSenderAddress
{
    return [s_thePrefs emailSenderAddress];
}

/*****************************************************************/
/**
 \brief Save the changes into the prefs persistent storage.
 *****************************************************************/
+ (void)saveChanges
{
    if ( s_thePrefs )
        {
#ifdef DEBUG
        NSLog(@"BMLT_Prefs saveChanges saving to %@.", [BMLT_Prefs docPath]);
#endif
        [NSKeyedArchiver archiveRootObject:s_thePrefs toFile:[BMLT_Prefs docPath]];
        }
}

/*****************************************************************/
/**
 \brief Check to make sure that Location Services are available
 \returns YES, if Location Services are available
 *****************************************************************/
+(BOOL)locationServicesAvailable
{
    return [CLLocationManager locationServicesEnabled] != NO && [CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied;
}

/*****************************************************************/
/**
 \brief Validate a given string as an email address (full RFC compliance).
        Got this from here: https://github.com/benmcredmond/DHValidation
 \returns YES, if the email address is valid.
 *****************************************************************/
+ (BOOL)isValidEmailAddress:(NSString *)inEmailAddress  ///< The email address to validate.
{
    NSString *emailRegex =  @"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
                            @"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
                            @"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
                            @"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
                            @"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
                            @"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
                            @"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";
    
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES[c] %@", emailRegex];
    
    return [emailTest evaluateWithObject:inEmailAddress];
}

/*****************************************************************/
/**
 \brief URL-encodes a string.
        This was culled from here: http://stackoverflow.com/questions/8086584/objective-c-url-encoding
 \returns a URL-encoded version of the given string.
 *****************************************************************/
+ (NSString *)getURLEncodedString:(NSString*)inString   ///< The string to be encoded.
{
    NSMutableString *output = [NSMutableString string];
    const char      *source = [inString UTF8String];
    
    size_t sourceLen = strlen ( source );
    
    for ( int i = 0; i < sourceLen; ++i )
        {
        const unsigned char thisChar = (const unsigned char)source[i];
        if ( false && thisChar == ' ' )
            {
            [output appendString:@"+"];
            }
        // Check to see if this is a low-order UTF-8, or an extended one.
        else if ( thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' ||
                   (thisChar >= 'a' && thisChar <= 'z') ||
                   (thisChar >= 'A' && thisChar <= 'Z') ||
                   (thisChar >= '0' && thisChar <= '9') )
            {
            [output appendFormat:@"%c", thisChar];
            }
        else
            {
            [output appendFormat:@"%%%02X", thisChar];
            }
        }
    
    return output;
}

/*****************************************************************/
/**
 \brief Initializer from a coder.
 \returns self
 *****************************************************************/
-(id)initWithCoder:(NSCoder *)decoder   ///< The decoder with the stored state.
{
    self = [super init];
    
    if ( self )
        {
        servers = nil;
        
        if ( decoder )
            {
            servers = [decoder decodeObjectForKey:@"servers"];
            
            if ( [decoder containsValueForKey:@"startWithMap"] )
                {
                _startWithMap = [decoder decodeBoolForKey:@"startWithMap"];
                }
            else
                {
                [self setStartWithMap:([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)];  // iPad starts with map preference.
                }
            
            if ( [decoder containsValueForKey:@"preferDistanceSort"] )
                {
                _preferDistanceSort = [decoder decodeBoolForKey:@"preferDistanceSort"];
                }
            else
                {
                [self setPreferDistanceSort:NO];
                }
            
            if ( [decoder containsValueForKey:@"lookupMyLocation"] )
                {
                _lookupMyLocation = [decoder decodeBoolForKey:@"lookupMyLocation"];
                }
            else
                {
                [self setLookupMyLocation:YES];
                }
            
            if ( [decoder containsValueForKey:@"gracePeriod"] )
                {
                _gracePeriod = [decoder decodeIntForKey:@"gracePeriod"];
                }
            else
                {
                [self setGracePeriod:BMLT_Pref_Default_Value_Grace_Period];
                }
            
            if ( [decoder containsValueForKey:@"startWithSearch"] )
                {
                _startWithSearch = [decoder decodeBoolForKey:@"startWithSearch"];
                }
            else
                {
                [self setStartWithSearch:YES];
                }
            
            if ( [decoder containsValueForKey:@"preferAdvancedSearch"] )
                {
                _preferAdvancedSearch = [decoder decodeBoolForKey:@"preferAdvancedSearch"];
                }
            else
                {
                [self setPreferAdvancedSearch:NO];
                }
            
            if ( [decoder containsValueForKey:@"searchTypePref"] )
                {
                _searchTypePref = [decoder decodeIntForKey:@"searchTypePref"];
                }
            else
                {
                [self setSearchTypePref:([self preferAdvancedSearch] ? _PREFER_ADVANCED_SEARCH : _PREFER_SIMPLE_SEARCH)];
                }
            
            if ( [decoder containsValueForKey:@"preferSearchResultsAsMap"] )
                {
                _preferSearchResultsAsMap = [decoder decodeBoolForKey:@"preferSearchResultsAsMap"];
                }
            else
                {
                [self setPreferSearchResultsAsMap:[self startWithMap]];
                }
            
            if ( [decoder containsValueForKey:@"preserveAppStateOnSuspend"] )
                {
                _preserveAppStateOnSuspend = [decoder decodeBoolForKey:@"preserveAppStateOnSuspend"];
                }
            else
                {
                [self setPreserveAppStateOnSuspend:![self startWithSearch]];
                }
            
            if ( [decoder containsValueForKey:@"preserveAppStateOnSuspend"] )
                {
                _keepUpdatingLocation = [decoder decodeBoolForKey:@"keepUpdatingLocation"];
                }
            else
                {
                [self setKeepUpdatingLocation:NO];
                }
            
            if ( [decoder containsValueForKey:@"resultCount"] )
                {
                _resultCount = [decoder decodeIntForKey:@"resultCount"];
                }
            else
                {
                [self setResultCount:10];
                }
            
            if ( [decoder containsValueForKey:@"emailName"] )
                {
                _emailSenderName = [decoder decodeObjectForKey:@"emailName"];
                }
            else
                {
                [self setEmailSenderName:@""];
                }
            
            if ( [decoder containsValueForKey:@"emailAddress"] )
                {
                _emailSenderAddress = [decoder decodeObjectForKey:@"emailAddress"];
                }
            else
                {
                [self setEmailSenderAddress:@""];
                }
            }
        else
            {
            [self setStartWithMap:([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)];  // iPad defaults to map search.
            [self setPreferDistanceSort:NO];
            [self setLookupMyLocation:YES];
            [self setGracePeriod:BMLT_Pref_Default_Value_Grace_Period];
            [self setStartWithSearch:YES];
            [self setPreferAdvancedSearch:NO];
            [self setSearchTypePref:([self preferAdvancedSearch] ? _PREFER_ADVANCED_SEARCH : _PREFER_SIMPLE_SEARCH)];
            [self setPreferSearchResultsAsMap:[self startWithMap]];
            [self setPreserveAppStateOnSuspend:![self startWithSearch]];
            [self setKeepUpdatingLocation:NO];
            [self setResultCount:10];
            [self setEmailSenderName:@""];
            [self setEmailSenderAddress:@""];
            }
        }
    
    return self;
}

/*****************************************************************/
/**
 \brief Returns the array of servers from prefs.
 \returns a array of BMLT_Server objects.
 *****************************************************************/
- (NSArray *)servers
{
    return servers;
}

/*****************************************************************/
/**
 \brief Creates a new server, with the given root URI and name.
 \returns an integer. The index of the new server object.
 *****************************************************************/
- (NSInteger)addServerWithURI:(NSString *)inURI             ///< The URI of the root server
                      andName:(NSString *)inName            ///< The name of the server
               andDescription:(NSString *)inDescription;    ///< A textual description of the server
{
    NSInteger   ret = -1;
    
    if ( inURI )
        {
        ret = 0;
        if ( !servers )
            {
            servers = [[NSMutableArray alloc] init];
            }
        else
            {
            for ( BMLT_ServerPref *serverPref in servers )
                {
                if ( NSOrderedSame == ([[serverPref getServerURI] caseInsensitiveCompare:inURI]) )
                    {
                    ret = -1;
                    break;
                    }
                
                ret++;
                }
            }
    
        BMLT_ServerPref *server_pref = [[BMLT_ServerPref alloc] init];
        [server_pref setServerURI:inURI];
        [server_pref setServerName:inName];
        [server_pref setServerDescription:inDescription];
        
        [servers addObject:server_pref];
        }
    
    return ret;
}

/*****************************************************************/
/**
 \brief Deletes the server at the given root URI.
 \returns a boolean. YES if successful.
 *****************************************************************/
- (BOOL)removeServerWithURI:(NSString *)inURI   ///< The URI of the server to delete.
{
    BOOL    ret = NO;
    
    if ( inURI )
        {
        if ( servers )
            {
            NSInteger count = [servers count];
            for ( NSInteger index = 0; index < count; index++ )
                {
                BMLT_ServerPref *server_pref = (BMLT_ServerPref *)[servers objectAtIndex:index];
                if ( NSOrderedSame == ([[server_pref getServerURI] caseInsensitiveCompare:inURI]) )
                    {
                    [servers removeObjectAtIndex:index];
                    ret = YES;
                    break;
                    }
                }
            }
        }
    
    return ret;
}

/*****************************************************************/
/**
 \brief Store into an encoder
 *****************************************************************/
-(void)encodeWithCoder:(NSCoder *)encoder   ///< The encoder that will receive the stored state.
{
    [encoder encodeObject:servers forKey:@"servers"];
    [encoder encodeBool:[self startWithMap] forKey:@"startWithMap"];
    [encoder encodeBool:[self preferDistanceSort] forKey:@"preferDistanceSort"];
    [encoder encodeBool:[self lookupMyLocation] forKey:@"lookupMyLocation"];
    [encoder encodeInt:[self gracePeriod] forKey:@"gracePeriod"];
    [encoder encodeBool:[self startWithSearch] forKey:@"startWithSearch"];
    [encoder encodeBool:[self preferAdvancedSearch] forKey:@"preferAdvancedSearch"];
    [encoder encodeInt:[self searchTypePref] forKey:@"searchTypePref"];
    [encoder encodeBool:[self preferSearchResultsAsMap] forKey:@"preferSearchResultsAsMap"];
    [encoder encodeBool:[self preserveAppStateOnSuspend] forKey:@"preserveAppStateOnSuspend"];
    [encoder encodeBool:[self keepUpdatingLocation] forKey:@"keepUpdatingLocation"];
    [encoder encodeInt:[self resultCount] forKey:@"resultCount"];
    [encoder encodeObject:[self emailSenderName] forKey:@"emailName"];
    [encoder encodeObject:[self emailSenderAddress] forKey:@"emailAddress"];
}
@end

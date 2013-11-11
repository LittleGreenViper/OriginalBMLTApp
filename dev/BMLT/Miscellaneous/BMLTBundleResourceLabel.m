//
//  BMLTGetInfoLabel.m
//  BMLT
//
//  Created by MAGSHARE.
//  Copyright 2012 MAGSHARE. All rights reserved.
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

#import "BMLTBundleResourceLabel.h"

/*****************************************************************/
/**
 \class BMLTGetInfoLabel
 \brief This class implements a label that displays the Get Info String.
        This allows a transparent name display that can be easily
        formatted.
 *****************************************************************/
@implementation BMLTBundleResourceLabel

/*****************************************************************/
/**
 \brief Initializer -Grabs the string, and sets it as the display.
 \returns self
 *****************************************************************/
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
        {
        NSString    *plistPath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
        NSString    *appInfo = [[NSDictionary dictionaryWithContentsOfFile:plistPath] valueForKey:[self text]];
        [self setText:appInfo];
        }
    return self;
}
@end
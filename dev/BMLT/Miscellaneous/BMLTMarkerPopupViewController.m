//
//  BMLTMarkerPopupViewController.m
//  BMLT
//
//  Created by MAGSHARE.
//  Copyright 2013 MAGSHARE. All rights reserved.
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

#import "BMLTMarkerPopupViewController.h"

/***************************************************************************/
/**
 \class BMLTMarkerPopupViewController
 \brief This is the controller for the annotation popup that comes up over the black annotation
        in the map results view when tapped.
 */
@interface BMLTMarkerPopupViewController ()

@end

@implementation BMLTMarkerPopupViewController

/***************************************************************************/
/**
 \brief Basic initializer
        This will be the one used most. We establish a context (container)
        and a target (the view that is pointed to). The controller and the
        view will figure out the layout from there.
 */
- (id)initWithTargetView:(UIView*)inTargetView  ///< The view that is pointed to
          andContextView:(UIView*)inContextView ///< The context in which this popup will appear
          andContentView:(UIView*)inContentView ///< The view that will go inside this one.
{
    self = [super init];
    if (self)
    {
        _targetView = inTargetView;
        _contextView = inContextView;
        _contentsSubview = inContentView;
    }
    return self;
}

@end

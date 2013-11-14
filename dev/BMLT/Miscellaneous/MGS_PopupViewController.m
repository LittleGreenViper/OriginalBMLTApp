//
//  MGS_PopupViewController.m
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

#import "MGS_PopupViewController.h"
#import "MGS_PopupView.h"

static const float  s_BaseArrowWidthInPixels    = 16.0; ///< This is how wide (or tall) the base of the arrow will be.
static const float  s_ArrowLengthInPixels       = 16.0; ///< This is how far out it will stick from the 
static const float  s_PaddingInPixels           = 4.0;  ///< This is how much "breathing room" the contents will get.

/***************************************************************************/
/**
 \class MGS_PopupViewController
 \brief This is the controller for the annotation popup that comes up over the black annotation
        in the map results view when tapped.
 */
@interface MGS_PopupViewController ()
- (BMLT_PopupMetrics)pm_calculatePopupFrame;
@end

@implementation MGS_PopupViewController

/***************************************************************************/
/**
 \brief Basic initializer
        This will be the one used most. We establish a context (container)
        and a target (the view that is pointed to). The controller and the
        view will figure out the layout from there.
 */
- (id)initWithTargetView:(UIView*)inTargetView  ///< The view that is pointed to
          andContentView:(UIView*)inContentView ///< The view that will go inside this one.
{
    self = [super init];
    if (self)
        {
        _targetView = inTargetView;
        _contextView = [inTargetView superview];
        _contentsSubview = inContentView;
        }
    return self;
}

/***************************************************************************/
/**
 \brief Calculate the metrics for the popup view.
 \returns a BMLT_PopupMetrics struct, containing the metrics used for the popup.
 */
- (BMLT_PopupMetrics)pm_calculatePopupFrame;
{
    BMLT_PopupMetrics   ret = { CGRectZero, CGPointZero };
    
    ret.arrowBaseWidth = s_BaseArrowWidthInPixels;
    ret.arrowLength = s_ArrowLengthInPixels;
    // Start with a frame that is in the upper left, and big enough for the contents.
    ret.popupViewFrame = CGRectInset ( [[self contentsSubview] bounds], -s_PaddingInPixels, -s_PaddingInPixels );
    
    // Get the thing that we're pointing at, and the context that we share.
    CGRect  targetFrame = [[self targetView] frame];
    CGSize  contextSize = [[self contextView] bounds].size;
    
    // We will want to pop up above the target, if at all possible. We allow the popup to cover up to half the target.
    CGRect  frameAbove = CGRectMake ( 0, 0, contextSize.width, ((targetFrame.origin.y + (targetFrame.size.height / 2.0)) - s_ArrowLengthInPixels) );
    
    CGRect  popupFrameContainer = CGRectZero;
    
    // Make sure that we can fit inside the area above the target.
    if ( CGRectContainsRect ( frameAbove, ret.popupViewFrame ) )
        {
        popupFrameContainer = frameAbove;
        }
    else // The next choice is to the right.
        {
        CGRect  frameRight = CGRectMake ( (targetFrame.origin.x + targetFrame.size.width + s_ArrowLengthInPixels), 0, contextSize.width - (targetFrame.origin.x + targetFrame.size.width + s_ArrowLengthInPixels), contextSize.height );
            
        if ( CGRectContainsRect ( frameRight, CGRectOffset ( ret.popupViewFrame, (targetFrame.origin.x + targetFrame.size.width + s_ArrowLengthInPixels), 0 ) ) )
            {
            popupFrameContainer = frameRight;
            }
        else // The next choice is to the left.
            {
            CGRect  frameLeft = CGRectMake ( 0, 0, (targetFrame.origin.x - s_ArrowLengthInPixels), contextSize.height );
            
            if ( CGRectContainsRect ( frameLeft, ret.popupViewFrame ) )
                {
                popupFrameContainer = frameLeft;
                }
            else // The last choice is from the bottom.
                {
                CGRect  frameBelow = CGRectMake ( 0, (targetFrame.origin.y + targetFrame.size.height + s_ArrowLengthInPixels), contextSize.width, contextSize.height - (targetFrame.origin.y + targetFrame.size.height + s_ArrowLengthInPixels) );
                    
                popupFrameContainer = frameBelow;
                }
            }
        }
    
    // OK. At this point, we know what part of the screen will contain the popup. We now actually determine its frame within that area.
    
    // First, we ensure that the container will actually fit the popup. If not, we don't draw anything.
    
    CGRect compRect = popupFrameContainer;
    
    compRect.origin = CGPointZero;  // We zero the origin, so the rects will be comparable.
    
    // We don't worry about the arrow, because we can afford a bit of "slop," here.
    if ( CGRectContainsRect ( compRect, ret.popupViewFrame ) )
        {
        // We know that we will fit. Time to start calculating the "nitty gritty."
        
        // Our first choice is directly above the target, centered.
        CGFloat left = (targetFrame.origin.x + (targetFrame.size.width / 2.0)) - (ret.popupViewFrame.size.width / 2.0);
        CGFloat top = targetFrame.origin.y - (ret.popupViewFrame.size.height + ret.arrowLength);
        
        if ( top < 0 )  // If we need to, we can cover up to half the target.
            {
            if ( (targetFrame.origin.y + (targetFrame.size.height / 2.0)) - (ret.popupViewFrame.size.height + ret.arrowLength) >= 0 )
                {
                top = 0;
                }
            }
        
        // If we fit entirely within the frame...
        if ( (left >= 0) && (top >= 0) && ((left + ret.popupViewFrame.size.width) <= popupFrameContainer.size.width) )
            {
            
            }
        }
    
    return ret;
}
@end

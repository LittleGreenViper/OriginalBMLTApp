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
static const float  s_PaddingInPixels           = 1.0;  ///< This is how much "breathing room" the contents will get.

/***************************************************************************/
/**
 \class MGS_PopupViewController
 \brief This is the controller for the annotation popup that comes up over the black annotation
        in the map results view when tapped.
 */
@interface MGS_PopupViewController ()
@property   (atomic, strong, readwrite) UITapGestureRecognizer  *p_tapper; ///< This will be a gesture recognizer that we'll add to the container. We trap taps, and close the popup.

+ (MGS_PopupMetrics)pm_calculateArrow:(MGS_PopupMetrics)inMetrics andTarget:(UIView*)inTarget;

- (void)pm_setUp;
- (MGS_PopupMetrics)pm_calculatePopupFrame;
@end

@implementation MGS_PopupViewController

/***************************************************************************/
/**
 \brief Calculate the metrics for the popup, taking into account the position of the target view.
 \returns a BMLT_PopupMetrics struct, containing the metrics used for the popup.
 */
+ (MGS_PopupMetrics)pm_calculateArrow:(MGS_PopupMetrics)inMetrics ///< The current metrics of the popup (to be rounded out by this function)
                             andTarget:(UIView*)inTarget            ///< The target view, so we can take its measure.
{
#ifdef DEBUG
    NSLog ( @"\r----------------------------------------------\rMGS_PopupViewController::pm_calculateArrow:andTarget:andDirection:\r----------------------------------------------\r" );
#endif
    switch ( inMetrics.direction )
        {
        case MGS_PopupDirectionEnum_Top:
            {
#ifdef DEBUG
            NSLog ( @"MGS_PopupViewController::pm_calculateArrow:andTarget: -Top Section Selected" );
#endif
            CGFloat top = [inTarget frame].origin.y - (inMetrics.popupViewFrame.size.height + inMetrics.arrowLength);
            if ( top < 0 )
                {
                top = 0;
                }
            
            // We try to center. If we can't, we'll offset.
            CGFloat left = ([inTarget frame].origin.x + ([inTarget frame].size.width / 2.0)) - (inMetrics.popupViewFrame.size.width / 2.0);
            
            if ( left < 0 )
                {
                left = 0;
                }
            
            CGFloat right = left + inMetrics.popupViewFrame.size.width;
            
            if ( right > inMetrics.containerSize.width )
                {
                right = inMetrics.containerSize.width;
                left = right - inMetrics.popupViewFrame.size.width;
                }
            
            inMetrics.popupViewFrame.origin = CGPointMake ( left, top );
            
            inMetrics.popupArrowPoint = CGPointMake ( [inTarget frame].origin.x + ([inTarget frame].size.width / 2.0), [inTarget frame].origin.y );
            break;
            }
            
        case MGS_PopupDirectionEnum_Right:
            {
#ifdef DEBUG
            NSLog ( @"MGS_PopupViewController::pm_calculateArrow:andTarget: -Right Section Selected" );
#endif
            CGFloat left = [inTarget frame].origin.x + [inTarget frame].size.width + inMetrics.arrowLength;
            CGFloat right = left + inMetrics.popupViewFrame.size.width;
            
            if ( right > inMetrics.containerSize.width )
                {
                right = inMetrics.containerSize.width;
                left = right - inMetrics.popupViewFrame.size.width;
                }
            
            CGFloat top = ([inTarget frame].origin.y + (([inTarget frame].size.height) / 2.0)) - (inMetrics.popupViewFrame.size.height / 2.0);
            
            if ( top < 0 )
                {
                top = 0;
                }
            
            CGFloat bottom = top + inMetrics.popupViewFrame.size.height;
            
            if ( bottom > inMetrics.containerSize.height )
                {
                bottom = inMetrics.containerSize.height;
                top = bottom - inMetrics.popupViewFrame.size.height;
                }
            
            inMetrics.popupViewFrame.origin = CGPointMake ( left, top );
            
            inMetrics.popupArrowPoint = CGPointMake ( [inTarget frame].origin.x + [inTarget frame].size.width, [inTarget frame].origin.y + ([inTarget frame].size.height / 2.0) );
            break;
            }
            
        case MGS_PopupDirectionEnum_Left:
            {
#ifdef DEBUG
            NSLog ( @"MGS_PopupViewController::pm_calculateArrow:andTarget: -Left Section Selected" );
#endif
            CGFloat left = [inTarget frame].origin.x - (inMetrics.popupViewFrame.size.width + inMetrics.arrowLength);
            
            if ( left < 0 )
                {
                left = 0;
                }
            
            CGFloat top = ([inTarget frame].origin.y + (([inTarget frame].size.height) / 2.0)) - (inMetrics.popupViewFrame.size.height / 2.0);
            
            if ( top < 0 )
                {
                top = 0;
                }
            
            CGFloat bottom = top + inMetrics.popupViewFrame.size.height;
            
            if ( bottom > inMetrics.containerSize.height )
                {
                bottom = inMetrics.containerSize.height;
                top = bottom - inMetrics.popupViewFrame.size.height;
                }
            
            inMetrics.popupViewFrame.origin = CGPointMake ( left, top );
            
            inMetrics.popupArrowPoint = CGPointMake ( [inTarget frame].origin.x, [inTarget frame].origin.y + ([inTarget frame].size.height / 2.0) );
            break;
            }
            
        default:
            {
#ifdef DEBUG
            NSLog ( @"MGS_PopupViewController::pm_calculateArrow:andTarget: -Bottom Section Selected" );
#endif
            CGFloat top = [inTarget frame].origin.y + ([inTarget frame].size.height + inMetrics.arrowLength);
            CGFloat bottom = top + inMetrics.popupViewFrame.size.height;
            
            if ( bottom > inMetrics.containerSize.height )
                {
                bottom = inMetrics.containerSize.height;
                top = bottom - inMetrics.popupViewFrame.size.height;
                }
            
            CGFloat left = ([inTarget frame].origin.x + ([inTarget frame].size.width / 2.0)) - (inMetrics.popupViewFrame.size.width / 2.0);
            
            if ( left < 0 )
                {
                left = 0;
                }
            
            CGFloat right = left + inMetrics.popupViewFrame.size.width;
            
            if ( right > inMetrics.containerSize.width )
                {
                right = inMetrics.containerSize.width;
                left = right - inMetrics.popupViewFrame.size.width;
                }
            
            inMetrics.popupViewFrame.origin = CGPointMake ( left, top );
            
            inMetrics.popupArrowPoint = CGPointMake ( [inTarget frame].origin.x + ([inTarget frame].size.width / 2.0), [inTarget frame].origin.y + [inTarget frame].size.height );
            break;
            }
        }
    
    // Normalize to local coordinates for the popup frame.
    inMetrics.popupArrowPoint.x -= inMetrics.popupViewFrame.origin.x;
    inMetrics.popupArrowPoint.y -= inMetrics.popupViewFrame.origin.y;
    
    return inMetrics;
}

/***************************************************************************/
/**
 \brief Basic initializer
        This will be the one used most. We establish a context (container)
        and a target (the view that is pointed to). The controller and the
        view will figure out the layout from there.
        We add a temporary tap gesture recognizer to the container in order
        to close the popup.
 */
- (id)initWithTargetView:(UIView*)inTargetView  ///< The view that is pointed to
          andContentView:(UIView*)inContentView ///< The view that will go inside this one.
{
#ifdef DEBUG
    NSLog ( @"\r----------------------------------------------\rMGS_PopupViewController::initWithTargetView:andContentView:\r----------------------------------------------\r" );
#endif
    self = [super init];
    if (self)
        {
        _targetView = inTargetView;
        _contextView = [inTargetView superview];
        _contentsSubview = inContentView;
        _p_tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closePopup:)];
        [self pm_setUp];
        }
    return self;
}

/***************************************************************************/
/**
 \brief This closes the popup window.
 */
- (void)viewWillDisappear:(BOOL)animated
{
#ifdef DEBUG
    NSLog ( @"\r----------------------------------------------\rMGS_PopupViewController::viewWillDisappear\r----------------------------------------------\r" );
#endif
    [[self contextView] removeGestureRecognizer:[self p_tapper]];
    [self setP_tapper:nil];
}

/***************************************************************************/
/**
 \brief This closes the popup window.
 */
- (IBAction)closePopup:(id)sender
{
#ifdef DEBUG
    NSLog ( @"\r----------------------------------------------\rMGS_PopupViewController::closePopup\r----------------------------------------------\r" );
#endif
    [[self view] removeFromSuperview];
}

/***************************************************************************/
/**
 \brief Sets everything up.
 */
- (void)pm_setUp
{
    MGS_PopupMetrics   metrics = [self pm_calculatePopupFrame];
#ifdef DEBUG
    NSLog ( @"\r----------------------------------------------\rMGS_PopupViewController::viewWillLayoutSubviews\r----------------------------------------------\r" );
    NSLog ( @"Target View Bounds: (%f, %f), (%f, %f)", [[self targetView] frame].origin.x, [[self targetView] frame].origin.y, [[self targetView] frame].size.width, [[self targetView] frame].size.height );
    NSLog ( @"Content View Bounds: (%f, %f), (%f, %f)", [[self contentsSubview] frame].origin.x, [[self contentsSubview] frame].origin.y, [[self contentsSubview] frame].size.width, [[self contentsSubview] frame].size.height );
    NSLog ( @"Context View Bounds: (%f, %f)", [[self contextView] bounds].size.width, [[self contextView] bounds].size.height );
    NSLog ( @"Metrics -Popup View Frame: (%f, %f), (%f, %f)", metrics.popupViewFrame.origin.x, metrics.popupViewFrame.origin.y, metrics.popupViewFrame.size.width, metrics.popupViewFrame.size.height );
    NSLog ( @"Metrics -Container Size: (%f, %f)", metrics.containerSize.width, metrics.containerSize.height );
    NSLog ( @"Metrics -Popup Arrow Point: (%f, %f)", metrics.popupArrowPoint.x, metrics.popupArrowPoint.y );
    NSLog ( @"Metrics -Popup Arrow Base Width: %f", metrics.arrowBaseWidth );
    NSLog ( @"Metrics -Popup Arrow Length: %f", metrics.arrowLength );
    NSLog ( @"Metrics -Direction: %d", metrics.direction );
#endif
    
    [self setView:[[MGS_PopupView alloc] initWithMetrics:metrics]];
    [[self view] setFrame:metrics.popupViewFrame];
    [[self contentsSubview] setFrame:CGRectMake ( s_PaddingInPixels, s_PaddingInPixels, [[self contentsSubview] frame].size.width, [[self contentsSubview] frame].size.height )];
    [[self view] addSubview:[self contentsSubview]];
    [[self contextView] addSubview:[self view]];
    [[self contextView] addGestureRecognizer:[self p_tapper]];
    
    [super viewWillLayoutSubviews];
}

/***************************************************************************/
/**
 \brief Calculate the metrics for the popup view.
 \returns a BMLT_PopupMetrics struct, containing the metrics used for the popup.
 */
- (MGS_PopupMetrics)pm_calculatePopupFrame;
{
#ifdef DEBUG
    NSLog ( @"\r----------------------------------------------\rMGS_PopupViewController::pm_calculatePopupFrame\r----------------------------------------------\r" );
#endif
    CGRect                  targetFrame = [[self targetView] frame];
    CGSize                  contextSize = [[self contextView] bounds].size;
    MGS_PopupMetrics       ret = { CGRectZero, contextSize, CGPointZero, 0, 0, MGS_PopupDirectionEnum_Undefined };
    CGRect                  popupFrameContainer = CGRectZero;
    MGS_PopupDirectionEnum  direction = MGS_PopupDirectionEnum_Undefined;
    CGRect                  frameAbove = CGRectMake ( 0, 0, contextSize.width, MAX ( 0, targetFrame.origin.y - ([[self contentsSubview] frame].size.height + s_ArrowLengthInPixels) ) );
    
    ret.arrowBaseWidth = s_BaseArrowWidthInPixels;
    ret.arrowLength = s_ArrowLengthInPixels;
    // Start with a frame that is in the upper left, and big enough for the contents.
    ret.popupViewFrame = CGRectInset ( [[self contentsSubview] bounds], -s_PaddingInPixels, -s_PaddingInPixels );
    ret.popupViewFrame.origin = CGPointZero;
    
#ifdef DEBUG
    NSLog ( @"MGS_PopupViewController::pm_calculatePopupFrame Target Frame: (%f, %f) (%f, %f)", targetFrame.origin.x, targetFrame.origin.y, targetFrame.size.width, targetFrame.size.height );
    NSLog ( @"MGS_PopupViewController::pm_calculatePopupFrame Contents Frame: (%f, %f) (%f, %f)", ret.popupViewFrame.origin.x, ret.popupViewFrame.origin.y, ret.popupViewFrame.size.width, ret.popupViewFrame.size.height );
    NSLog ( @"MGS_PopupViewController::pm_calculatePopupFrame Context Frame: (0, 0) (%f, %f)", contextSize.width, contextSize.height );
    NSLog ( @"\rMGS_PopupViewController::pm_calculatePopupFrame Above Frame: (%f, %f) (%f, %f)", frameAbove.origin.x, frameAbove.origin.y, frameAbove.size.width, frameAbove.size.height );
#endif
    
    // We will want to pop up above the target, if at all possible. We allow the popup to cover up to half the target.

    // Make sure that we can fit inside the area above the target.
    if ( CGRectContainsRect ( frameAbove, ret.popupViewFrame ) )
        {
#ifdef DEBUG
        NSLog ( @"MGS_PopupViewController::pm_calculatePopupFrame -Top Section Selected" );
#endif
        popupFrameContainer = frameAbove;
        direction = MGS_PopupDirectionEnum_Top;
        }
    else // The next choice is to the right.
        {
        CGRect  frameRight = CGRectMake ( (targetFrame.origin.x + targetFrame.size.width + s_ArrowLengthInPixels), 0, contextSize.width - (targetFrame.origin.x + targetFrame.size.width + s_ArrowLengthInPixels), contextSize.height );
            
#ifdef DEBUG
        NSLog ( @"\rMGS_PopupViewController::pm_calculatePopupFrame Right Frame: (%f, %f) (%f, %f)", frameRight.origin.x, frameRight.origin.y, frameRight.size.width, frameRight.size.height );
#endif
        if ( CGRectContainsRect ( frameRight, CGRectOffset ( ret.popupViewFrame, (targetFrame.origin.x + targetFrame.size.width + s_ArrowLengthInPixels), 0 ) ) )
            {
#ifdef DEBUG
            NSLog ( @"MGS_PopupViewController::pm_calculatePopupFrame -Right Section Selected" );
#endif
            popupFrameContainer = frameRight;
            direction = MGS_PopupDirectionEnum_Right;
            }
        else // The next choice is to the left.
            {
            CGRect  frameLeft = CGRectMake ( 0, 0, (targetFrame.origin.x - s_ArrowLengthInPixels), contextSize.height );
            
#ifdef DEBUG
            NSLog ( @"\rMGS_PopupViewController::pm_calculatePopupFrame Left Frame: (%f, %f) (%f, %f)", frameLeft.origin.x, frameLeft.origin.y, frameLeft.size.width, frameLeft.size.height );
#endif
            if ( CGRectContainsRect ( frameLeft, ret.popupViewFrame ) )
                {
#ifdef DEBUG
                NSLog ( @"MGS_PopupViewController::pm_calculatePopupFrame -Left Section Selected" );
#endif
                popupFrameContainer = frameLeft;
                direction = MGS_PopupDirectionEnum_Left;
                }
            else // The last choice is from the bottom.
                {
                CGRect  frameBelow = CGRectMake ( 0, (targetFrame.origin.y + targetFrame.size.height + s_ArrowLengthInPixels), contextSize.width, contextSize.height - (targetFrame.origin.y + targetFrame.size.height + s_ArrowLengthInPixels) );
                
#ifdef DEBUG
                NSLog ( @"\rMGS_PopupViewController::pm_calculatePopupFrame Lower Frame: (%f, %f) (%f, %f)", frameBelow.origin.x, frameBelow.origin.y, frameBelow.size.width, frameBelow.size.height );
                NSLog ( @"MGS_PopupViewController::pm_calculatePopupFrame -Lower Section Selected" );
#endif
                popupFrameContainer = frameBelow;
                direction = MGS_PopupDirectionEnum_Bottom;
                }
            }
        }
    
    // OK. At this point, we know what part of the screen will contain the popup. We now actually determine its frame within that area.
    
    ret.direction = direction;
    ret = [[self class] pm_calculateArrow:ret andTarget:[self targetView]];

    return ret;
}
@end

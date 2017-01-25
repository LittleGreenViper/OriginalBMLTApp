//
//  MGS_PopupView.m
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

#import "MGS_PopupView.h"

static const CGFloat    s_CornerRoundnessInPixels   = 4.0;  ///< The size of the corners.

/***************************************************************************/
/**
 \class MGS_PopupView
 \brief This is the view for the annotation popup that comes up over the black annotation
        in the map results view when tapped.
 */
@interface MGS_PopupView ()
@property   (assign, atomic, readwrite)     MGS_PopupMetrics   p_metrics;    ///< This will hold the metrics for this view.
@property   (atomic, strong, readwrite)     CAShapeLayer        *p_drawingLayer; ///< This is the shape layer we use for the actual drawing.
@end

@implementation MGS_PopupView

/***************************************************************************/
/**
 \brief Designated initializer
 */
- (id)initWithMetrics:(MGS_PopupMetrics)inMetrics  ///< The metrics that determine the shape and location of the view.
{
#ifdef DEBUG
    NSLog ( @"\r----------------------------------------------\rMGS_PopupView::initWithMetrics:\r----------------------------------------------\r" );
#endif
    self = [super initWithFrame:inMetrics.popupViewFrame];
    
    if ( self )
        {
        _p_metrics = inMetrics;
        }
    
    return self;
}

/***************************************************************************/
/**
 \brief We draw the view by creating shape layers, then letting the view render the layers.
 */
- (void)layoutSubviews
{
#ifdef DEBUG
    NSLog ( @"\r----------------------------------------------\rMGS_PopupView::layoutSubviews\r----------------------------------------------\r" );
#endif
    [super layoutSubviews];
    
    CGRect  drawingRect = [self bounds];

    if ( !CGRectIsEmpty ( drawingRect ) )
        {
#ifdef DEBUG
    NSLog ( @"Draw Rect Bounds: (%f, %f), (%f, %f)", drawingRect.origin.x, drawingRect.origin.y, drawingRect.size.width, drawingRect.size.height );
#endif
        CAShapeLayer    *maskLayer = [CAShapeLayer layer];      // Set up a shape layer for our mask.
        CAShapeLayer    *outlineLayer = [CAShapeLayer layer];   // Set up a shape layer for our view drawing.
    
        if ( maskLayer && outlineLayer )
            {
            [outlineLayer setFrame:drawingRect];
            [maskLayer setFrame:drawingRect];
            
            if ( [self p_drawingLayer] )
                {
                [[self p_drawingLayer] removeFromSuperlayer];
                [self setP_drawingLayer:nil];
                }
            
            float roundness = s_CornerRoundnessInPixels;
            
            UIBezierPath    *framePath = [[UIBezierPath alloc] init];
            
            if ( framePath )
                {
                // Draw the outline.
                
                // Start at the top of the left side.
                [framePath moveToPoint:CGPointMake ( 0, s_CornerRoundnessInPixels )];
                
                // Add the top left corner.
                [framePath addArcWithCenter:CGPointMake ( s_CornerRoundnessInPixels, s_CornerRoundnessInPixels ) radius:s_CornerRoundnessInPixels startAngle:M_PI endAngle:((3 * M_PI) / 2.0) clockwise:YES];
                
                // If we are under the target, we break for the arrow.
                if ( [self p_metrics].direction == MGS_PopupDirectionEnum_Bottom )
                    {
                    CGPoint arrowBaseRight = CGPointMake ( [self p_metrics].popupArrowPoint.x + ([self p_metrics].arrowBaseWidth / 2.0), 0);
                    CGPoint arrowBaseLeft = CGPointMake ( arrowBaseRight.x - [self p_metrics].arrowBaseWidth, 0);
                    
                    [framePath addLineToPoint:arrowBaseLeft];
                    [framePath addLineToPoint:[self p_metrics].popupArrowPoint];
                    [framePath addLineToPoint:arrowBaseRight];
                    }
                
                [framePath addLineToPoint:CGPointMake ( [self p_metrics].popupViewFrame.size.width - s_CornerRoundnessInPixels, 0 )];
                
                // Add the top right corner.
                [framePath addArcWithCenter:CGPointMake ( [self p_metrics].popupViewFrame.size.width - s_CornerRoundnessInPixels, s_CornerRoundnessInPixels ) radius:s_CornerRoundnessInPixels startAngle:((3 * M_PI) / 2.0) endAngle:0 clockwise:YES];
                
                // If we are to the left of the target, we break for the arrow.
                if ( [self p_metrics].direction == MGS_PopupDirectionEnum_Left )
                    {
                    CGPoint arrowBaseBottom = CGPointMake ( [self p_metrics].popupViewFrame.size.width, [self p_metrics].popupArrowPoint.y - ([self p_metrics].arrowBaseWidth / 2.0) );
                    CGPoint arrowBaseTop = CGPointMake ( [self p_metrics].popupViewFrame.size.width, arrowBaseBottom.y + [self p_metrics].arrowBaseWidth);
                    
                    [framePath addLineToPoint:arrowBaseBottom];
                    [framePath addLineToPoint:[self p_metrics].popupArrowPoint];
                    [framePath addLineToPoint:arrowBaseTop];
                    }
                
               [framePath addLineToPoint:CGPointMake ( [self p_metrics].popupViewFrame.size.width, [self p_metrics].popupViewFrame.size.height - s_CornerRoundnessInPixels )];
                
                // Add the bottom right corner.
                [framePath addArcWithCenter:CGPointMake ( [self p_metrics].popupViewFrame.size.width - s_CornerRoundnessInPixels, [self p_metrics].popupViewFrame.size.height - s_CornerRoundnessInPixels ) radius:s_CornerRoundnessInPixels startAngle:0 endAngle:M_PI / 2 clockwise:YES];
                
                // If we are over the target, we break for the arrow.
                if ( [self p_metrics].direction == MGS_PopupDirectionEnum_Top )
                    {
                    CGPoint arrowBaseRight = CGPointMake ( [self p_metrics].popupArrowPoint.x + ([self p_metrics].arrowBaseWidth / 2.0), [self p_metrics].popupViewFrame.size.height);
                    CGPoint arrowBaseLeft = CGPointMake ( arrowBaseRight.x - [self p_metrics].arrowBaseWidth, [self p_metrics].popupViewFrame.size.height);
                    
                    [framePath addLineToPoint:arrowBaseRight];
                    [framePath addLineToPoint:[self p_metrics].popupArrowPoint];
                    [framePath addLineToPoint:arrowBaseLeft];
                    }

                [framePath addLineToPoint:CGPointMake ( s_CornerRoundnessInPixels, [self p_metrics].popupViewFrame.size.height )];
                
                // Add the bottom left corner.
                [framePath addArcWithCenter:CGPointMake ( s_CornerRoundnessInPixels, [self p_metrics].popupViewFrame.size.height - s_CornerRoundnessInPixels ) radius:s_CornerRoundnessInPixels startAngle:M_PI / 2 endAngle:M_PI clockwise:YES];
                
                // If we are to the right of the target, we break for the arrow.
                if ( [self p_metrics].direction == MGS_PopupDirectionEnum_Right )
                    {
                    CGPoint arrowBaseBottom = CGPointMake ( 0, [self p_metrics].popupArrowPoint.y - ([self p_metrics].arrowBaseWidth / 2.0) );
                    CGPoint arrowBaseTop = CGPointMake ( 0, arrowBaseBottom.y + [self p_metrics].arrowBaseWidth);
                    
                    [framePath addLineToPoint:arrowBaseBottom];
                    [framePath addLineToPoint:[self p_metrics].popupArrowPoint];
                    [framePath addLineToPoint:arrowBaseTop];
                    }
                
                // Finish us up.
                [framePath addLineToPoint:CGPointMake ( 0, s_CornerRoundnessInPixels )];
                
                [outlineLayer setCornerRadius:roundness];
                [outlineLayer setPath:[framePath CGPath]];
                [outlineLayer setFillColor:[[UIColor blackColor] CGColor]];
                
                [self setP_drawingLayer:outlineLayer];
                [[self layer] insertSublayer:outlineLayer below:[[[self layer] sublayers] objectAtIndex:0]];
                
                [maskLayer setCornerRadius:roundness];
                [maskLayer setPath:[framePath CGPath]];
                [[self layer] setMask:maskLayer];
                }
            }
        }
}
@end

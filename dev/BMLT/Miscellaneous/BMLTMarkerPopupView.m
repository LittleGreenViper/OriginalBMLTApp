//
//  BMLTMarkerPopupView.m
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

#import "BMLTMarkerPopupView.h"

static const float  s_CornerRoundnessInPixels   = 8.0;
static const float  s_BaseArrowWidthInPixels    = 16.0;
static const float  s_ArrowLengthInPixels       = 16.0;

/***************************************************************************/
/**
 \class BMLTMarkerPopupView
 \brief This is the view for the annotation popup that comes up over the black annotation
        in the map results view when tapped.
 */
@interface BMLTMarkerPopupView ()
@property   (assign, atomic, readwrite) CGPoint     p_pointyEnd;    ///< This will hold the point (in superview coordinates) where the arrow will end up. This will basically control the whole layout.
@end

@implementation BMLTMarkerPopupView

/***************************************************************************/
/**
 \brief Designated initializer
 */
- (id)initWithPoint:(CGPoint)inPointyEnd    /// Where there is to be an arrow pointing.
{
    return self;
}

/***************************************************************************/
/**
 \brief We draw the view by creating shape layers, then letting the view render the layers.
 */
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect  drawingRect = [self bounds];

    if ( !CGRectIsEmpty ( drawingRect ) )
    {
        CAShapeLayer    *maskLayer = [CAShapeLayer layer];      // Set up a shape layer for our mask.
        
        if ( maskLayer )
        {
            [maskLayer setFrame:drawingRect];
            
            float roundness = s_CornerRoundnessInPixels;
            
            UIBezierPath    *framePath = [UIBezierPath bezierPathWithRoundedRect:drawingRect
                                                               byRoundingCorners:UIRectCornerAllCorners
                                                                     cornerRadii:CGSizeMake ( roundness, roundness )
                                          ];
            
            
            if ( framePath )
            {
                [maskLayer setCornerRadius:roundness];
                [maskLayer setPath:[framePath CGPath]];
                [[self layer] setMask:maskLayer];
            }
        }
    }
}

@end

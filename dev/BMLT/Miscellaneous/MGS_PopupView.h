//
//  MGS_PopupView.h
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

#import <UIKit/UIKit.h>

typedef enum
{
    MGS_PopupDirectionEnum_Undefined = 0,
    MGS_PopupDirectionEnum_Top,
    MGS_PopupDirectionEnum_Right,
    MGS_PopupDirectionEnum_Left,
    MGS_PopupDirectionEnum_Bottom
} MGS_PopupDirectionEnum;

typedef struct  /// This will contain the various metrics for the popup view.
{
    CGRect                  popupViewFrame;     ///< This is the frame (in container coordinates) of the popup view.
    CGSize                  containerSize;      ///< This is the size (in container coordinates) of the containing view.
    CGPoint                 popupArrowPoint;    ///< This is the point (in local popup view coordinates) of the outer tip of the arrow.
    CGFloat                 arrowBaseWidth;     ///< The width of the arrow base.
    CGFloat                 arrowLength;        ///< The length of the arrow.
    MGS_PopupDirectionEnum  direction;          ///< The relationship of the popup to the target.
} MGS_PopupMetrics;

/***************************************************************************/
/**
 \class MGS_PopupView
 \brief This is the view for the annotation popup that comes up over the black annotation
        in the map results view when tapped.
 */
@interface MGS_PopupView : UIView
- (id)initWithMetrics:(MGS_PopupMetrics)inMetrics;
@end

//
//  MGS_PopupViewController.h
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

@protocol MGS_PopupViewControllerDelegate <NSObject>
- (void)closeMarkerPopup;
@end

@class MGS_PopupViewController; ///< Forward declaration for the gesture recognizer.

/*****************************************************************/
/**
 \class MGS_PopupViewGestureRecognizer
 \brief This is used to find taps anywhere in the assigned view.
        It is inspired (and cribbed) from here:
        http://stackoverflow.com/questions/1049889/how-to-intercept-touches-events-on-a-mkmapview-or-uiwebview-objects/4064538#4064538
 *****************************************************************/
@interface MGS_PopupViewGestureRecognizer : UIGestureRecognizer
@property (atomic, weak) MGS_PopupViewController  *myController;  ///< This will hold the view controller that we'll use to update.

- (id)initWithController:(MGS_PopupViewController*)inController;
@end

/***************************************************************************/
/**
 \class MGS_PopupViewController
 \brief This is the controller for the annotation popup that comes up over the black annotation
        in the map results view when tapped.
 */
@interface MGS_PopupViewController : UIViewController
@property (atomic, weak, readwrite) IBOutlet UIView *targetView;            ///< This will be the view that is pointed to
@property (atomic, weak, readwrite) IBOutlet UIView *contextView;           ///< This will be the container view.
@property (atomic, weak, readwrite) NSObject <MGS_PopupViewControllerDelegate> *delegate; ///< This will be the controller that needs to be called to clean up.
@property (atomic, strong, readwrite) IBOutlet UIView *contentsSubview;     ///< This will be what goes inside the popup.

- (id)initWithTargetView:(UIView*)inTargetView andContentView:(UIView*)inContentView;
- (IBAction)closePopup:(id)sender;
@end

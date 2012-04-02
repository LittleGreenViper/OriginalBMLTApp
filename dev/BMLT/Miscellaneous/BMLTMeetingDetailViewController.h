//
//  BMLTMeetingDetailViewController.h
//  BMLT
//
//  Created by MAGSHARE on 8/13/11.
//  Copyright 2011 MAGSHARE. All rights reserved.
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
#import <MapKit/MapKit.h>

@class BMLT_Meeting;
@class BMLT_Results_MapPointAnnotation;

#define List_Meeting_Format_Circle_Size_Big 30

@interface BMLTMeetingDetailViewController : UIViewController <MKMapViewDelegate>
{
    MKMapView                       *meetingMapView;
    IBOutlet UIView                 *formatsContainerView;
    IBOutlet UIButton               *addressButton;
    IBOutlet UITextView             *commentsTextView;
    IBOutlet UITextView             *frequencyTextView;
    IBOutlet UIButton               *selectMapButton;
    IBOutlet UIButton               *selectSatelliteButton;
    UIViewController                *myModalController;
    BMLT_Results_MapPointAnnotation *myMarker;
}
@property (weak, nonatomic, readonly)   BMLT_Meeting    *myMeeting;
@property (nonatomic, retain) IBOutlet  MKMapView       *meetingMapView;

- (id)initWithMeeting:(BMLT_Meeting *)inMeeting andController:(UIViewController *)inController; ///< Initialize with a meeting object.

- (void)setMyModalController:(UIViewController *)inController;
- (UIViewController *)getMyModalController;
- (BMLT_Meeting *)getMyMeeting;
- (void)setFormats;
- (void)setMeetingFrequencyText;
- (void)setMeetingCommentsText;
- (void)setMeetingLocationText;
- (void)setMapLocation;
- (IBAction)callForDirections:(id)sender;

@end

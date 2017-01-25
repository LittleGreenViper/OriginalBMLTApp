//
//  FormatDetailView.h
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

#import <UIKit/UIKit.h>

@class BMLT_Format;

@interface BMLTFormatDetailViewController : UIViewController
{
    UIViewController            *myModalController;
    BMLT_Format                 *myFormat;
}
@property (atomic, strong, readwrite) IBOutlet UINavigationBar    *navBar;
@property (atomic, strong, readwrite) IBOutlet UILabel            *formatKeyLabel;
@property (atomic, strong, readwrite) IBOutlet UIImageView        *formatKeyImage;
@property (atomic, strong, readwrite) IBOutlet UITextView         *formatDescription;

- (id)initWithFormat:(BMLT_Format *)inFormat andController:(UIViewController *)inController;
- (IBAction)donePressed:(id)sender;
- (void)setMyFormat:(BMLT_Format *)inFormat;
- (void)setUpKey;
- (void)setTitle;
- (void)setDescription;
- (BMLT_Format *)getMyFormat;
- (void)setMyModalController:(UIViewController *)inController;
- (UIViewController *)getMyModalController;
@end

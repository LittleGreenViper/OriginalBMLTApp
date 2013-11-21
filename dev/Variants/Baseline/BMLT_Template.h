//
//  BMLT_Template.h
//  BMLT
//
//  Created by MAGSHARE.
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

@interface BMLT_TemplateWindow : UIView
@end

@interface BMLT_TemplateWindowViewController : UIViewController
@property (weak, nonatomic) IBOutlet BMLT_TemplateWindow    *windowView;
@property (weak, nonatomic) IBOutlet UINavigationBar        *navigationBar;
@property (weak, nonatomic) IBOutlet UIToolbar              *toolbar;
@property (weak, nonatomic) IBOutlet UILabel                *linkColorLabel;
@property (weak, nonatomic) IBOutlet UILabel                *textColorLabel;
@property (weak, nonatomic) IBOutlet UIView                 *settingsView;
@property (weak, nonatomic) IBOutlet UILabel                *settingsTextColorLabel;
@property (weak, nonatomic) IBOutlet UIView                 *infoView;
@property (weak, nonatomic) IBOutlet UILabel                *infoTextLabel;
@property (weak, nonatomic) IBOutlet UIView                 *meetingDetailsView;
@property (weak, nonatomic) IBOutlet UILabel                *meetingDetailsTextLabel;
@property (weak, nonatomic) IBOutlet UIView                 *simpleSearchView;
@property (weak, nonatomic) IBOutlet UILabel                *simpleSearchTextLabel;
@property (weak, nonatomic) IBOutlet UIView                 *advancedSearchView;
@property (weak, nonatomic) IBOutlet UILabel                *advancedSearchTextLabel;
@property (weak, nonatomic) IBOutlet UIView                 *popoverView;
@property (weak, nonatomic) IBOutlet UILabel                *popoverTextLabel;
@property (weak, nonatomic) IBOutlet UIView                 *listEvenView;
@property (weak, nonatomic) IBOutlet UILabel                *listEvenTextLabel;
@property (weak, nonatomic) IBOutlet UIView                 *listOddView;
@property (weak, nonatomic) IBOutlet UILabel                *listOddTextLabel;
+ (id)loadInstanceFromNib;
@end

@interface BMLT_Template : NSObject
@property (atomic, strong, readwrite) IBOutlet  BMLT_TemplateWindowViewController   *templateViewController;
@end

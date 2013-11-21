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

@interface BMLT_Template : NSObject
@property (atomic, strong, readwrite) IBOutlet  UIViewController    *templateViewController;

- (UIView*)getWindowTemplate;
- (UIView*)getSearchViewTemplate;
- (UIView*)getBusyViewTemplate;
- (UIView*)getInfoViewTemplate;
- (UIView*)getMeetingsDetailsViewTemplate;
- (UIView*)getFormatDetailsViewTemplate;
- (UIView*)getSettingsViewTemplate;
- (UIView*)getList0ViewTemplate;
- (UIView*)getList1ViewTemplate;
@end

@interface BMLT_TemplateWindowViewController : UIViewController
+ (id)loadInstanceFromNib;
@end

@interface BMLT_TemplateWindow : UIView
@end

@interface BMLT_TemplateSearchView : UIView
@end

@interface BMLT_TemplateBusyView : UIView
@end

@interface BMLT_TemplateInfoView : UIView
@end

@interface BMLT_TemplateMeetingDetailsView : UIView
@end

@interface BMLT_TemplateFormatDetailsView : UIView
@end

@interface BMLT_TemplateSettingsView : UIView
@end

@interface BMLT_TemplateList0View : UIView
@end

@interface BMLT_TemplateList1View : UIView
@end

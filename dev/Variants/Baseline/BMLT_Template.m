//
//  BMLT_Template.m
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

#import "BMLT_Template.h"

@implementation BMLT_Template
- (id)init
{
    self = [super init];
    
    if ( self )
        {
        _templateViewController = [BMLT_TemplateWindowViewController loadInstanceFromNib];
        }
    
    return self;
}

- (UIView*)getWindowTemplate
{
    return [[self templateViewController] view];
}

- (UIView*)getSearchViewTemplate
{
    return nil;
}

- (UIView*)getBusyViewTemplate
{
    return nil;
}

- (UIView*)getInfoViewTemplate
{
    return nil;
}

- (UIView*)getMeetingsDetailsViewTemplate
{
    return nil;
}

- (UIView*)getFormatDetailsViewTemplate
{
    return nil;
}

- (UIView*)getSettingsViewTemplate
{
    return nil;
}

- (UIView*)getList0ViewTemplate
{
    return nil;
}

- (UIView*)getList1ViewTemplate
{
    return nil;
}
@end

@implementation BMLT_TemplateWindowViewController
// Cribbed from here: http://stackoverflow.com/questions/13560671/ios-instantiate-custom-view-from-nib-file-across-multiple-uiviewcontroller
+ (id)loadInstanceFromNib
{
    UIView *result;
    
    NSArray* elements = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass ( [self class] ) owner:nil options:nil];
    
    for ( id anObject in elements )
        {
        if ( [anObject isKindOfClass:[self class]] )
            {
            result = anObject;
            break;
            }
        }
    
    return result;
}
@end

@implementation BMLT_TemplateWindow
@end

@implementation BMLT_TemplateSearchView
@end

@implementation BMLT_TemplateBusyView
@end

@implementation BMLT_TemplateInfoView
@end

@implementation BMLT_TemplateMeetingDetailsView
@end

@implementation BMLT_TemplateFormatDetailsView
@end

@implementation BMLT_TemplateSettingsView
@end

@implementation BMLT_TemplateList0View
@end

@implementation BMLT_TemplateList1View
@end

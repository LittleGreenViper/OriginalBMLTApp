//
//  MGS_Simple_Control.h
//  MGS_Simple_Control
//
//  Created by MAGSHARE on 11/1/13.
//  Copyright (c) 2013 MAGSHARE. All rights reserved.
//
//  This is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  MGS_Simple_Control is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this code.  If not, see <http://www.gnu.org/licenses/>.

#import <UIKit/UIKit.h>

/************************************************************************************************************************/
/************************************************************************************************************************/

/**
 \enum MGS_Simple_ControlEnum_ControlType
 
 \brief The type of control
 */
typedef enum
{
    MGS_Simple_ControlEnum_ControlType_Pushbutton   = 0,    ///< Standard momentary pushbutton with text inside of it.
    MGS_Simple_ControlEnum_ControlType_Checkbox     = 1,    ///< Checkbox
    MGS_Simple_ControlEnum_ControlType_Radio        = 2     ///< Radio button
} MGS_Simple_ControlEnum_ControlType;


/************************************************************************************************************************/
/************************************************************************************************************************/

/***************************************************************************/
/**
 \class MGS_Simple_Control
 
 \brief Swiss-army-knife control that uses dynamic CG/CA drawing.
 */
@interface MGS_Simple_Control : UIControl
@property   (nonatomic, assign, readwrite)  MGS_Simple_ControlEnum_ControlType  controlType;    ///< Specifies the control type.
@property   (nonatomic, assign, readwrite)  BOOL                                checked;        ///< If YES, the control is checked, or "sticky." This is not valid for MGS_Simple_ControlEnum_ControlType_Pushbutton
@property   (nonatomic, assign, readwrite)  BOOL                                noBorder;       ///< If YES, the control does not display an outer border.
@property   (nonatomic, assign, readwrite)  BOOL                                noFill;         ///< If YES, the control does not display a fill.
@property   (nonatomic, strong, readwrite)  NSString                            *title;         ///< This is the text inside the button for MGS_Simple_ControlEnum_ControlType_Pushbutton. It is ignored in the other controls.
@property   (nonatomic, strong, readwrite)  NSString                            *valueTag;      ///< This is a string that is used to identify the control. It will be used by the MGS_Simple_ControlGroup class.

/***************************************************************************/
/**
 \brief Designated Initializer
 
 \param inFrame the control frame, in superview context
 \param inControlType one of MGS_Simple_ControlEnum_ControlType. The type of control
 \param inTint The color that will form the general tint of the control.
 \param inChecked If YES, the control will be checked.
 \param inTitle If the control is a button, the text for that button. If the control is not a button, this is ignored.
 
 \returns self
 */
- (id)initWithFrame:(CGRect)inFrame andControlType:(MGS_Simple_ControlEnum_ControlType)inControlType andTint:(UIColor*)inTint andChecked:(BOOL)inChecked andTitle:(NSString*)inTitle;

/***************************************************************************/
/**
 \brief Accessor. Returns the state of the checked data member.
 
 \returns YES, if the control is checked.
 */
- (BOOL)isChecked;
@end

/************************************************************************************************************************/
/************************************************************************************************************************/

/***************************************************************************/
/**
 \class MGS_Simple_ControlGroup
 
 \brief This makes it damn easy to group together controls.
 
        This aggregates checkboxes and radiobuttons. It will only work for one type. Don't mix control types.
 
        You use this by adding a number of MGS_Simple_Control subviews to this view. It will automatically read the contained
        views, and will set itself up to aggregate them. This allows you to treat a group of radiobuttons or checkboxes as a
        unit. This is a UIControl class, so it will send valueChanged messages.
 
        You examine the tags datamember for the current values of all the controls. If the class aggregates checkboxes,
        then it will have a list of tags, with each one representing a checked box (unchecked boxes are not represented).
        The values array is nil, if there are no checked boxes.
        
        In the case of radiobuttons, this will be nil (for the rare case where there are no radiobuttons selected), or will
        only have one tag.
 
        For radiobuttons, this class also handles making sure that only one radiobutton is selected at a time.
 
        You can "prime" a MGS_Simple_ControlGroup by setting this value. If the tags don't match controls, they will be
        ignored. If there are more than one tag in a radiobutton set, only the first valid one will be used, and all others
        will be ignored.
 
        This class will only send valueChanged messages.
 */
@interface MGS_Simple_ControlGroup : UIControl
@property   (atomic, strong, readonly)      NSArray *controls;  ///< This is a list of all the controls in the group.
@property   (nonatomic, strong, readwrite)  NSArray *tagArray;  ///< This is a variable-length list of tags. Each tag represents a control that is checked.
@end

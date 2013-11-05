//
//  MGS_Simple_Control.m
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

#import "MGS_Simple_Control.h"
#import <QuartzCore/QuartzCore.h>

static const CGFloat    s_BaseFontSize              = 100;  ///< The largest (base) font size.
static const CGFloat    s_CornerRoundnessInPixels   = 4;    ///< The roundness of the corners (and the inset of the title).
static const CGFloat    s_LineThicknessInPixels     = 3;    ///< The thickness of the lines in pixels.
static const CGFloat    s_DisabledOpacity           = 0.5;  ///< The opacity of diabled controls.

#define IOS_6_TINT      ([UIColor colorWithRed:0.6549019608 green:0.6509803922 blue:0 alpha:1])              ///< This is a stand-in tint color for iOS6 (which doesn't have tintColor).

/************************************************************************************************************************/
/************************************************************************************************************************/

/***************************************************************************/
/**
 \class MGS_Simple_ControlGroup
 
 \brief This makes it damn easy to group together controls.
 
        This aggregates checkboxes and radiobuttons. It will only work for one type, and that type is determined by the
        first control it encounters in pm_adaptToSubViews. Don't mix control types.
 
        You use this by adding a number of MGS_Simple_Control subviews to this view. It will automatically read the contained
        views, and will set itself up to aggregate them. This allows you to treat a group of radiobuttons or checkboxes as a
        unit. This is a UIControl class, so it will send valueChanged messages.
 
        You examine the values datamember for the current values of all the controls. If the class aggregates checkboxes,
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
@interface MGS_Simple_ControlGroup ()
/***************************************************************************/
/**
 \brief Catalogs the subviews, and sets itself up to make best use of them.
 
        NOTE: This only "digs" down one layer, and only catalogs checkboxes
        and radiobuttons.
 */
- (void)pm_adaptToSubViews;

/***************************************************************************/
/**
 \brief This responds to events within contained controls.
 */
- (IBAction)pm_controlValueChanged:(MGS_Simple_Control*)sender;
@end

/************************************************************************************************************************/
/************************************************************************************************************************/

/***************************************************************************/
/**
 \class MGS_Simple_Control
 
 \brief Swiss-army-knife control that uses dynamic CG/CA drawing.
 */
@interface MGS_Simple_Control ()
@property   (atomic, strong, readwrite)  UILabel        *p_textLabel;           ///< For MGS_Simple_ControlEnum_ControlType_Pushbutton, this is the label subview inside the button.
@property   (atomic, strong, readwrite)  CAShapeLayer   *p_controlDrawingLayer; ///< This is the shape layer we use for the actual drawing.

- (void)pm_setUpTextItem;
- (MGS_Simple_ControlGroup*)pm_areYouMyMommy;
@end

/***************************************************************************/
/**
 \class MGS_Simple_Control
 
 \brief Swiss-army-knife control that uses dynamic CG/CA drawing.
 */
@implementation MGS_Simple_Control
/***************************************************************************/
/**
 \brief This sets the title text, and also sizes the text item for maximum efficiency.
 */
- (void)pm_setUpTextItem
{
    // If we are qualified to have a text label...
    if ( ([self controlType] == MGS_Simple_ControlEnum_ControlType_Pushbutton) && [self title] )
    {
        if ( ![self p_textLabel] )  // First time through, we create the item.
        {
            CGRect  frame = CGRectInset ( [self bounds], s_CornerRoundnessInPixels, s_CornerRoundnessInPixels );
            UILabel *pLabel = [[UILabel alloc] initWithFrame:frame];
            
            [self addSubview:pLabel];
            [self setP_textLabel:pLabel];
        }
        
        if ( [self p_textLabel] )   // If we have a label, we set its text.
        {
            // All this gameplaying is to determine the proper font size for that label.
            NSMutableAttributedString   *pAttrString = [[NSMutableAttributedString alloc] initWithString:[self title] attributes:nil];
            
            if ( pAttrString )
            {
                float       fontSize = s_BaseFontSize;
                NSRange     range = NSMakeRange ( 0, [[self title] length] );
                
                do
                {
                    [pAttrString beginEditing];
                    [pAttrString addAttribute:NSFontAttributeName
                                        value:[UIFont boldSystemFontOfSize:fontSize]
                                        range:range
                     ];
                    [pAttrString endEditing];
                    
                    NSRange ignored;
                    NSDictionary    *pAttributes = [pAttrString attributesAtIndex:0
                                                                   effectiveRange:&ignored
                                                    ];
                    
                    CGSize pSize = [[self title] sizeWithAttributes:pAttributes];
                    
                    // We test to see if the attributed string will fit.
                    
                    // If so, we break the loop.
                    if ( (pSize.width <= [[self p_textLabel] bounds].size.width) && (pSize.height <= [[self p_textLabel] bounds].size.height) )
                    {
                        break;
                    }
                    else    // If not, we knock the size down by 0.1, and try again.
                    {
                        fontSize -= 0.1;
                        [pAttrString beginEditing];
                        [pAttrString removeAttribute:NSFontAttributeName range:range];
                        [pAttrString endEditing];
                    }
                } while ( YES );
                
                [[self p_textLabel] setTextAlignment:NSTextAlignmentCenter];
                [[self p_textLabel] setFont:[UIFont boldSystemFontOfSize:fontSize]];
                [[self p_textLabel] setText:[self title]];
                
                UIColor *tint = nil;
                
                if ( [self respondsToSelector:@selector(tintColor)] )
                {
                    if ( ![self tintColor] )
                    {
                        [self setTintColor:[UIColor blackColor]];
                    }
                    
                    tint = [self tintColor];
                }
                else
                {
                    tint = IOS_6_TINT;
                }
                
                [[self p_textLabel] setTextColor:tint];
                [self bringSubviewToFront:[self p_textLabel]];
            }
        }
    }
    else    // Otherwise, we don't have a text label.
    {
        if ( [self p_textLabel] )
        {
            [[self p_textLabel] removeFromSuperview];
            [self setP_textLabel:nil];
        }
    }
}

/***************************************************************************/
/**
 \brief Checks the container view to see if it's a "smart container." If so, it does cool stuff.
 
 \returns the superview, if it is a MGS_Simple_ControlGroup. Otherwise, nil.
 */
- (MGS_Simple_ControlGroup*)pm_areYouMyMommy
{
    MGS_Simple_ControlGroup *mommy = nil;
    
    if ( [[self superview] isKindOfClass:[MGS_Simple_ControlGroup class]] )
    {
        mommy = (MGS_Simple_ControlGroup*)[self superview];
        [mommy pm_adaptToSubViews];
    }
    
    return mommy;
}

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
- (id)initWithFrame:(CGRect)inFrame
     andControlType:(MGS_Simple_ControlEnum_ControlType)inControlType
            andTint:(UIColor*)inTint
         andChecked:(BOOL)inChecked
           andTitle:(NSString*)inTitle
{
    self = [super initWithFrame:inFrame];
    
    if (self)
    {
        _controlType = inControlType;
        [self setTintColor:inTint];
        _checked = inChecked;
        [self setSelected:inChecked];
        _title = inTitle;
    }
    
    return self;
}

/***************************************************************************/
/**
 \brief Accessor. Returns the state of the checked data member.
 
 \returns YES, if the control is checked.
 */
- (BOOL)isChecked
{
    return [self checked];
}

/***************************************************************************/
/**
 \brief This sets the control type, and forces a redraw.
 
 \param inControlType A MGS_Simple_ControlEnum_ControlType. The new control type.
 */
- (void)setControlType:(MGS_Simple_ControlEnum_ControlType)inControlType
{
    // If this is an unknown control type, we default to pushbutton.
    if (    (inControlType != MGS_Simple_ControlEnum_ControlType_Pushbutton)
        &&  (inControlType != MGS_Simple_ControlEnum_ControlType_Radio)
        &&  (inControlType != MGS_Simple_ControlEnum_ControlType_Checkbox)
        )
    {
        inControlType = MGS_Simple_ControlEnum_ControlType_Pushbutton;
    }
    
    _controlType = inControlType;
    
    [self setNeedsLayout];
}

/***************************************************************************/
/**
 \brief This sets the control to a "checked" state, or an "unchecked" state.
 
 \param inChecked A BOOL. YES, if the control is to be checked.
 */
- (void)setChecked:(BOOL)inChecked
{
    if ( _checked != inChecked )
    {
        _checked = inChecked;
        
        [self setSelected:inChecked];
        [self setNeedsLayout];
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

/***************************************************************************/
/**
 \brief This sets the control to a "checked" state, or an "unchecked" state.
 
 \param inTitle The new title string for the button. This shows no visible change if the control is not a button.
 */
- (void)setTitle:(NSString *)inTitle
{
    _title = inTitle;
    
    [self setNeedsLayout];
}

/***************************************************************************/
/**
 \brief This is where we re-establish any text and control state. This allows the control to be dynamically changed.

        This method is also where all the drawing happens. We draw the control by creating
        shape layers, then letting the view render the layers.
 */
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self pm_areYouMyMommy];
    
    CGRect  drawingRect = [self bounds];
    
    [self setChecked:[self isSelected]];

    // Checkboxes and radiobuttons are always square/round, so we use the smallest side as the square.
    if (    ([self controlType] == MGS_Simple_ControlEnum_ControlType_Checkbox)
        ||  ([self controlType] == MGS_Simple_ControlEnum_ControlType_Radio)
        )
    {
        if ( drawingRect.size.width < drawingRect.size.height )
        {
            drawingRect.size.height = drawingRect.size.width;
        }
        else
        {
            drawingRect.size.width = drawingRect.size.height;
        }
        
        [self setBounds:drawingRect];   // Change our own dimensions.
    }
    
    if ( !CGRectIsEmpty ( drawingRect ) )
    {
        CAShapeLayer    *outlineLayer = [CAShapeLayer layer];   // Set up a shape layer for our control drawing.
        CAShapeLayer    *maskLayer = [CAShapeLayer layer];      // Set up a shape layer for our mask.
        
        if ( outlineLayer )
        {
            [outlineLayer setFrame:drawingRect];
            [maskLayer setFrame:drawingRect];
            
            if ( [self p_controlDrawingLayer] )
            {
                [[self p_controlDrawingLayer] removeFromSuperlayer];
                [self setP_controlDrawingLayer:nil];
            }
            
            UIColor *tint = nil;
            
            if ( [self respondsToSelector:@selector(tintColor)] )
            {
                if ( ![self tintColor] )
                {
                    [self setTintColor:[UIColor blackColor]];
                }
                
                tint = [self tintColor];
            }
            else
            {
                tint = IOS_6_TINT;
            }
            
            UIBezierPath    *framePath = nil;
            
            float roundness = s_CornerRoundnessInPixels;
            
            // Radio buttons are round.
            if ( [self controlType] == MGS_Simple_ControlEnum_ControlType_Radio )
            {
                framePath = [UIBezierPath bezierPathWithOvalInRect:drawingRect];
                roundness = [self bounds].size.width / 2.0;
            }
            else
            {
                if ( [self controlType] == MGS_Simple_ControlEnum_ControlType_Pushbutton )
                {
                    roundness *= 2.0;   // Buttons have more round.
                }
                
                framePath = [UIBezierPath bezierPathWithRoundedRect:drawingRect
                                                  byRoundingCorners:UIRectCornerAllCorners
                                                        cornerRadii:CGSizeMake ( roundness, roundness )
                             ];
            }
            
            UIBezierPath    *maskPath = [UIBezierPath bezierPathWithCGPath:[framePath CGPath]];
            
            // Checkboxes have a big "X" in the middle.
            if ( ([self controlType] == MGS_Simple_ControlEnum_ControlType_Checkbox) && [self isChecked] )
            {
                CAShapeLayer    *checkFillerLayer = [CAShapeLayer layer];   // We use another layer to fill the radio button.
                CGRect          checkFillerRect = CGRectInset ( drawingRect, s_CornerRoundnessInPixels, s_CornerRoundnessInPixels );
                UIBezierPath    *fillerPath = [UIBezierPath bezierPath];
                
                // We actually draw a checkmark.
                [fillerPath moveToPoint:CGPointMake ( checkFillerRect.origin.x + (checkFillerRect.size.width / 10), (checkFillerRect.origin.y + checkFillerRect.size.height) - (checkFillerRect.size.height / 3) )];
                [fillerPath addLineToPoint:CGPointMake ( checkFillerRect.origin.x + (checkFillerRect.size.width / 5), (checkFillerRect.origin.y + checkFillerRect.size.height) - (checkFillerRect.size.height / 3) )];
                [fillerPath addLineToPoint:CGPointMake ( checkFillerRect.origin.x + (checkFillerRect.size.width / 2) - (checkFillerRect.size.width / 10), (checkFillerRect.origin.y + checkFillerRect.size.height) )];
                [fillerPath addLineToPoint:CGPointMake ( checkFillerRect.origin.x + checkFillerRect.size.width, checkFillerRect.origin.y )];
                
                [checkFillerLayer setLineWidth:s_LineThicknessInPixels];
                [checkFillerLayer setFrame:drawingRect];
                [checkFillerLayer setFillColor:[[UIColor clearColor] CGColor]];
                [checkFillerLayer setStrokeColor:[self isEnabled] ? [[UIColor greenColor] CGColor] : [[UIColor whiteColor] CGColor]];
                [checkFillerLayer setPath:[fillerPath CGPath]];
                [checkFillerLayer setLineJoin:kCALineJoinRound];
                [checkFillerLayer setLineCap:kCALineCapRound];
                [outlineLayer addSublayer:checkFillerLayer];
            }
            else
            {
                // Radio buttons have a big round bull's eye.
                if ( ([self controlType] == MGS_Simple_ControlEnum_ControlType_Radio) && [self isChecked] )
                {
                    CAShapeLayer    *radioFillerLayer = [CAShapeLayer layer];   // We use another layer to fill the radio button.
                    CGRect          fillerRect = CGRectInset ( drawingRect, s_CornerRoundnessInPixels, s_CornerRoundnessInPixels );
                    UIBezierPath    *fillerPath = [UIBezierPath bezierPathWithOvalInRect:fillerRect];
                    
                    [radioFillerLayer setFrame:drawingRect];
                    [radioFillerLayer setFillColor:[tint CGColor]];
                    [radioFillerLayer setPath:[fillerPath CGPath]];
                    [outlineLayer addSublayer:radioFillerLayer];
                }
            }
            
            if ( framePath )
            {
                [outlineLayer setCornerRadius:roundness];
                [outlineLayer setPath:[framePath CGPath]];
                [outlineLayer setLineWidth:s_LineThicknessInPixels];
                [outlineLayer setFillColor:(![self noFill] && [self isHighlighted]) ? [[UIColor whiteColor] CGColor] : [[UIColor clearColor] CGColor]];
                [outlineLayer setStrokeColor:[self noBorder] ? [[UIColor clearColor] CGColor] : [tint CGColor]];
                
                [self setP_controlDrawingLayer:outlineLayer];
                [[self layer] addSublayer:outlineLayer];
                
                [maskLayer setCornerRadius:roundness];
                [maskLayer setPath:[maskPath CGPath]];
                [[self layer] setMask:maskLayer];
            }
            
            if ( [self noFill] )
            {
                [self setBackgroundColor:[UIColor clearColor]];
            }
        }
    }
    
    [self pm_setUpTextItem];
    
    if ( ![self isEnabled] )
    {
//        [[self layer] setOpacity:s_DisabledOpacity];
    }
    else
    {
        [[self layer] setOpacity:1.0];
    }
}

/***************************************************************************/
/**
 \brief Intercepts the highlight setting, in order to force a redraw.
 
 \param inHighlighted If YES, the control is in a "higlighted" state.
 */
- (void)setHighlighted:(BOOL)inHighlighted
{
    [super setHighlighted:inHighlighted];
    [self setNeedsLayout];
}

/***************************************************************************/
/**
 \brief Intercepts the enabled setting, in order to force a redraw.
 
 \param inEnabled If YES, the control is in an enabled state.
 */
- (void)setEnabled:(BOOL)inEnabled
{
    [super setEnabled:inEnabled];
    [self setNeedsLayout];
}

/***************************************************************************/
/**
 \brief When the touch event starts, this is called.
 
 \param inTouch the UITouch object that is tracking the gesture
 \param inEvent the event that started this
 
 \returns YES, if the event is valid.
 */
- (BOOL)beginTrackingWithTouch:(UITouch *)inTouch withEvent:(UIEvent *)inEvent
{
    BOOL    ret = NO;
    
    // We can't change unchecked radio buttons.
    if ( [self isEnabled] && !(([self controlType] == MGS_Simple_ControlEnum_ControlType_Radio) && [self checked]) )
    {
        [self setHighlighted:YES];
        
        ret = YES;
    }
    
    return ret;
}

/***************************************************************************/
/**
 \brief When the touch event ends peacfully, this is called.
 
 \param inTouch the UITouch object that is tracking the gesture
 \param inEvent the event that started this
*/
- (void)endTrackingWithTouch:(UITouch *)inTouch withEvent:(UIEvent *)inEvent
{
    [self setHighlighted:NO];
    
    if ( [self isEnabled] )
    {
        // If the event ended in the control, we change the value (maybe)
        
        if ( CGRectContainsPoint ( [self bounds], [inTouch locationInView:self] ) )
        {
            switch ( [self controlType] )
            {
                case MGS_Simple_ControlEnum_ControlType_Radio:
                    if ( ![self isChecked] )  // You can't uncheck radiobuttons.
                    {
                        [self setChecked:YES];
                        [self sendActionsForControlEvents:UIControlEventValueChanged];
                    }
                    break;
                    
                case MGS_Simple_ControlEnum_ControlType_Checkbox:
                    [self setChecked:![self isChecked]];
                    [self sendActionsForControlEvents:UIControlEventValueChanged];
                    break;
                    
                default:
                    break;
            }
        }
    }
    else
    {
        [self sendActionsForControlEvents:UIControlEventTouchUpOutside];
    }
}

/***************************************************************************/
/**
 \brief When the touch event is canceled, this is called.
 
 \param inTouch the UITouch object that is tracking the gesture
 \param inEvent the event that started this
*/
- (void)cancelTrackingWithTouch:(UITouch *)inTouch withEvent:(UIEvent *)inEvent
{
    [self setHighlighted:NO];
    [self sendActionsForControlEvents:UIControlEventTouchCancel];
}
@end

/************************************************************************************************************************/
/************************************************************************************************************************/

/***************************************************************************/
/**
 \class MGS_Simple_ControlGroup
 
 \brief This makes it damn easy to group together controls.
 
        This aggregates checkboxes and radiobuttons. It will only work for one type, and that type is determined by the
        first control it encounters in pm_adaptToSubViews. Don't mix control types.
 
        You use this by adding a number of MGS_Simple_Control subviews to this view. It will automatically read the contained
        views, and will set itself up to aggregate them. This allows you to treat a group of radiobuttons or checkboxes as a
        unit. This is a UIControl class, so it will send valueChanged messages.
 
        You examine the values datamember for the current values of all the controls. If the class aggregates checkboxes,
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
@implementation MGS_Simple_ControlGroup
/***************************************************************************/
/**
 \brief Catalogs the subviews, and sets itself up to make best use of them.
 
        NOTE: This only "digs" down one layer, and only catalogs checkboxes
        and radiobuttons.
 */
- (void)pm_adaptToSubViews
{
    _controls = nil;    // Delete any previous records of the contents. We'll rebuild it.
    _tagArray = nil;    // Same for tags. We'll be restoring this from the state of the contained objects.
    
    NSMutableArray  *pNewControlsArray = [[NSMutableArray alloc] init];
    NSMutableArray  *pNewTagArray = [[NSMutableArray alloc] init];
    MGS_Simple_ControlEnum_ControlType  currentControlType = MGS_Simple_ControlEnum_ControlType_Pushbutton; // We set this to the first valid control that we find.
    
    for ( UIView *pView in [self subviews] )
    {
        if ( [pView isKindOfClass:[MGS_Simple_Control class]] )
        {
            MGS_Simple_Control  *pControl = (MGS_Simple_Control*)pView;
            
            // Can't be a pushbutton, and it should have a value tag.
            if ( ([pControl controlType] != MGS_Simple_ControlEnum_ControlType_Pushbutton) && [pControl valueTag] )
            {
                // If we have already started cataloging, then the control has to be the same type as previous controls.
                if ( (currentControlType == MGS_Simple_ControlEnum_ControlType_Pushbutton) || ([pControl controlType] == currentControlType) )
                {
                    currentControlType = [pControl controlType];    // We will only be looking for these from now on.
                    
                    // Just in case we were already there...
                    [pControl removeTarget:self
                                    action:@selector(pm_controlValueChanged:)
                          forControlEvents:UIControlEventValueChanged
                     ];
                    
                    // Make sure that we get called when the control value changes.
                    [pControl addTarget:self
                                 action:@selector(pm_controlValueChanged:)
                       forControlEvents:UIControlEventValueChanged
                     ];
                    
                    [pNewControlsArray addObject:pControl];
                    
                    if ( [pControl isChecked] ) // If this is a checked control, we add its value tag to the tag array.
                    {
                        [pNewTagArray addObject:[pControl valueTag]];
                    }
                }
            }
            
        }
    }
    
    // If we have controls and values, we set them now.
    if ( [pNewControlsArray count] )
    {
        _controls = [NSArray arrayWithArray:pNewControlsArray];
        
        if ( [pNewTagArray count] ) // This doesn't make sense if there are no controls.
        {
            _tagArray = [NSArray arrayWithArray:pNewTagArray];
        }
    }
}

/***************************************************************************/
/**
 \brief This responds to events within contained controls.
 
 \param inSender This is the control that initiated the action.
 */
- (IBAction)pm_controlValueChanged:(MGS_Simple_Control*)inSender
{
#ifdef DEBUG
    NSLog ( @"MGS_Simple_ControlGroup::pm_controlValueChanged:%@", [inSender valueTag] );
#endif
    
    [self pm_adaptToSubViews];

    // There can only be one...
    if ( ([inSender controlType] == MGS_Simple_ControlEnum_ControlType_Radio) && [inSender isChecked] )
    {
        // Uncheck all the other controls
        for ( MGS_Simple_Control *pControl in [self controls] )
        {
            if ( pControl != inSender )
            {
#ifdef DEBUG
                NSLog ( @"   Unchecking:%@", [pControl valueTag] );
#endif
                [pControl setChecked:NO];
            }
        }
    }
    
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

/***************************************************************************/
/**
 \brief Accessor. Refreshes the control state, and returns an array of checked tags.
 
 \returns an array of NSString. The valueTags of checked controls.
 */
- (NSArray*)tags
{
#ifdef DEBUG
    NSLog ( @"MGS_Simple_ControlGroup::tags" );
#endif
    
    [self pm_adaptToSubViews];
    return _tagArray;
}

/***************************************************************************/
/**
 \brief "Primes" the group with a list of tags representing checked controls.
 
 \param inTagArray This is a list of tags for controls that should be checked.

        If the tags don't match controls, they will be ignored. If there are more
        than one tag in a radiobutton set, only the first valid one will be used,
        and all others will be ignored.
*/
- (void)setTagArray:(NSArray*)inTagArray
{
#ifdef DEBUG
    NSLog ( @"MGS_Simple_ControlGroup::setTagArray:%@", inTagArray );
#endif

    _tagArray = nil;
    
    if ( inTagArray )
    {
        // If we are dealing with radiobuttons, we simply walk through until we hit our first on, then break.
        if ( [(MGS_Simple_Control*)[[self controls] objectAtIndex:0] controlType] == MGS_Simple_ControlEnum_ControlType_Radio )
        {
            for ( NSString *tag in inTagArray )
            {
                for ( MGS_Simple_Control *pControl in [self controls] )
                {
                    if ( [[pControl valueTag] isEqualToString:tag] )
                    {
                        [pControl setChecked:YES];
                        return;
                    }
                }
            }
        }
        else    // With checkboxes, we need to uncheck ones that are not in the list.
        {
            for ( MGS_Simple_Control *pControl in [self controls] )
            {
                BOOL    wasChecked = NO;
                for ( NSString *tag in inTagArray )
                {
                    if ( [[pControl valueTag] isEqualToString:tag] )
                    {
                        wasChecked = YES;
                        break;
                    }
                }
                
                [pControl setChecked:wasChecked];
            }
        }
    }
    else    // No tag array, no checks.
    {
        for ( MGS_Simple_Control *pControl in [self controls] )
        {
            [pControl setChecked:NO];
        }
    }
}
@end

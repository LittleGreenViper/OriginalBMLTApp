//
//  BMLT_Results_MapPointAnnotationView.m
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

#import "BMLT_Results_MapPointAnnotationView.h"
#import "BMLT_Meeting.h"

static int kRegularAnnotationOffsetUp   = 24; /**< This is how many pixels to shift the annotation view up. */
static int kRegularAnnotationOffsetTop  = 4;  /**< This is how many pixels to pad the top number display. */
int kRegularAnnotationOffsetRight       = 5;  /**< This is how many pixels to shift the annotation view right. */

/*****************************************************************/
/**
 \class BMLT_Results_MapPointAnnotationView
 \brief This is the base class for the standard meetings pins.
 *****************************************************************/
@implementation BMLT_Results_MapPointAnnotationView
/*****************************************************************/
/**
 \brief Initializes the annotation in the standard MapKiot manner.
 \returns self
 *****************************************************************/
- (id)initWithAnnotation:(id<MKAnnotation>)annotation
         reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    
    if ( self )
        {
        [self setCenterOffset:CGPointMake(kRegularAnnotationOffsetRight, -kRegularAnnotationOffsetUp)];
        [self selectImage];
        }
    
    return self;
}

/*****************************************************************/
/**
 \brief This tells the annotation to figure out which image it will use.
        In this class, it will choose a blue marker for just one
        meeting, or go all Neo with a red one, for multiple meetings.
 *****************************************************************/
- (void)selectImage
{
    if ( [[self annotation] isKindOfClass:[BMLT_Results_MapPointAnnotation class]] )
        {
        BOOL    isMulti = [(BMLT_Results_MapPointAnnotation *)[self annotation] getNumberOfMeetings] > 1;
        BOOL    isSelected = [(BMLT_Results_MapPointAnnotation *)[self annotation] isSelected]; 
        [self setImage:[UIImage imageNamed:(isSelected ? @"MapMarkerGreen" : isMulti ? @"MapMarkerRed" : @"MapMarkerBlue")]];
        [self setBackgroundColor:[UIColor clearColor]];
        [self setNeedsDisplay];
        }
}

/*****************************************************************/
/**
 \brief This draws the marker. We add the index number to the
        marker, so it can be associated with the listed meetings.
 *****************************************************************/
- (void)drawRect:(CGRect)rect
{
    [[self image] drawInRect:rect];
    
    BMLT_Meeting   *firstMeeting = (BMLT_Meeting *)[[(BMLT_Results_MapPointAnnotation *)[self annotation] myMeetings] objectAtIndex:0];
    
    if ( firstMeeting )
        {
        NSString    *indexString = [NSString stringWithFormat:@"%d", [firstMeeting meetingIndex]];
        
        // Blue and red get a white number. Green gets black (default).
        if ( ![(BMLT_Results_MapPointAnnotation *)[self annotation] isSelected] )
            {
            CGContextSetRGBFillColor ( UIGraphicsGetCurrentContext(), 1, 1, 1, 1 );
            }
        
        rect.size.width -= (kRegularAnnotationOffsetRight * 2);
        rect.origin.y += kRegularAnnotationOffsetTop;
        [indexString drawInRect:rect withFont:[UIFont boldSystemFontOfSize:16] lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentCenter];
        }
}

@end

/*****************************************************************/
/**
 \class BMLT_Results_BlackAnnotationView
 \brief This class replaces the red/blue choice with a black marker,
        representing the user's location.
        This is also used by the search dialog, and has an animated drag.
 *****************************************************************/
@interface BMLT_Results_BlackAnnotationView ()
@property (atomic, strong, readonly)    NSArray     *p_animationFrames;
@property (atomic, strong, readwrite)   NSTimer     *p_animationTimer;
@property (atomic, assign, readwrite)   NSInteger   p_currentFrame;
@end

@implementation BMLT_Results_BlackAnnotationView
/*****************************************************************/
/**
 \brief We simply switch on the draggable bit, here.
 \returns self
 *****************************************************************/
- (id)initWithAnnotation:(id<MKAnnotation>)annotation
         reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    
    if ( self )
    {
        [self setBackgroundColor:[UIColor clearColor]];
        [self setDraggable:YES];
        [self setSelected:YES animated:NO];
        NSArray     *pFiles = @[@"Frame01.png", @"Frame02.png", @"Frame03.png", @"Frame04.png", @"Frame05.png", @"Frame06.png", @"Frame07.png", @"Frame08.png", @"Frame09.png", @"Frame10.png"];
        
        NSMutableArray  *pImages = [[NSMutableArray alloc] init];
            
        for ( NSString *fileName in pFiles )
            {
            UIImage *pImage = [UIImage imageNamed:fileName];
                
#ifdef DEBUG
            NSLog(@"   File %@ has image %@.", fileName, pImage);
#endif
            [pImages addObject:pImage];
            }
        
        _p_animationFrames = [NSArray arrayWithArray:pImages];
        
        [self setCenterOffset:CGPointMake(kRegularAnnotationOffsetRight, -kRegularAnnotationOffsetUp)];
        [self selectImage];
    }
    
    return self;
}

/*****************************************************************/
/**
 \brief We choose black.
 *****************************************************************/
- (void)selectImage
{
    [self setImage:[UIImage imageNamed:@"MapMarkerBlack"]];
}

/*****************************************************************/
/**
 \brief Handles dragging. Changes the image while dragging.
 *****************************************************************/
- (void)setDragState:(MKAnnotationViewDragState)newDragState    ///< The upcoming drag state
            animated:(BOOL)animated                             ///< Whether or not to animate the drag.
{
#ifdef DEBUG
    NSLog(@"BMLT_Results_BlackAnnotationView::setDragState: %d animated: called.", newDragState);
#endif
    switch ( newDragState )
    {
        case MKAnnotationViewDragStateStarting:
            newDragState = MKAnnotationViewDragStateDragging;
            [self setP_currentFrame:0];
            [self setBounds:CGRectInset([self bounds], -([self bounds].size.width * 2), -([self bounds].size.height * 2))];
            [self setCenterOffset:CGPointZero];
            [self setP_animationTimer:[NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(setNeedsDisplay) userInfo:nil repeats:YES]];
            break;
            
        case MKAnnotationViewDragStateEnding:
        default:
            [[self p_animationTimer] invalidate];
            [self setP_animationTimer:nil];
            [self setCenterOffset:CGPointMake(kRegularAnnotationOffsetRight, -kRegularAnnotationOffsetUp)];
            [self setBounds:CGRectMake ( 0, 0, [[self image] size].width, [[self image] size].height)];
            newDragState = MKAnnotationViewDragStateNone;
            break;
    }
    [super setDragState:newDragState animated:animated];
    [self setNeedsDisplay];
}

/*****************************************************************/
/**
 \brief This draws the marker, dependent upon the state.
 *****************************************************************/
- (void)drawRect:(CGRect)inRect ///< The rectangle to be filled (we ignore this).
{
    if ( [self dragState] == MKAnnotationViewDragStateDragging )
        {
        UIImage *pImage = (UIImage*)[[self p_animationFrames] objectAtIndex:[self p_currentFrame]];
        
        if ( pImage )
            {
            inRect = [self bounds];
            if ( inRect.size.width < inRect.size.height )
                {
                float offset = (inRect.size.height - inRect.size.width) / 2.0;
                inRect.size.height = inRect.size.width;
                inRect.origin.y += offset;
                }
            else
                {
                float offset = (inRect.size.width - inRect.size.height) / 2.0;
                inRect.size.width = inRect.size.height;
                inRect.origin.x += offset;
                }
            [pImage drawInRect:inRect];

            NSInteger   nextFrame = [self p_currentFrame] + 1;
            
            if ( nextFrame == [[self p_animationFrames] count] )
                {
                nextFrame = 0;
                }
            
            [self setP_currentFrame:nextFrame];
            }
        }
    else
        {
        [[self image] drawInRect:[self bounds]];
        }
}
@end

/*****************************************************************/
/**
 \class BMLT_Results_MapPointAnnotation
 \brief This is the annotation controller class that we use to manage
        the markers.
 *****************************************************************/
@implementation BMLT_Results_MapPointAnnotation

@synthesize isSelected = _selected, coordinate = _coordinate, title, subtitle, displayIndex, myMeetings, dragDelegate = _dragDelegate;

/*****************************************************************/
/**
 \brief Initialize with a coordinate, and a list of meetings.
 \returns self.
 *****************************************************************/
- (id)initWithCoordinate:(CLLocationCoordinate2D)coords ///< The coordinates of this marker.
             andMeetings:(NSArray *)inMeetings          ///< A list of BMLT_Meeting objects, represented by this marker (it may be 1 meeting).
                andIndex:(NSInteger)inIndex             ///< This is an index that is displayed near the annotation. If >0, a little number is displayed, which is used to match to a printed or PDF number.
{
    self = [super init];
    
    if (self)
        {
        _coordinate = coords;
        myMeetings = [[NSMutableArray alloc] initWithArray:inMeetings];
        }
    
    return self;
}

/*****************************************************************/
/**
 \brief Sets the selected property, and triggers a redraw.
 *****************************************************************/
- (void)setIsSelected:(BOOL)isSelected
{
    _selected = isSelected;
}

/*****************************************************************/
/**
 \brief Returns the number of meetings represented by this marker.
 \returns an integer. The number of meetings represented by the marker.
 *****************************************************************/
- (NSInteger)getNumberOfMeetings
{
    if ( [self getMyMeetings] )
        {
        return [[self getMyMeetings] count];
        }
    
    return 0;
}

/*****************************************************************/
/**
 \brief Gets a particular meeting from a list.
 \returns a BMLT_Meeting object for the selected meeting.
 *****************************************************************/
- (BMLT_Meeting *)getMeetingAtIndex:(NSInteger)index    ///< The index of the desired meeting.
{
    return [[self getMyMeetings] objectAtIndex:index];
}

/*****************************************************************/
/**
 \brief Adds a meeting to the list.
 *****************************************************************/
- (void)addMeeting:(BMLT_Meeting *)inMeeting    ///< The meeting object to be added.
{
    if ( !myMeetings )
        {
        myMeetings = [[NSMutableArray alloc] init];
        }
    
    [myMeetings addObject:inMeeting];
}

/*****************************************************************/
/**
 \brief Get the raw list of meetings.
 \returns an array of BMLT_Meeting objects.
 *****************************************************************/
- (NSArray *)getMyMeetings
{
    return myMeetings;
}

@end


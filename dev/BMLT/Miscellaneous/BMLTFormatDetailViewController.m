//
//  FormatDetailView.m
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

#import "BMLTFormatDetailViewController.h"
#import "BMLT_Format.h"
#import "A_BMLTSearchResultsViewController.h"
#import <QuartzCore/QuartzCore.h>

@implementation BMLTFormatDetailViewController

/*****************************************************************/
/**
 \brief We set up the popover size, here.
 \returns self
 *****************************************************************/
- (id)initWithFormat:(BMLT_Format *)inFormat            ///< The format object for the display.
       andController:(UIViewController *)inController   ///< The modal controller for the display.
{
    self = [super init];
    
    if ( self )
        {
        myFormat = inFormat;
        CGRect  myBounds = [[self view] bounds];
        CGRect  lowestFrame = [[self formatDescription] frame];
        [self setMyModalController:inController];
        
        myBounds.size.height = lowestFrame.origin.y + lowestFrame.size.height + 8;
        
        [self setPreferredContentSize:myBounds.size];    // Make sure our popover isn't too big.
        }
    
    return self;
}

#pragma mark - View lifecycle -

/*****************************************************************/
/**
 \brief Called before the view appears.
 *****************************************************************/
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ( ![[[self navigationController] navigationBar] respondsToSelector:@selector(setBarTintColor:)] )
        {
        [[[self navigationItem] rightBarButtonItem] setTintColor:nil];
        }

}

/*****************************************************************/
/**
 \brief Set up all the various dialog items
 *****************************************************************/
- (void)viewDidLoad
{
    [self setTitle];
    [self setDescription];
    [self setUpKey];
    // With a popover, we don't need the "Done" button.
    if ( [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad )
        {
        if ( [BMLTVariantDefs popoverBackgroundColor] )
            {
            UIColor *myBGColor = [[UIColor alloc] initWithCGColor:[[BMLTVariantDefs popoverBackgroundColor] CGColor]];
            [[self view] setBackgroundColor:myBGColor];
            myBGColor = nil;
            }
        [(UINavigationItem *)[[self navBar] topItem] setRightBarButtonItem:nil animated:NO];
        }
    else
        {
        if ( [BMLTVariantDefs modalBackgroundColor] )
            {
            UIColor *myBGColor = [[UIColor alloc] initWithCGColor:[[BMLTVariantDefs modalBackgroundColor] CGColor]];
            [[self view] setBackgroundColor:[BMLTVariantDefs modalBackgroundColor]];
            myBGColor = nil;
            }
        }
    [super viewDidLoad];
}

#pragma mark - Custom Functions -

/*****************************************************************/
/**
 \brief Set up the format key display.
 *****************************************************************/
- (void)setUpKey
{
    FormatUIElements    *fmtEl = [BMLT_Format getFormatColor:myFormat];

    [[self formatKeyImage] setImage:[UIImage imageNamed:fmtEl.imageName2x]];
    [[self formatKeyLabel] setText:fmtEl.title];
    [[self formatKeyLabel] setTextColor:fmtEl.textColor];
}

/*****************************************************************/
/**
 \brief Set the format title in the navbar.
 *****************************************************************/
- (void)setTitle
{
    [[[self navBar] topItem] setTitle:[myFormat getBMLTName]];
}

/*****************************************************************/
/**
 \brief Set the format description.
 *****************************************************************/
- (void)setDescription
{
    [[self formatDescription] setText:[myFormat getBMLTDescription]];
}

/*****************************************************************/
/**
 \brief Set the modal controller data member.
 *****************************************************************/
- (void)setMyModalController:(UIViewController *)inController   ///< The modal controller for this view.
{
    myModalController = inController;
}

/*****************************************************************/
/**
 \brief   Accessor -return the view's modal controller.
 \returns the modal controller for the view.
 *****************************************************************/
- (UIViewController *)getMyModalController
{
    return myModalController;
}

/*****************************************************************/
/**
 \brief Called when the user presses the "Done" button.
 *****************************************************************/
- (IBAction)donePressed:(id)sender  ///< The done button object.
{
    [(A_BMLTSearchResultsViewController *)myModalController closeModal];
    myModalController = nil;
}

/*****************************************************************/
/**
 \brief Set the format object for this display.
 *****************************************************************/
- (void)setMyFormat:(BMLT_Format *)inFormat
{
    myFormat = inFormat;
}

/*****************************************************************/
/**
 \brief Accessor -return the format object for this display.
 \returns the display's format object.
 *****************************************************************/
- (BMLT_Format *)getMyFormat
{
    return myFormat;
}

@end

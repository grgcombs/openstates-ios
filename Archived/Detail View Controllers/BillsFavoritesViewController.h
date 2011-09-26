//
//  BillsFavoritesViewController.h
//  Created by Gregory Combs on 2/25/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import <UIKit/UIKit.h>
#import <RestKit/RestKit.h>

#define kBillFavoritesStorageFile @"FavoriteBills.plist"

@interface BillsFavoritesViewController : UITableViewController <RKRequestDelegate, UITableViewDelegate> {
	NSMutableArray *_watchList;
	NSMutableDictionary *_cachedBills;
}
- (IBAction)loadBills:(id)sender;
	
@end
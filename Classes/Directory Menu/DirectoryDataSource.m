//
//  DirectoryDataSource.m
//  TexLege
//
//  Created by Gregory S. Combs on 5/31/09.
//  Copyright 2009 Gregory S. Combs. All rights reserved.
//

#import "DirectoryDataSource.h"
#import "TexLegeAppDelegate.h"
#import "LegislatorObj.h"

#import "DetailTableViewController.h"

@implementation DirectoryDataSource

@synthesize fetchedResultsController, managedObjectContext;

@synthesize hideTableIndex;
@synthesize filterChamber, filterString;

// setup the data collection
- init {
	if (self = [super init]) {
		self.filterChamber = 0;
		self.filterString = [[[NSMutableString alloc] initWithString:@""] retain];
	}
	return self;
}

- (void)dealloc {
	if ([self hasFilter])
		[self removeFilter];
	if (filterString)
		[filterString release];
	
	[fetchedResultsController release];
	[managedObjectContext release];
    [super dealloc];
}

#pragma mark -
#pragma mark TableDataSourceProtocol methods
// return the data used by the navigation controller and tab bar item

- (NSString *)name 
{ return @"Directory"; }

- (NSString *)navigationBarName 
{ return @"Legislator Directory"; }

- (UIImage *)tabBarImage 
{ return [UIImage imageNamed:@"Directory.png"]; }

- (BOOL)showDisclosureIcon
{ return NO; }

- (BOOL)usesCoreData
{ return YES; }

- (BOOL)usesToolbar
{ return YES; }

- (BOOL)usesSearchbar
{ return YES; }

- (BOOL)canEdit
{ return NO; }

#pragma mark -
#pragma mark UITableViewDataSource methods

// legislator name is displayed in a plain style tableview

- (UITableViewStyle)tableViewStyle {
	return UITableViewStylePlain;
};



// return the legislator at the index in the sorted by symbol array
- (LegislatorObj *)legislatorDataForIndexPath:(NSIndexPath *)indexPath {
	
	// DO A TRANSLATION HERE UNTIL WE GET A COMPLETE COMMITTEOBJ MODEL (WITH RELATIONSHIPS)
	LegislatorObj *tempEntry = [fetchedResultsController objectAtIndexPath:indexPath];
	//return [[[LegislatorsListing sharedLegislators] legislatorDictionary] objectForKey:tempEntry.legislatorID];
	return tempEntry;	
}


// UITableViewDataSource methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *MyIdentifier = @"LegislatorDirectory";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:MyIdentifier] autorelease];
	}
#if NEEDS_TO_INITIALIZE_DATABASE
	[self initializeDatabase];
#endif
    
	LegislatorObj *tempEntry = [self legislatorDataForIndexPath:indexPath];
	
	if (tempEntry == nil) {
		debug_NSLog(@"Busted in DirectoryDataSource.m: cellForRowAtIndexPath -> Couldn't get legislator data for row.");
		return nil;
	}
	
	// configure cell contents
	cell.textLabel.text = [NSString stringWithFormat: @"%@ - (%@)", 
						   [tempEntry legProperName], [tempEntry partyShortName]];
	cell.textLabel.font = [UIFont boldSystemFontOfSize:16];
	cell.detailTextLabel.text = [tempEntry labelSubText];
	cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:12];
	cell.detailTextLabel.textColor = [UIColor lightGrayColor];
	
	cell.imageView.image = [tempEntry smallLegislatorImage];

	// all the rows should show the disclosure indicator
	if ([self showDisclosureIcon])
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	return cell;
}

#pragma mark -
#pragma mark Indexing / Sections


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {	
	NSInteger count = [[fetchedResultsController sections] count];		
	if (count > 1 /*&! self.hasFilter*/)  {
		return count; 
	}
	return 1;	
}

// This is for the little index along the right side of the table ... use nil if you don't want it.
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	return  hideTableIndex ? nil : [fetchedResultsController sectionIndexTitles] ;
	//return  nil ;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
	return index; // index ..........
}

- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section {
	// eventually (soon) we'll need to create a new fetchedResultsController to filter for chamber selection
	NSInteger count = [[fetchedResultsController sections] count];		
	if (count > 1) {
		id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedResultsController sections] objectAtIndex:section];
		count = [sectionInfo numberOfObjects];
	}
	return count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	// this table has multiple sections. One for each unique character that an element begins with
	// [A,B,C,D,E,F,G,H,I,K,L,M,N,O,P,R,S,T,U,V,X,Y,Z]
	// return the letter that represents the requested section
	
	NSInteger count = [[fetchedResultsController sections] count];		
	if (count > 1 /*&! self.hasFilter*/)  {
		id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedResultsController sections] objectAtIndex:section];
		return [sectionInfo indexTitle]; // or [sectionInfo name];
	}
	return @"";
}

#pragma mark -
#pragma mark Filtering Functions

// do we want to do a proper whichFilter sort of thing?
- (BOOL) hasFilter {
	return (self.filterString.length > 0 || self.filterChamber > 0);
}

// Predicate Programming
// You want your search to be diacritic insensitive to match the 'é' in pensée and 'e' in pensee. 
// You get this by adding the [d] after the attribute; the [c] means case insensitive.
//
// We can also do: "(firstName beginswith 'G') AND (lastName like 'Combs')"
//    or: "group.name matches "'work.*'", "ALL children.age > 12", and "ANY children.age > 12"
//    or for operations: "@sum.items.price < 1000"
//
// The matches operator uses regex, so is not supported by Core Data’s SQL store— although 
//     it does work with in-memory filtering.
// *** The Core Data SQL store supports only one to-many operation per query; therefore in any predicate 
//      sent to the SQL store, there may be only one operator (and one instance of that operator) 
//      from ALL, ANY, and IN.
// You cannot necessarily translate “arbitrary” SQL queries into predicates.
//*

- (void) updateFilterPredicate {
	NSMutableString * predString = [NSMutableString stringWithString:@""];
		
	if (self.filterChamber > 0)	// do some chamber filtering
		[predString appendFormat:@"(legtype == %@)", [NSNumber numberWithInt:self.filterChamber]];
	if (self.filterString.length > 0) {		// do some string filtering
		if (predString.length > 0)	// we already have some predicate action, insert "AND"
			[predString appendString:@" AND "];
		[predString appendFormat:@"((lastname CONTAINS[cd] '%@') OR (firstname CONTAINS[cd] '%@')", self.filterString, self.filterString];
		[predString appendFormat:@" OR (middlename CONTAINS[cd] '%@') OR (nickname CONTAINS[cd] '%@')", self.filterString, self.filterString];
		[predString appendFormat:@" OR (district CONTAINS[cd] '%@'))", self.filterString];
	}
	
	NSPredicate *predicate = (predString.length > 0) ? [NSPredicate predicateWithFormat:predString] : nil;
	
	[fetchedResultsController.fetchRequest setPredicate:predicate];
	
	NSError *error = nil;
	if (![[self fetchedResultsController] performFetch:&error]) {
        // Handle error
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
    }           
}

// probably unnecessary, but we might as well validate the new info with our expectations...
- (void) setFilterByString:(NSString *)filter {
	if (![self.filterString isEqualToString:filter]) {
		self.filterString = (filter==nil) ? @"" : filter;
	}
	// we also get called on toolbar chamber switches, with or without a search string, so update anyway...
	[self updateFilterPredicate];	
}

- (void) removeFilter {
	// do we want to tell it to clear out our chamber selection too? Not really, the ViewController sets it for us.
	// self.filterChamber = 0;
	[self setFilterByString:@""]; // we updateFilterPredicate automatically
	
}	

#pragma mark -
#pragma mark Core Data Methods

#if NEEDS_TO_INITIALIZE_DATABASE

- (void)initializeDatabase {
	NSInteger count = [[self.fetchedResultsController sections] count];
	if (count == 0) { // try initializing it...
		
		// Create a new instance of the entity managed by the fetched results controller.
		NSManagedObjectContext *context = [fetchedResultsController managedObjectContext];
		NSEntityDescription *entity = [[fetchedResultsController fetchRequest] entity];
		
		// read the legislator data from the plist
		NSString *thePath = [[NSBundle mainBundle]  pathForResource:@"Legislators" ofType:@"plist"];
		NSArray *rawPlistArray = [[NSArray alloc] initWithContentsOfFile:thePath];
		
		// iterate over the values in the raw  dictionary
		for (NSDictionary * aDictionary in rawPlistArray)
		{
			// create an legislator instance for each
			NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:
												 [entity name] inManagedObjectContext:context];
			
			[newManagedObject setValue:[aDictionary valueForKey:@"legislatorID"] forKey:@"legislatorID"];
			[newManagedObject setValue:[aDictionary valueForKey:@"legtype"] forKey:@"legtype"];
			[newManagedObject setValue:[aDictionary valueForKey:@"legtype_name"] forKey:@"legtype_name"];
			[newManagedObject setValue:[aDictionary valueForKey:@"lastname"] forKey:@"lastname"];
			[newManagedObject setValue:[aDictionary valueForKey:@"firstname"] forKey:@"firstname"];
			[newManagedObject setValue:[aDictionary valueForKey:@"middlename"] forKey:@"middlename"];
			[newManagedObject setValue:[aDictionary valueForKey:@"nickname"] forKey:@"nickname"];
			[newManagedObject setValue:[aDictionary valueForKey:@"suffix"] forKey:@"suffix"];
			[newManagedObject setValue:[aDictionary valueForKey:@"party_name"] forKey:@"party_name"];
			[newManagedObject setValue:[aDictionary valueForKey:@"party_id"] forKey:@"party_id"];
			[newManagedObject setValue:[aDictionary valueForKey:@"district"] forKey:@"district"];
			[newManagedObject setValue:[aDictionary valueForKey:@"tenure"] forKey:@"tenure"];
			[newManagedObject setValue:[aDictionary valueForKey:@"partisan_index"] forKey:@"partisan_index"];
			
			[newManagedObject setValue:[aDictionary valueForKey:@"photo_name"] forKey:@"photo_name"];
			//		[newManagedObject setValue:[aDictionary valueForKey:@"leg_image"] forKey:@"leg_image"];
			
			[newManagedObject setValue:[aDictionary valueForKey:@"bio_url"] forKey:@"bio_url"];
			[newManagedObject setValue:[aDictionary valueForKey:@"twitter"] forKey:@"twitter"];
			[newManagedObject setValue:[aDictionary valueForKey:@"email"] forKey:@"email"];
			
			[newManagedObject setValue:[aDictionary valueForKey:@"notes"] forKey:@"notes"];
			[newManagedObject setValue:[aDictionary valueForKey:@"chamber_desk"] forKey:@"chamber_desk"];
			
			[newManagedObject setValue:[aDictionary valueForKey:@"cap_office"] forKey:@"cap_office"];
			[newManagedObject setValue:[aDictionary valueForKey:@"staff"] forKey:@"staff"];
			[newManagedObject setValue:[aDictionary valueForKey:@"cap_phone"] forKey:@"cap_phone"];
			[newManagedObject setValue:[aDictionary valueForKey:@"cap_fax"] forKey:@"cap_fax"];
			[newManagedObject setValue:[aDictionary valueForKey:@"cap_phone2_name"] forKey:@"cap_phone2_name"];
			[newManagedObject setValue:[aDictionary valueForKey:@"cap_phone2"] forKey:@"cap_phone2"];
			
			[newManagedObject setValue:[aDictionary valueForKey:@"dist1_street"] forKey:@"dist1_street"];
			[newManagedObject setValue:[aDictionary valueForKey:@"dist1_city"] forKey:@"dist1_city"];
			[newManagedObject setValue:[aDictionary valueForKey:@"dist1_zip"] forKey:@"dist1_zip"];
			[newManagedObject setValue:[aDictionary valueForKey:@"dist1_phone"] forKey:@"dist1_phone"];
			[newManagedObject setValue:[aDictionary valueForKey:@"dist1_fax"] forKey:@"dist1_fax"];
			
			[newManagedObject setValue:[aDictionary valueForKey:@"dist2_street"] forKey:@"dist2_street"];
			[newManagedObject setValue:[aDictionary valueForKey:@"dist2_city"] forKey:@"dist2_city"];
			[newManagedObject setValue:[aDictionary valueForKey:@"dist2_zip"] forKey:@"dist2_zip"];
			[newManagedObject setValue:[aDictionary valueForKey:@"dist2_phone"] forKey:@"dist2_phone"];
			[newManagedObject setValue:[aDictionary valueForKey:@"dist2_fax"] forKey:@"dist2_fax"];
			
			[newManagedObject setValue:[aDictionary valueForKey:@"dist3_street"] forKey:@"dist3_street"];
			[newManagedObject setValue:[aDictionary valueForKey:@"dist3_city"] forKey:@"dist3_city"];
			[newManagedObject setValue:[aDictionary valueForKey:@"dist3_zip"] forKey:@"dist3_zip"];
			[newManagedObject setValue:[aDictionary valueForKey:@"dist3_phone1"] forKey:@"dist3_phone1"];
			[newManagedObject setValue:[aDictionary valueForKey:@"dist3_fax"] forKey:@"dist3_fax"];
			
			[newManagedObject setValue:[aDictionary valueForKey:@"dist4_street"] forKey:@"dist4_street"];
			[newManagedObject setValue:[aDictionary valueForKey:@"dist4_city"] forKey:@"dist4_city"];
			[newManagedObject setValue:[aDictionary valueForKey:@"dist4_zip"] forKey:@"dist4_zip"];
			[newManagedObject setValue:[aDictionary valueForKey:@"dist4_phone1"] forKey:@"dist4_phone1"];
			[newManagedObject setValue:[aDictionary valueForKey:@"dist4_fax"] forKey:@"dist4_fax"];
			
			// Save the context.
			NSError *error;
			if (![context save:&error]) {
				// Handle the error...
			}
		}
		// release the raw data
		[rawPlistArray release];
	}
}
#endif

/*
 Set up the fetched results controller.
 */
- (NSFetchedResultsController *)fetchedResultsController {
    
    if (fetchedResultsController != nil) {
        return fetchedResultsController;
    }
    
	// Create the fetch request for the entity.
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	
	// Get our table-specific Core Data.
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"LegislatorObj" inManagedObjectContext:managedObjectContext];
	[fetchRequest setEntity:entity];
	
	// Sort by committeeName.
	NSSortDescriptor *nameInitialSortOrder = [[NSSortDescriptor alloc] initWithKey:@"lastname"
																   ascending:YES] ;
	NSSortDescriptor *firstDescriptor = [[NSSortDescriptor alloc] initWithKey:@"firstname"
																	ascending:YES] ;
	[fetchRequest setSortDescriptors:[NSArray arrayWithObjects:nameInitialSortOrder, firstDescriptor, nil]];
	
	
	NSString * sectionString;
	// we don't want sections when searching, change to hasFilter if you don't want it for toolbarAction either...
    // nil for section name key path means "no sections".
	if (self.filterString.length > 0) 
		sectionString = nil;
	else
		sectionString = @"lastnameInitial";
	
	NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] 
															 initWithFetchRequest:fetchRequest 
															 managedObjectContext:managedObjectContext 
															 sectionNameKeyPath:sectionString cacheName:@"Root"];
	
    aFetchedResultsController.delegate = self;
	self.fetchedResultsController = aFetchedResultsController;
	
	[aFetchedResultsController release];
	[fetchRequest release];
	[nameInitialSortOrder release];	
	[firstDescriptor release];	

	return fetchedResultsController;
}    

@end
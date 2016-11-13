#import "BillVoter.h"
#import <SLFRestKit/CoreData.h>

@implementation BillVoter

+ (RKManagedObjectMapping *)mapping {
    RKManagedObjectMapping *mapping = [RKManagedObjectMapping mappingForClass:[self class] inManagedObjectStore:[RKObjectManager sharedManager].objectStore];
    [mapping mapKeyPath:@"leg_id" toAttribute:@"legID"];
    [mapping mapAttributes:@"name", nil];
    return mapping;
}

+ (NSArray *)sortDescriptors {
    return [[self superclass] sortDescriptors];
}

@end

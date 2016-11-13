#import "CommitteeMember.h"
#import "SLFLegislator.h"
#import "SLFSortDescriptor.h"
#import <SLFRestKit/CoreData.h>

@implementation CommitteeMember

+ (RKManagedObjectMapping *)mapping {
    RKManagedObjectMapping *mapping = [RKManagedObjectMapping mappingForClass:[self class] inManagedObjectStore:[RKObjectManager sharedManager].objectStore];
    [mapping mapKeyPath:@"leg_id" toAttribute:@"legID"];
    [mapping mapKeyPath:@"role" toAttribute:@"type"];
    [mapping mapAttributes:@"name", nil];
    return mapping;
}

- (SLFLegislator *)foundLegislator {
    SLFLegislator *foundLegislator = nil;
    if (self.legID)
        foundLegislator = [SLFLegislator findFirstByAttribute:@"legID" withValue:self.legID];
    return foundLegislator;
}

- (NSString *)type {
    [self willAccessValueForKey:@"type"];
    NSString *aRole = [self primitiveValueForKey:@"type"];
    [self didAccessValueForKey:@"type"];
    if (aRole)
        aRole = [aRole capitalizedString];
    return aRole;
}

+ (NSArray *)sortDescriptors {
    NSArray *existing = [[self superclass] sortDescriptors];
    NSMutableArray *descriptors = [NSMutableArray arrayWithArray:existing];
    [descriptors insertObject:[SLFSortDescriptor stringSortDescriptorWithKey:@"foundLegislator.lastName" ascending:YES] atIndex:1];
    return descriptors;
}

@end

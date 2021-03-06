//
//  RKManagedObjectMapping.m
//  RestKit
//
//  Created by Blake Watters on 5/31/11.
//  Copyright 2011 Two Toasters
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "RKManagedObjectMapping.h"
#import "NSManagedObject+ActiveRecord.h"
#import "RKManagedObjectStore.h"
#import "RKDynamicObjectMappingMatcher.h"
#import "RKObjectPropertyInspector+CoreData.h"
#import "../Support/RKLog.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitCoreData

@implementation RKManagedObjectMapping

@synthesize entity = _entity;
@synthesize primaryKeyAttribute = _primaryKeyAttribute;
@synthesize objectStore = _objectStore;

+ (id)mappingForClass:(Class)objectClass {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException 
                                   reason:[NSString stringWithFormat:@"You must provide a managedObjectStore. Invoke mappingForClass:inManagedObjectStore: instead."]
                                 userInfo:nil];
}

+ (id)mappingForClass:(Class)objectClass inManagedObjectStore:(RKManagedObjectStore*)objectStore {
    return [self mappingForEntityWithName:NSStringFromClass(objectClass) inManagedObjectStore:objectStore];
}

+ (RKManagedObjectMapping*)mappingForEntity:(NSEntityDescription*)entity inManagedObjectStore:(RKManagedObjectStore*)objectStore {
    return [[[self alloc] initWithEntity:entity inManagedObjectStore:objectStore] autorelease];
}

+ (RKManagedObjectMapping*)mappingForEntityWithName:(NSString*)entityName inManagedObjectStore:(RKManagedObjectStore*)objectStore {
    return [self mappingForEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:objectStore.managedObjectContext]
             inManagedObjectStore:objectStore];
}

- (id)initWithEntity:(NSEntityDescription*)entity inManagedObjectStore:(RKManagedObjectStore*)objectStore {
    NSAssert(entity, @"Cannot initialize an RKManagedObjectMapping without an entity. Maybe you want RKObjectMapping instead?");
    NSAssert(objectStore, @"Object store cannot be nil");
    self = [self init];
    if (self) {
        self.objectClass = NSClassFromString([entity managedObjectClassName]);
        _entity = [entity retain];
        _objectStore = objectStore;
    }
    
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        _relationshipToPrimaryKeyMappings = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)dealloc {
    [_entity release];
    [_relationshipToPrimaryKeyMappings release];
    [super dealloc];
}

- (NSDictionary*)relationshipsAndPrimaryKeyAttributes {
    return _relationshipToPrimaryKeyMappings;
}

- (void)connectRelationship:(NSString*)relationshipName withObjectForPrimaryKeyAttribute:(NSString*)primaryKeyAttribute {
    NSAssert([_relationshipToPrimaryKeyMappings objectForKey:relationshipName] == nil, @"Cannot add connect relationship %@ by primary key, a mapping already exists.", relationshipName);
    [_relationshipToPrimaryKeyMappings setObject:primaryKeyAttribute forKey:relationshipName];
}

- (void)connectRelationshipsWithObjectsForPrimaryKeyAttributes:(NSString*)firstRelationshipName, ... {
    va_list args;
    va_start(args, firstRelationshipName);
    for (NSString* relationshipName = firstRelationshipName; relationshipName != nil; relationshipName = va_arg(args, NSString*)) {
		NSString* primaryKeyAttribute = va_arg(args, NSString*);
        NSAssert(primaryKeyAttribute != nil, @"Cannot connect a relationship without an attribute containing the primary key");
        [self connectRelationship:relationshipName withObjectForPrimaryKeyAttribute:primaryKeyAttribute];
        // TODO: Raise proper exception here, argument error...
    }
    va_end(args);
}

- (void)connectRelationship:(NSString*)relationshipName withObjectForPrimaryKeyAttribute:(NSString*)primaryKeyAttribute whenValueOfKeyPath:(NSString*)keyPath isEqualTo:(id)value {
    NSAssert([_relationshipToPrimaryKeyMappings objectForKey:relationshipName] == nil, @"Cannot add connect relationship %@ by primary key, a mapping already exists.", relationshipName);
    RKDynamicObjectMappingMatcher* matcher = [[RKDynamicObjectMappingMatcher alloc] initWithKey:keyPath value:value primaryKeyAttribute:primaryKeyAttribute];
    [_relationshipToPrimaryKeyMappings setObject:matcher forKey:relationshipName];
    [matcher release];
}

- (void)connectRelationship:(NSString*)relationshipName withObjectForPrimaryKeyAttribute:(NSString*)primaryKeyAttribute usingEvaluationBlock:(BOOL (^)(id data))block {
    NSAssert([_relationshipToPrimaryKeyMappings objectForKey:relationshipName] == nil, @"Cannot add connect relationship %@ by primary key, a mapping already exists.", relationshipName);
    RKDynamicObjectMappingMatcher* matcher = [[RKDynamicObjectMappingMatcher alloc] initWithPrimaryKeyAttribute:primaryKeyAttribute evaluationBlock:block];
    [_relationshipToPrimaryKeyMappings setObject:matcher forKey:relationshipName];
    [matcher release];
}

- (id)defaultValueForMissingAttribute:(NSString*)attributeName {
    NSAttributeDescription *desc = [[self.entity attributesByName] valueForKey:attributeName];
    return [desc defaultValue];
}

- (id)mappableObjectForData:(id)mappableData {    
    NSAssert(mappableData, @"Mappable data cannot be nil");

    id object = nil;
    id primaryKeyValue = nil;
    NSString* primaryKeyAttribute;
    
    NSEntityDescription* entity = [self entity];
    RKObjectAttributeMapping* primaryKeyAttributeMapping = nil;
    
    primaryKeyAttribute = [self primaryKeyAttribute];
    if (primaryKeyAttribute) {
        // If a primary key has been set on the object mapping, find the attribute mapping
        // so that we can extract any existing primary key from the mappable data
        for (RKObjectAttributeMapping* attributeMapping in self.attributeMappings) {
            if ([attributeMapping.destinationKeyPath isEqualToString:primaryKeyAttribute]) {
                primaryKeyAttributeMapping = attributeMapping;
                break;
            }
        }
        
        // Get the primary key value out of the mappable data (if any)        
        if ([primaryKeyAttributeMapping isMappingForKeyOfNestedDictionary]) {
            RKLogDebug(@"Detected use of nested dictionary key as primaryKey attribute...");
            primaryKeyValue = [[mappableData allKeys] lastObject];
        } else {
            NSString* keyPathForPrimaryKeyElement = primaryKeyAttributeMapping.sourceKeyPath;
            if (keyPathForPrimaryKeyElement) {
                primaryKeyValue = [mappableData valueForKeyPath:keyPathForPrimaryKeyElement];
            }
        }        
    }
    
    // If we have found the primary key attribute & value, try to find an existing instance to update
    if (primaryKeyAttribute && primaryKeyValue) {                
        object = [_objectStore findOrCreateInstanceOfEntity:entity withPrimaryKeyAttribute:primaryKeyAttribute andValue:primaryKeyValue];
        NSAssert2(object, @"Failed creation of managed object with entity '%@' and primary key value '%@'", entity.name, primaryKeyValue);
    } else {
        object = [[[NSManagedObject alloc] initWithEntity:entity
                           insertIntoManagedObjectContext:_objectStore.managedObjectContext] autorelease];
    }
    
    return object;
}

- (Class)classForProperty:(NSString*)propertyName {
    Class propertyClass = [super classForProperty:propertyName];
    if (! propertyClass) {
        propertyClass = [[RKObjectPropertyInspector sharedInspector] typeForProperty:propertyName ofEntity:self.entity];
    }
    
    return propertyClass;
}

@end

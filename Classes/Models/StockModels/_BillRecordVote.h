// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to BillRecordVote.h instead.

#import <CoreData/CoreData.h>


@class SLFBill;
@class BillVoter;
@class BillVoter;
@class GenericAsset;
@class BillVoter;
















@interface BillRecordVoteID : NSManagedObjectID {}
@end

@interface _BillRecordVote : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (BillRecordVoteID*)objectID;




@property (nonatomic, strong) NSString *billChamber;


//- (BOOL)validateBillChamber:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *chamber;


//- (BOOL)validateChamber:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSDate *date;


//- (BOOL)validateDate:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *method;


//- (BOOL)validateMethod:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *motion;


//- (BOOL)validateMotion:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber *noCount;


@property short noCountValue;
- (short)noCountValue;
- (void)setNoCountValue:(short)value_;

//- (BOOL)validateNoCount:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber *otherCount;


@property short otherCountValue;
- (short)otherCountValue;
- (void)setOtherCountValue:(short)value_;

//- (BOOL)validateOtherCount:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber *passed;


@property BOOL passedValue;
- (BOOL)passedValue;
- (void)setPassedValue:(BOOL)value_;

//- (BOOL)validatePassed:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *record;


//- (BOOL)validateRecord:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *session;


//- (BOOL)validateSession:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *stateID;


//- (BOOL)validateStateID:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *type;


//- (BOOL)validateType:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *voteID;


//- (BOOL)validateVoteID:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber *yesCount;


@property short yesCountValue;
- (short)yesCountValue;
- (void)setYesCountValue:(short)value_;

//- (BOOL)validateYesCount:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) SLFBill* bill;

//- (BOOL)validateBill:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSSet* noVotes;

- (NSMutableSet*)noVotesSet;




@property (nonatomic, strong) NSSet* otherVotes;

- (NSMutableSet*)otherVotesSet;




@property (nonatomic, strong) NSSet* sources;

- (NSMutableSet*)sourcesSet;




@property (nonatomic, strong) NSSet* yesVotes;

- (NSMutableSet*)yesVotesSet;




@end

@interface _BillRecordVote (CoreDataGeneratedAccessors)

- (void)addNoVotes:(NSSet*)value_;
- (void)removeNoVotes:(NSSet*)value_;
- (void)addNoVotesObject:(BillVoter*)value_;
- (void)removeNoVotesObject:(BillVoter*)value_;

- (void)addOtherVotes:(NSSet*)value_;
- (void)removeOtherVotes:(NSSet*)value_;
- (void)addOtherVotesObject:(BillVoter*)value_;
- (void)removeOtherVotesObject:(BillVoter*)value_;

- (void)addSources:(NSSet*)value_;
- (void)removeSources:(NSSet*)value_;
- (void)addSourcesObject:(GenericAsset*)value_;
- (void)removeSourcesObject:(GenericAsset*)value_;

- (void)addYesVotes:(NSSet*)value_;
- (void)removeYesVotes:(NSSet*)value_;
- (void)addYesVotesObject:(BillVoter*)value_;
- (void)removeYesVotesObject:(BillVoter*)value_;

@end

@interface _BillRecordVote (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveBillChamber;
- (void)setPrimitiveBillChamber:(NSString*)value;




- (NSString*)primitiveChamber;
- (void)setPrimitiveChamber:(NSString*)value;




- (NSDate*)primitiveDate;
- (void)setPrimitiveDate:(NSDate*)value;




- (NSString*)primitiveMethod;
- (void)setPrimitiveMethod:(NSString*)value;




- (NSString*)primitiveMotion;
- (void)setPrimitiveMotion:(NSString*)value;




- (NSNumber*)primitiveNoCount;
- (void)setPrimitiveNoCount:(NSNumber*)value;

- (short)primitiveNoCountValue;
- (void)setPrimitiveNoCountValue:(short)value_;




- (NSNumber*)primitiveOtherCount;
- (void)setPrimitiveOtherCount:(NSNumber*)value;

- (short)primitiveOtherCountValue;
- (void)setPrimitiveOtherCountValue:(short)value_;




- (NSNumber*)primitivePassed;
- (void)setPrimitivePassed:(NSNumber*)value;

- (BOOL)primitivePassedValue;
- (void)setPrimitivePassedValue:(BOOL)value_;




- (NSString*)primitiveRecord;
- (void)setPrimitiveRecord:(NSString*)value;




- (NSString*)primitiveSession;
- (void)setPrimitiveSession:(NSString*)value;




- (NSString*)primitiveStateID;
- (void)setPrimitiveStateID:(NSString*)value;




- (NSString*)primitiveType;
- (void)setPrimitiveType:(NSString*)value;




- (NSString*)primitiveVoteID;
- (void)setPrimitiveVoteID:(NSString*)value;




- (NSNumber*)primitiveYesCount;
- (void)setPrimitiveYesCount:(NSNumber*)value;

- (short)primitiveYesCountValue;
- (void)setPrimitiveYesCountValue:(short)value_;





- (SLFBill*)primitiveBill;
- (void)setPrimitiveBill:(SLFBill*)value;



- (NSMutableSet*)primitiveNoVotes;
- (void)setPrimitiveNoVotes:(NSMutableSet*)value;



- (NSMutableSet*)primitiveOtherVotes;
- (void)setPrimitiveOtherVotes:(NSMutableSet*)value;



- (NSMutableSet*)primitiveSources;
- (void)setPrimitiveSources:(NSMutableSet*)value;



- (NSMutableSet*)primitiveYesVotes;
- (void)setPrimitiveYesVotes:(NSMutableSet*)value;


@end

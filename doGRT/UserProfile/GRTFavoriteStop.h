//
//  GRTFavoriteStop.h
//  doGRT
//
//  Created by Greg Wang on 12-9-25.
//
//

#import <CoreData/CoreData.h>
#import <MapKit/MapKit.h>

@interface GRTFavoriteStop : NSManagedObject <MKAnnotation>

@property (nonatomic, retain) NSNumber * stop_id;
@property (nonatomic, retain) NSString * display_name;
@property (nonatomic, retain) NSNumber * display_order;

// Center latitude and longitude of the annotion view.
// The implementation of this property must be KVO compliant.
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

// Title and subtitle for use by selection UI.
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *subtitle;

@end

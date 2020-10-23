#import <MapKit/MapKit.h>
#import "RNMapsDirections.h"
#import <React/RCTConvert.h>
#import <CoreLocation/CoreLocation.h>
#import <React/RCTConvert+CoreLocation.h>
#import <React/RCTUtils.h>
#import <React/RCTLog.h>

@interface RCTConvert (Mapkit)

+ (MKCoordinateSpan)MKCoordinateSpan:(id)json;
+ (MKCoordinateRegion)MKCoordinateRegion:(id)json;

@end

@implementation RCTConvert(MapKit)

+ (MKCoordinateSpan)MKCoordinateSpan:(id)json
{
    json = [self NSDictionary:json];
    return (MKCoordinateSpan){
        [self CLLocationDegrees:json[@"latitudeDelta"]],
        [self CLLocationDegrees:json[@"longitudeDelta"]]
    };
}

+ (MKCoordinateRegion)MKCoordinateRegion:(id)json
{
    return (MKCoordinateRegion){
        [self CLLocationCoordinate2D:json],
        [self MKCoordinateSpan:json]
    };
}

@end

@implementation RNDirections
{
    MKLocalSearch *localSearch;
    MKDirectionsRequest *directionRequest;
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE()

- (NSArray *)formatLocalSearchCallback:(MKLocalSearchResponse *)localSearchResponse
{
    NSMutableArray *RCTResponse = [[NSMutableArray alloc] init];
    
    for (MKMapItem *mapItem in localSearchResponse.mapItems) {
        NSMutableDictionary *formedLocation = [[NSMutableDictionary alloc] init];
        
        [formedLocation setValue:mapItem.name forKey:@"name"];
        [formedLocation setValue:mapItem.url.absoluteURL forKey:@"absoluteUrl"];
        [formedLocation setValue:mapItem.url.absoluteString forKey:@"absoluteStrUrl"];
        if (@available(iOS 9.0, *)) {
            [formedLocation setValue:mapItem.timeZone forKey:@"timeZone"];
        } else {
            // Fallback on earlier versions
        }
        [formedLocation setObject:[NSNumber numberWithBool:mapItem.isCurrentLocation] forKey:@"isCurrentLocation"];
        if (@available(iOS 13.0, *)) {
            [formedLocation setValue:mapItem.pointOfInterestCategory forKey:@"pointOfInterestCategory"];
        } else {
            // Fallback on earlier versions
        }
        [formedLocation setValue:mapItem.placemark.title forKey:@"address"];
        [formedLocation setValue:@{@"latitude": @(mapItem.placemark.coordinate.latitude),
                                   @"longitude": @(mapItem.placemark.coordinate.longitude)} forKey:@"location"];
        
        [RCTResponse addObject:formedLocation];
    }
    
    return [RCTResponse copy];
}

RCT_EXPORT_METHOD(getRouteDetails:(NSDictionary *)placemarks callback:(RCTResponseSenderBlock)callback){
    
//    [directionRequest cancel];
    
    double originLatitude = [[placemarks objectForKey:@"originLatitude"] doubleValue];
    double originLongitude = [[placemarks objectForKey:@"originLongitude"] doubleValue];
    double destinationLatitude = [[placemarks objectForKey:@"destinationLatitude"] doubleValue];
    double destinationLongitude = [[placemarks objectForKey:@"destinationLongitude"] doubleValue];
    
    
    MKPlacemark *placemarkOne = [[MKPlacemark alloc] initWithCoordinate:CLLocationCoordinate2DMake(originLatitude, originLongitude)];
    MKPlacemark *placemarkTwo = [[MKPlacemark alloc] initWithCoordinate:CLLocationCoordinate2DMake(destinationLatitude, destinationLongitude)];

    
    MKMapItem *sourceMapItem = [[MKMapItem alloc] initWithPlacemark:placemarkOne];
    MKMapItem *destinationMapItem = [[MKMapItem alloc] initWithPlacemark:placemarkTwo];
    
    directionRequest = [[MKDirectionsRequest alloc] init];
    [directionRequest setSource:sourceMapItem];
    [directionRequest setDestination:destinationMapItem];
    [directionRequest setTransportType:MKDirectionsTransportTypeWalking];
    [directionRequest setRequestsAlternateRoutes:NO];
    
    MKDirections *directions = [[MKDirections alloc] initWithRequest:directionRequest];
    
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        if(error) {
            RCTLog(@"Error with address: %@", error.localizedFailureReason);
        }
        if ( ! error && [response routes] > 0) {
            NSMutableArray *polylinePoints = [NSMutableArray array];
            MKRoute *firstRoute = [[response routes] objectAtIndex:0];
                NSArray *steps = firstRoute.steps;
                for (MKRouteStep *step in steps) {
                    NSLog(@"---------------------------------------------------------------------------------");
                    NSLog(@"instruction %@", step.instructions);
                    NSLog(@"notice %@", step.notice);
                    NSLog(@"distance %f", step.distance);
                    NSLog(@"latitude %f", step.polyline.coordinate.latitude);
                    NSLog(@"longitude %f", step.polyline.coordinate.longitude);
                    NSLog(@"---------------------------------------------------------------------------------");
                    NSDictionary *currentStep =@{
                        @"instructions": step.instructions,
                        @"distance": [NSNumber numberWithDouble:step.distance],
                        @"latitude": [NSNumber numberWithDouble:step.polyline.coordinate.latitude],
                        @"longitude": [NSNumber numberWithDouble:step.polyline.coordinate.longitude],
                    };
                    [polylinePoints addObject:currentStep];
                }
            
            
            MKRoute *route = [[response routes] objectAtIndex:0];
                
            NSDictionary *successDict =@{
                                         @"eta": [NSNumber numberWithDouble:route.expectedTravelTime],
                                         @"distance": [NSNumber numberWithDouble: route.distance],
                                         @"waypoints": [RCTConvert NSArray:polylinePoints],
                                         };
                                        
            
            callback(@[successDict]);
        }
    }];
}


@end

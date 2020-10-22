#import <MapKit/MapKit.h>
#import "RNMapsDirections.h"
#import <React/RCTConvert.h>
#import <CoreLocation/CoreLocation.h>
#import <React/RCTConvert+CoreLocation.h>
#import <React/RCTUtils.h>
#import <React/RCTLog.h>

@implementation RNMapsDirections
{
    MKLocalSearch *localSearch;
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(fetchDirections:(NSDictionary *)placemarks callback:(RCTResponseSenderBlock)callback){
    
    [directionRequest cancel];
    
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

#import <MapKit/MapKit.h>
#import "RNMapsDirections.h"
#import <React/RCTConvert.h>
#import <CoreLocation/CoreLocation.h>
#import <React/RCTConvert+CoreLocation.h>
#import <React/RCTUtils.h>
#import <React/RCTLog.h>

@implementation RNMapsDirections
{
    MKDirectionsRequest *directionRequest;
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(getRouteDetails:(NSDictionary *)placemarks mode:(NSString *)mode callback:(RCTResponseSenderBlock)callback){
    
//    [directionRequest cancel];
    
    double originLatitude = [[placemarks objectForKey:@"originLatitude"] doubleValue];
    double originLongitude = [[placemarks objectForKey:@"originLongitude"] doubleValue];
    double destinationLatitude = [[placemarks objectForKey:@"destinationLatitude"] doubleValue];
    double destinationLongitude = [[placemarks objectForKey:@"destinationLongitude"] doubleValue];
    
    
    MKPlacemark *placemarkOne = [[MKPlacemark alloc] initWithCoordinate:CLLocationCoordinate2DMake(originLatitude, originLongitude)];
    MKPlacemark *placemarkTwo = [[MKPlacemark alloc] initWithCoordinate:CLLocationCoordinate2DMake(destinationLatitude, destinationLongitude)];

    
    MKMapItem *sourceMapItem = [[MKMapItem alloc] initWithPlacemark:placemarkOne];
    MKMapItem *destinationMapItem = [[MKMapItem alloc] initWithPlacemark:placemarkTwo];
    
    MKDirectionsTransportType transportType;
    if([mode isEqualToString:@"DRIVING"]) {
        transportType = MKDirectionsTransportTypeAutomobile;
    } else if([mode isEqualToString:@"WALKING"]) {
        transportType = MKDirectionsTransportTypeWalking;
    } else if([mode isEqualToString:@"TRANSIT"]) {
        transportType = MKDirectionsTransportTypeTransit;
    } else {
        transportType = MKDirectionsTransportTypeAny;
    }
    // BICYCLING not available in Mapkit
    
    directionRequest = [[MKDirectionsRequest alloc] init];
    [directionRequest setSource:sourceMapItem];
    [directionRequest setDestination:destinationMapItem];
    [directionRequest setTransportType:transportType];
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
                    NSDictionary *currentStep =@{
                        @"instructions": (step.instructions) ? step.instructions : @"",
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
                                         @"coordinates": [RCTConvert NSArray:polylinePoints],
                                         };
                                        
            
            callback(@[successDict]);
        }
    }];
}


@end

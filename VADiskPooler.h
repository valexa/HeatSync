//
//  VADiskPooler.h
//  HeatSync
//
//  Created by Vlad Alexa on 6/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface VADiskPooler : NSObject {
@private
    
}

+(int)smartTemperature:(NSString*)iopath;
+(NSArray*)getDrives;     
+(NSString*)interfaceType:(io_service_t)device;
+(NSString*)getPathAsStringFor:(io_service_t)service;
+(BOOL)isSmartCapable:(io_service_t)device;
+(BOOL)isSleeping:(NSDictionary*)dict;
+(NSDictionary*)getPower:(io_service_t)root interface:(NSString*)interface;
+(NSDictionary*)getDictForProperty:(NSString*)propertyName device:(io_service_t)device;

@end

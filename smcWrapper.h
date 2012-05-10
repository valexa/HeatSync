//
//  smcWrapper.h
//  HeatSync
//
//  Created by Vlad Alexa on 9/3/10.
//  Copyright 2010 NextDesign.
//  Portions from FanControl Copyright (c) 2006 Hendrik Holtmann 
//
//	This program is free software; you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation; either version 2 of the License, or
//	(at your option) any later version.
//
//	This program is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with this program; if not, write to the Free Software
//	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

@interface smcWrapper : NSObject {
}

+(void)openConn;

+(NSDictionary*)getAllKeys;
+(NSDictionary*)getKeyValues;

+(int) get_fan_rpm:(int)fan_number;
+(int) get_fan_num;
+(int) get_min_speed:(int)fan_number;
+(int) get_max_speed:(int)fan_number;
+(void)setFanRpm:(NSString *)key value:(NSString *)value;
+(NSString*) get_fan_descr:(int)fan_number;
+(NSString*)installAndCheckHelper:(NSString*)copyFrom;
+ (void)removeHelper;
+(void)setupHelper;

+(BOOL)volHasOwnershipSuid:(NSString*)path;
+(NSString*)execTask:(NSString*)launch args:(NSArray*)args;
+ (NSString *)machineName;
+ (NSString *)machineModel;
+ (BOOL)isIntel;
+ (BOOL)isDesktop;

@end

@interface NSNumber (NumberAdditions)
- (NSString *) tohex;
- (NSNumber*) celsius_fahrenheit;
@end
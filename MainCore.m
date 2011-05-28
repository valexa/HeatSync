//
//  MainCore.m
//  HeatSync
//
//  Created by Vlad Alexa on 1/16/11.
//  Copyright 2010 NextDesign. 
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

#import "MainCore.h"
#import "smcWrapper.h"

#if PLUGIN //set in project's GCC_PREPROCESSOR_DEFINITIONS
	#define PREF_OBSERVER_NAME_STRING @"MPPluginHeatSyncPreferencesEvent"
#else
	#define PREF_OBSERVER_NAME_STRING @"VAHeatSyncPreferencesEvent"
#endif

#define PLUGIN_NAME_STRING @"HeatSync"

@implementation MainCore

- (id)init{
    self = [super init];
    if(self != nil) {
		
		defaults = [NSUserDefaults standardUserDefaults];	
		fans = [[NSMutableDictionary alloc] init];			
		temps = [[NSMutableDictionary alloc] init];			
	
		[smcWrapper openConn];		
		
		[self findFans];	
		
		[self checkLoop];
		
		[NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(checkLoop) userInfo:nil repeats:YES];			
		
    }
    return self;
}

-(void)dealloc{
	[super dealloc];
	[temps release];
	[fans release];	
}

-(void)saveSetting:(id)object forKey:(NSString*)key{   
    //this is the method for when the host application is not SytemPreferences (MagicPrefsPlugins or your standalone)      
	if (![[object class] isKindOfClass:[NSObject class]]) {
		NSLog(@"The value to be set for %@ is not a object",key); 
		return;
	}     
    NSDictionary *prefs = [NSDictionary dictionaryWithDictionary:[defaults objectForKey:PLUGIN_NAME_STRING]];    
    if ([prefs objectForKey:@"settings"] == nil) {
        NSMutableDictionary *d = [[NSMutableDictionary dictionaryWithDictionary:prefs] autorelease];
        [d setObject:[[[NSDictionary alloc] init] autorelease] forKey:@"settings"];
        prefs = d;
    }
    NSDictionary *db = [self editNestedDict:prefs setObject:object forKeyHierarchy:[NSArray arrayWithObjects:@"settings",key,nil]];
    [defaults setObject:db forKey:PLUGIN_NAME_STRING];        
    [defaults synchronize];
}

-(NSDictionary*)editNestedDict:(NSDictionary*)dict setObject:(id)object forKeyHierarchy:(NSArray*)hierarchy{
    if (dict == nil) return dict;
    if (![dict isKindOfClass:[NSDictionary class]]) return dict;    
    NSMutableDictionary *parent = [[dict mutableCopy] autorelease];
    
    //drill down mutating each dict along the way
    NSMutableArray *structure = [NSMutableArray arrayWithCapacity:1];    
    NSMutableDictionary *prev = parent;
    for (id key in hierarchy) {
        if (key != [hierarchy lastObject]) {
            prev = [[[prev objectForKey:key] mutableCopy] autorelease];                            
            if (![prev isKindOfClass:[NSDictionary class]]) return dict;              
            [structure addObject:prev];
        }
    }   
    
    //do the change
    [[structure lastObject] setObject:object forKey:[hierarchy lastObject]];    
    
    //drill back up saving the changes each step along the way   
    for (int c = [structure count]-1; c >= 0; c--) {
        if (c == 0) {
            [parent setObject:[structure objectAtIndex:c] forKey:[hierarchy objectAtIndex:c]];                                
        }else{
            [[structure objectAtIndex:c-1] setObject:[structure objectAtIndex:c] forKey:[hierarchy objectAtIndex:c]];                                
        }       
    }
    
    return parent;
}

-(void)findFans{
	NSDictionary *plist = [[[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"] objectForKey:@"fans"];
	int num_fans,i;
	num_fans = [smcWrapper get_fan_num];
	NSString *desc;
	NSNumber *min,*max,*lowest;
	for (i = 0; i < num_fans; i++) {
		min = [NSNumber numberWithInt:[smcWrapper get_min_speed:i]];
		max = [NSNumber numberWithInt:[smcWrapper get_max_speed:i]];
		desc = [smcWrapper get_fan_descr:i];
		lowest = [NSNumber numberWithInt:[[[plist objectForKey:desc] objectForKey:@"min"] intValue]];
		if ([min intValue] > [lowest intValue] && [lowest intValue] != 0) min = lowest; //make sure we have the lowest value
		[fans setObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:i],@"id",min,@"min",max,@"max",nil] forKey:desc];
	}			
}

-(void)syncFans{
	NSMutableDictionary *updatedFans = [NSMutableDictionary dictionaryWithCapacity:1];
	for (NSString *key in fans){
		NSMutableDictionary *fan = [[fans objectForKey:key] mutableCopy];
		int theId = [[fan objectForKey:@"id"] intValue];
		NSNumber *curr = [NSNumber numberWithInt:[smcWrapper get_fan_rpm:theId]];
		[fan setObject:curr forKey:@"curr"];
		[updatedFans setObject:fan forKey:key];
		//NSLog(@"Set current fan speed for %@(%i) to %@",key,theId,curr);
		[fan release];			
	}	
	[fans addEntriesFromDictionary:updatedFans];
}

-(void)setFanSpeed:(NSString*)speed forTemp:(NSString*)type{
	
	NSString *fanName = nil;
	NSDictionary *settings = [[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"];		
	if ([type isEqualToString:@"ambient"]) {
		if ([[settings objectForKey:@"togAir"] boolValue] != YES) return;		
		fanName = @"ODD";
	}
	if ([type isEqualToString:@"hdd"]) {
		if ([[settings objectForKey:@"togHdd"] boolValue] != YES) return;		
		fanName = @"HDD";
	}
	if ([type isEqualToString:@"cpu"]) {
		if ([[settings objectForKey:@"togCpu"] boolValue] != YES) return;		
		fanName = @"CPU";
	}	
	
	if (fanName) {
		NSDictionary *fan = [fans objectForKey:fanName]; 		
		int theId = [[fan objectForKey:@"id"] intValue];
		NSNumber *min = [fan objectForKey:@"min"];		
		NSNumber *max = [fan objectForKey:@"max"];
		NSNumber *mid = [NSNumber numberWithInt:(([max intValue]-[min intValue])/2)+[min intValue]];
		NSNumber *high = [NSNumber numberWithInt:[max intValue]-500];		
		if (fan) {
			if ([speed isEqualToString:@"low"]) {				
				//NSLog(@"Setting fan RPM to %@ for %@(%i)",min,fanName,theId);
				[smcWrapper setFanRpm:[NSString stringWithFormat:@"F%dMn",theId] value:[min tohex]];								
			}
			if ([speed isEqualToString:@"mid"]) {
				//NSLog(@"Setting fan RPM to %@ for %@(%i)",mid,fanName,theId);				
				[smcWrapper setFanRpm:[NSString stringWithFormat:@"F%dMn",theId] value:[mid tohex]];
			}
			if ([speed isEqualToString:@"high"]) {
				//NSLog(@"Setting fan RPM to %@ for %@(%i)",high,fanName,theId);				
				[smcWrapper setFanRpm:[NSString stringWithFormat:@"F%dMn",theId] value:[high tohex]];
			}
			if ([speed isEqualToString:@"max"]) {
				//NSLog(@"Setting fan RPM to %@ for %@(%i)",max,fanName,theId);				
				[smcWrapper setFanRpm:[NSString stringWithFormat:@"F%dMn",theId] value:[max tohex]];
			}			
		}else {
			NSLog(@"No fan found for %@",fanName);			
		}
	}else {
		NSLog(@"No fan for %@",type);
	}
}

-(void)syncTemp{
	
	//refference values
	NSDictionary *refValues = [NSDictionary dictionaryWithObjectsAndKeys:
							   [NSDictionary dictionaryWithObjectsAndKeys:@"20",@"low",@"25",@"mid",@"30",@"high",@"35",@"max",nil],@"ambient",
							   [NSDictionary dictionaryWithObjectsAndKeys:@"45",@"low",@"50",@"mid",@"55",@"high",@"60",@"max",nil],@"hdd",
							   [NSDictionary dictionaryWithObjectsAndKeys:@"40",@"low",@"50",@"mid",@"60",@"high",@"90",@"max",nil],@"cpu",								
							   nil];	
	
	//actual values
	NSDictionary *allKeys = [smcWrapper allocAllKeys];
	NSDictionary *foundKeys = [smcWrapper allocFoundKeys:allKeys];
	
	//extract avg and max
	NSDictionary *avgDict = [self getAverages:foundKeys];
	NSDictionary *maxDict = [self getMaximum:foundKeys];
	
	for (NSString *key in refValues){
		NSDictionary *refDict = [refValues objectForKey:key];
		int max = [[maxDict objectForKey:key] intValue];
		int avg = [[avgDict objectForKey:key] intValue];		
		if (max != avg) {
			NSLog(@"%@ max %i avg %i",key,max,avg);
		}
		if (max >= [[refDict objectForKey:@"max"] intValue]-1 ) {
			//NSLog(@"%@ temp is max",key);
			[self setFanSpeed:@"max" forTemp:key];
			continue;
		}
		if (max >= [[refDict objectForKey:@"high"] intValue] ) {
			//NSLog(@"%@ temp is high",key);
			[self setFanSpeed:@"high" forTemp:key];			
			continue;
		}
		if (max >= [[refDict objectForKey:@"mid"] intValue] ) {
			//NSLog(@"%@ temp is mid",key);
			[self setFanSpeed:@"mid" forTemp:key];			
			continue;
		}	
		//NSLog(@"%@ temp is low",key);
		[self setFanSpeed:@"low" forTemp:key];		
	}	
	
	//get all temps
	NSMutableDictionary *allTemps = [NSMutableDictionary dictionaryWithCapacity:1];
	for (NSString *key in allKeys){
		NSNumber *val = [foundKeys objectForKey:key];
		if (val){
			//NSLog(@"%@ for %@ (%@)",val,key,[allKeys objectForKey:key]);
			[allTemps setObject:val forKey:[allKeys objectForKey:key]];
		}
	}
	
	//add current temps
	[temps removeAllObjects];	
	for (NSString *key in maxDict){
		NSMutableDictionary *tmp = [[refValues objectForKey:key] mutableCopy];
		[tmp setObject:[maxDict objectForKey:key] forKey:@"curr"];
		[temps setObject:tmp forKey:key];		
		[tmp release];
	}
	
	[self saveSetting:allTemps forKey:@"allTemps"];
	[self saveSetting:fans forKey:@"fans"];	
	[self saveSetting:temps forKey:@"temps"];	
	
	[allKeys release];
	[foundKeys release];	
	
}

-(void)checkLoop{
	[defaults synchronize];
	[self syncFans];	
	[self syncTemp];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:PREF_OBSERVER_NAME_STRING object:@"syncUI" userInfo:nil];	
}

-(NSDictionary*)getAverages:(NSDictionary*)foundKeys{
	NSMutableDictionary *ret = [NSMutableDictionary dictionaryWithCapacity:3];
	NSMutableArray *hdds = [NSMutableArray arrayWithCapacity:1];
	NSMutableArray *cpus = [NSMutableArray arrayWithCapacity:1];	
	
	for (NSString *key in foundKeys){		
		if ([key isEqualToString:@"TA0P"]){
			[ret setObject:[foundKeys objectForKey:key] forKey:@"ambient"];		
		}				
		if ([key isEqualToString:@"TH0P"] || [key isEqualToString:@"TH1P"] || [key isEqualToString:@"TH2P"] || [key isEqualToString:@"TH3P"]){
			[hdds addObject:[foundKeys objectForKey:key]];			
		}				
		if ([key isEqualToString:@"TC0D"] || [key isEqualToString:@"TC0H"] || [key isEqualToString:@"TCAH"] || [key isEqualToString:@"TC1D"] || [key isEqualToString:@"TC1H"] || [key isEqualToString:@"TCBH"]){
			[cpus addObject:[foundKeys objectForKey:key]];			
		}
	}	
	
	int total;
	
	if ([hdds count] > 0) {
		total = 0;
		for (NSNumber *val in hdds){
			total += [val intValue]; 
		}
		[ret setObject:[NSNumber numberWithInt:total/[hdds count]] forKey:@"hdd"];			
	}else {
		NSLog(@"No HDD's found");
	}
	
	if ([cpus count] > 0) {
		total = 0;
		for (NSNumber *val in cpus){
			total += [val intValue]; 
		}
		[ret setObject:[NSNumber numberWithInt:total/[cpus count]] forKey:@"cpu"];				
	}else {
		NSLog(@"No CPU's found");
	}
	
	return ret;
}

-(NSDictionary*)getMaximum:(NSDictionary*)foundKeys{
	NSMutableDictionary *ret = [NSMutableDictionary dictionaryWithCapacity:3];
	NSMutableArray *hdds = [NSMutableArray arrayWithCapacity:1];
	NSMutableArray *cpus = [NSMutableArray arrayWithCapacity:1];	
	
	for (NSString *key in foundKeys){		
		if ([key isEqualToString:@"TA0P"]){
			[ret setObject:[foundKeys objectForKey:key] forKey:@"ambient"];		
		}				
		if ([key isEqualToString:@"TH0P"] || [key isEqualToString:@"TH1P"] || [key isEqualToString:@"TH2P"] || [key isEqualToString:@"TH3P"]){
			[hdds addObject:[foundKeys objectForKey:key]];			
		}				
		if ([key isEqualToString:@"TC0D"] || [key isEqualToString:@"TC0H"] || [key isEqualToString:@"TCAH"] || [key isEqualToString:@"TC1D"] || [key isEqualToString:@"TC1H"] || [key isEqualToString:@"TCBH"]){
			[cpus addObject:[foundKeys objectForKey:key]];			
		}
	}	
	
	int max;
	
	max = 0;
	for (NSNumber *val in hdds){
		if ([val intValue] > max) max = [val intValue]; 
	}
	[ret setObject:[NSNumber numberWithInt:max] forKey:@"hdd"];	
	
	max = 0;
	for (NSNumber *val in cpus){
		if ([val intValue] > max) max = [val intValue];
	}
	[ret setObject:[NSNumber numberWithInt:max] forKey:@"cpu"];		
	
	return ret;
}


@end

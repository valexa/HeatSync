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
#import "VADiskPooler.h"

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
	[temps release];
	[fans release];	
	[super dealloc];    
}

-(void)saveSetting:(id)object forKey:(NSString*)key{ 
    //this is the method for when the host application is not SytemPreferences (MagicPrefsPlugins or your standalone)      
	if (![[object class] isKindOfClass:[NSObject class]]) {
		NSLog(@"The value to be set for %@ is not a object",key); 
		return;
	}     
    NSDictionary *prefs = [NSDictionary dictionaryWithDictionary:[defaults objectForKey:PLUGIN_NAME_STRING]];    
    if ([prefs objectForKey:@"settings"] == nil) {
        NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary:prefs];
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

-(void)setFanSpeed:(NSString*)speed ifEnabledFor:(NSString*)type{

	NSDictionary *settings = [[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"];		
	if ([type isEqualToString:@"ambient"]) {
		if ([[settings objectForKey:@"togAir"] boolValue] == YES){
            [self setFanSpeed:speed withName:@"ODD"];
        }
	}else if ([type isEqualToString:@"hdd"]) {
		if ([[settings objectForKey:@"togHdd"] boolValue] == YES){
            [self setFanSpeed:speed withName:@"HDD"];        
        }
	} else if ([type isEqualToString:@"cpu"]) {
		if ([[settings objectForKey:@"togCpu"] boolValue] == YES){
            [self setFanSpeed:speed withName:@"CPU"];        
        }
	}else if ([type isEqualToString:@"Macbook"]) {
		if ([[settings objectForKey:@"togMacbookPro"] boolValue] == YES){
            [self setFanSpeed:speed withName:@"Leftside"];           
            [self setFanSpeed:speed withName:@"Rightside"];        
        }
		if ([[settings objectForKey:@"togMacbookAir"] boolValue] == YES){
            [self setFanSpeed:speed withName:@"Exhaust"];                  
        }        
	}else{
        NSLog(@"No fan for %@",type);        
    }	    
}

-(void)setFanSpeed:(NSString*)speed withName:(NSString*)name{
    NSDictionary *fan = [fans objectForKey:name]; 		
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
        NSLog(@"No fan found for %@",name);			
    }    
}

-(void)syncTemp{
    
    //reference values
	NSDictionary *refValues = [self refValuesForMachine];
    	
	//actual values
	NSDictionary *smcKeys = [smcWrapper getKeyValues];    
    NSMutableDictionary *foundKeys = [NSMutableDictionary dictionaryWithDictionary:smcKeys];    
    
    //add smart temps
    int index = 0;
    if (CFAbsoluteTimeGetCurrent() - lastSMARTCheck > 660) {
        for (NSString *drive in [VADiskPooler getDrives]) {
            index += 1;
            int temp = [VADiskPooler smartTemperature:drive];
            [foundKeys setObject:[NSNumber numberWithInt:temp] forKey:[NSString stringWithFormat:@"SMART%i",index]];
            //NSLog(@"SMART temp is %@ for drive %i (%@)",temp,index,drive);                   
        }
        lastSMARTCheck = CFAbsoluteTimeGetCurrent();
    }    
	
	//extract avg and max
    NSDictionary *ah = [self getAvgAndHigh:foundKeys];
	NSDictionary *avgDict = [ah objectForKey:@"a"];
	NSDictionary *highestDict = [ah objectForKey:@"h"];
	
    if ([smcWrapper isDesktop] == YES) { 
        for (NSString *key in refValues){
            NSDictionary *refDict = [refValues objectForKey:key];
            int highest = [[highestDict objectForKey:key] intValue];
            int avg = [[avgDict objectForKey:key] intValue];
            int compare = 0;
            if (highest != avg) {
                //NSLog(@"Multiple sensors for %@ (highest %i avg %i)",key,highest,avg);
                compare = avg;                
            }else{
                compare = highest;
            }
            if (compare >= [[refDict objectForKey:@"max"] intValue]-1 ) {
                //NSLog(@"%@ temp is max %i",key,compare);
                [self setFanSpeed:@"max" ifEnabledFor:key];
            }else if (compare >= [[refDict objectForKey:@"high"] intValue] ) {
                //NSLog(@"%@ temp is high %i",key,compare);
                [self setFanSpeed:@"high" ifEnabledFor:key];			
            }else if (compare >= [[refDict objectForKey:@"mid"] intValue] ) {
                //NSLog(@"%@ temp is mid %i",key,compare);
                [self setFanSpeed:@"mid" ifEnabledFor:key];			
            }else{
                //NSLog(@"%@ temp is low %i",key,compare);
                [self setFanSpeed:@"low" ifEnabledFor:key];		                
            }	
        }        
    }else{
        int maxTotals = 0;
        int highTotals = 0;
        int midTotals = 0;
        int total = 0;
        for (NSString *key in refValues){
            NSDictionary *refDict = [refValues objectForKey:key];
            maxTotals += [[refDict objectForKey:@"max"] intValue];
            highTotals += [[refDict objectForKey:@"high"] intValue];
            midTotals += [[refDict objectForKey:@"mid"] intValue]; 
            int highest = [[highestDict objectForKey:key] intValue];
            int avg = [[avgDict objectForKey:key] intValue];		
            if (highest != avg) {
                //NSLog(@"Multiple sensors for %@ (highest %i avg %i)",key,highest,avg);
                total += avg;                
            }else{
                total += highest;                
            }
        }
        if (total >= maxTotals) {
            //NSLog(@"Macbook temp is max %i/%i",total,maxTotals);            
            [self setFanSpeed:@"max" ifEnabledFor:@"Macbook"];            
        }else if (total >= highTotals) {
            //NSLog(@"Macbook temp is high %i/%i",total,highTotals);             
            [self setFanSpeed:@"high" ifEnabledFor:@"Macbook"];            
        }else if (total >= midTotals) {
            //NSLog(@"Macbook temp is mid %i/%i",total,midTotals);             
            [self setFanSpeed:@"mid" ifEnabledFor:@"Macbook"];
        }else{
            //NSLog(@"Macbook temp is low %i/%i",total,midTotals);             
            [self setFanSpeed:@"low" ifEnabledFor:@"Macbook"];        
        }        
    }    
	
	//make list of temps associated with their descriptions
	NSMutableDictionary *allTemps = [NSMutableDictionary dictionaryWithCapacity:1];
    NSDictionary *allKeys = [smcWrapper getAllKeys];
	for (NSString *key in allKeys){
		NSNumber *val = [foundKeys objectForKey:key];
		if (val){
			//NSLog(@"%@ for %@ (%@)",val,key,[allKeys objectForKey:key]);
			[allTemps setObject:val forKey:[allKeys objectForKey:key]];
		}
	}   
	
	//add current temperature averages
	[temps removeAllObjects];	
	for (NSString *key in refValues){
        NSNumber *average = [avgDict objectForKey:key];
        NSNumber *highest = [avgDict objectForKey:key];
        if (average && highest) {
            NSMutableDictionary *tmp = [[refValues objectForKey:key] mutableCopy];            
            if ([highest intValue]-[average intValue] < 10) {
                [tmp setObject:average forKey:@"curr"];            
            }else{
                [tmp setObject:highest forKey:@"curr"];            
            }
            [temps setObject:tmp forKey:key];		
            [tmp release];            
        }else{
            NSLog(@"Got nil for %@ (avg:%@ high:%@)",key,average,highest);
        }
	}
	
	[self saveSetting:allTemps forKey:@"allTemps"];
	[self saveSetting:fans forKey:@"fans"];	
	[self saveSetting:temps forKey:@"temps"];		
	
}

-(void)checkLoop{
	[defaults synchronize];
	[self syncFans];	
	[self syncTemp];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:PREF_OBSERVER_NAME_STRING object:@"syncUI" userInfo:nil];	
}

-(NSDictionary*)getAvgAndHigh:(NSDictionary*)foundKeys{
    
	NSMutableArray *ambients = [NSMutableArray arrayWithCapacity:1];    
	NSMutableArray *hdds = [NSMutableArray arrayWithCapacity:1];
	NSMutableArray *cpus = [NSMutableArray arrayWithCapacity:1];	
	
	for (NSString *key in foundKeys){		
        if ([smcWrapper isDesktop] != YES) {   
            if ([key isEqualToString:@"TB0T"]){ //use bottom temp for macbook pro
                [ambients addObject:[foundKeys objectForKey:key]];		
            }
            if ([key isEqualToString:@"Th1H"]){ //use heatsync B temp for macbook air
                [ambients addObject:[foundKeys objectForKey:key]];
            }
            if ([key isEqualToString:@"Tm0P"]){ //use memory temp for macbook pros
                [hdds addObject:[foundKeys objectForKey:key]];			
            } 
            if ([key isEqualToString:@"TM0P"]){ //use memory temp for macbook airs
                [hdds addObject:[foundKeys objectForKey:key]];			
            }             
        }         
		if ([key isEqualToString:@"TA0P"] || [key isEqualToString:@"TA1P"]){
			[ambients addObject:[foundKeys objectForKey:key]];			
		}				
		if ([key isEqualToString:@"TH0P"] || [key isEqualToString:@"TH1P"] || [key isEqualToString:@"TH2P"] || [key isEqualToString:@"TH3P"]){
			[hdds addObject:[foundKeys objectForKey:key]];			
		}
		if ([key isEqualToString:@"SMART1"] || [key isEqualToString:@"SMART2"] || [key isEqualToString:@"SMART3"] || [key isEqualToString:@"SMART4"]){
			[hdds addObject:[foundKeys objectForKey:key]];			
		}        
		if ([key isEqualToString:@"TC0D"] || [key isEqualToString:@"TC0H"] || [key isEqualToString:@"TCAH"] || [key isEqualToString:@"TC1D"] || [key isEqualToString:@"TC1H"] || [key isEqualToString:@"TCBH"]){
			[cpus addObject:[foundKeys objectForKey:key]];			
		}
	}	

	//get averages
	NSMutableDictionary *average = [NSMutableDictionary dictionaryWithCapacity:3];    
	int total;
    
	if ([ambients count] > 0) {
		total = 0;
		for (NSNumber *val in ambients){
			total += [val intValue]; 
		}
        int ambient = total/[ambients count];
        if (ambient > 32) ambient = ambient - 6; //assume air gets heated 6 extra degrees while flowing trough casing if over 32
		[average setObject:[NSNumber numberWithInt:ambient] forKey:@"ambient"];			
	}else {
		NSLog(@"No Ambient sensors found");
	}    
	
	if ([hdds count] > 0) {
		total = 0;
		for (NSNumber *val in hdds){
			total += [val intValue]; 
		}
		[average setObject:[NSNumber numberWithInt:total/[hdds count]] forKey:@"hdd"];			
	}else {
		NSLog(@"No HDD sensors found");
	}
	
	if ([cpus count] > 0) {
		total = 0;
		for (NSNumber *val in cpus){
			total += [val intValue]; 
		}
		[average setObject:[NSNumber numberWithInt:total/[cpus count]] forKey:@"cpu"];				
	}else {
		NSLog(@"No CPU sensors found");
	}
	
    //get highest
	NSMutableDictionary *highest = [NSMutableDictionary dictionaryWithCapacity:3];	
	int high;    
    
	high = 0;
	for (NSNumber *val in ambients){
		if ([val intValue] > high) high = [val intValue]; 
	}
	[highest setObject:[NSNumber numberWithInt:high] forKey:@"ambient"];	    
	
	high = 0;
	for (NSNumber *val in hdds){
		if ([val intValue] > high) high = [val intValue]; 
	}
	[highest setObject:[NSNumber numberWithInt:high] forKey:@"hdd"];	
	
	high = 0;
	for (NSNumber *val in cpus){
		if ([val intValue] > high) high = [val intValue];
	}
	[highest setObject:[NSNumber numberWithInt:high] forKey:@"cpu"];	
	
    
    return [NSDictionary dictionaryWithObjectsAndKeys:average,@"a",highest,@"h", nil];

}


-(NSDictionary*)refValuesForMachine{    
    
    if ([smcWrapper isDesktop] == YES) {
		[self saveSetting:[NSNumber numberWithBool:NO] forKey:@"togMacbookPro"];        
		[self saveSetting:[NSNumber numberWithBool:NO] forKey:@"togMacbookAir"];       
        //determined on imac but might do for mac mini and mac pro too
        return [NSDictionary dictionaryWithObjectsAndKeys:
                [NSDictionary dictionaryWithObjectsAndKeys:@"25",@"low",@"30",@"mid",@"35",@"high",@"40",@"max",nil],@"ambient",
                [NSDictionary dictionaryWithObjectsAndKeys:@"45",@"low",@"50",@"mid",@"55",@"high",@"60",@"max",nil],@"hdd",
                [NSDictionary dictionaryWithObjectsAndKeys:@"40",@"low",@"50",@"mid",@"60",@"high",@"90",@"max",nil],@"cpu",								
                nil];
    }else{
		[self saveSetting:[NSNumber numberWithBool:NO] forKey:@"togAir"];        
		[self saveSetting:[NSNumber numberWithBool:NO] forKey:@"togHdd"];
		[self saveSetting:[NSNumber numberWithBool:NO] forKey:@"togCpu"];        
        //determined for macbook by guessing mostly
        return [NSDictionary dictionaryWithObjectsAndKeys:
                [NSDictionary dictionaryWithObjectsAndKeys:@"25",@"low",@"30",@"mid",@"35",@"high",@"40",@"max",nil],@"ambient",
                [NSDictionary dictionaryWithObjectsAndKeys:@"40",@"low",@"50",@"mid",@"55",@"high",@"60",@"max",nil],@"hdd",
                [NSDictionary dictionaryWithObjectsAndKeys:@"50",@"low",@"65",@"mid",@"80",@"high",@"90",@"max",nil],@"cpu",								
                nil];            
    }
	
}

@end

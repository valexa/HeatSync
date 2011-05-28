//
//  HeatSyncPreferences.m
//  HeatSync
//
//  Created by Vlad Alexa on 9/13/10.
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


#import "HeatSyncPreferences.h"
#import "smcWrapper.h"

#if PLUGIN //set in project's GCC_PREPROCESSOR_DEFINITIONS
	#define OBSERVER_NAME_STRING @"MPPluginHeatSyncPreferencesEvent"
	#define PREFS_PLIST_DOMAIN @"com.vladalexa.MagicPrefs.MagicPrefsPlugins"
#else
	#define OBSERVER_NAME_STRING @"VAHeatSyncPreferencesEvent"
	#define PREFS_PLIST_DOMAIN @"com.vladalexa.heatsync"
#endif

#define PLUGIN_NAME_STRING @"HeatSync"

@implementation HeatSyncPreferences

- (void)loadView {
    [super loadView];
	
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:OBSERVER_NAME_STRING object:nil];	
	[self syncUI];
	
}


-(void)theEvent:(NSNotification*)notif{	
	if (![[notif name] isEqualToString:OBSERVER_NAME_STRING]) {		
		return;
	}	
	if ([[notif userInfo] isKindOfClass:[NSDictionary class]]){
	}	
	if ([[notif object] isKindOfClass:[NSString class]]){
		if ([[notif object] isEqualToString:@"syncUI"]) {
			[self syncUI];
		}
	}
}

-(void)saveSetting:(id)object forKey:(NSString*)key{
    //this is the method for when the host application is not MagicPrefsPlugins (SytemPreferences or your standalone)    
	if (![[object class] isKindOfClass:[NSObject class]]) {
		NSLog(@"The value to be set for %@ is not a object",key);
		return;
	}    
	NSDictionary *defaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:PREFS_PLIST_DOMAIN];	
	NSMutableDictionary *settings = [[[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"] mutableCopy];
	if (settings == nil) settings = [[NSMutableDictionary alloc] initWithCapacity:1];	
	[settings setObject:object forKey:key];	
	NSMutableDictionary *dict = [[defaults objectForKey:PLUGIN_NAME_STRING] mutableCopy];	
	[dict setObject:settings forKey:@"settings"];	
	
	CFStringRef appID = (CFStringRef)PREFS_PLIST_DOMAIN;
	CFPreferencesSetValue((CFStringRef)PLUGIN_NAME_STRING,dict,appID,kCFPreferencesCurrentUser,kCFPreferencesAnyHost);
	CFPreferencesSynchronize(appID,kCFPreferencesCurrentUser,kCFPreferencesAnyHost);
    
	[settings release];		
	[dict release];
}

-(void)setMinRpm:(NSString*)type{
	NSString *fanName = nil;
	if ([type isEqualToString:@"ambient"]) {	
		fanName = @"ODD";
	}
	if ([type isEqualToString:@"hdd"]) {	
		fanName = @"HDD";
	}
	if ([type isEqualToString:@"cpu"]) {	
		fanName = @"CPU";
	}	
	
	NSDictionary *defaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:PREFS_PLIST_DOMAIN];	
	NSDictionary *fans = [[[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"] objectForKey:@"fans"];	
	NSNumber *min = [[fans objectForKey:fanName] objectForKey:@"min"];
	int theId = [[[fans objectForKey:fanName] objectForKey:@"id"] intValue];
	NSLog(@"Setting fan RPM to %@ for %@(%i)",min,fanName,theId);	
	[smcWrapper setFanRpm:[NSString stringWithFormat:@"F%dMn",theId] value:[min tohex]];		
}

-(IBAction)togAir:(id)sender{		
	if ([sender state] == 1){
		[airConnector setHidden:NO];		
		[self saveSetting:[NSNumber numberWithBool:YES] forKey:@"togAir"];
	}else {
		[airConnector setHidden:YES];		
		[self saveSetting:[NSNumber numberWithBool:NO] forKey:@"togAir"];
		[self setMinRpm:@"ambient"];
	}		
}

-(IBAction)togHdd:(id)sender{	
	if ([sender state] == 1){
		[hddConnector setHidden:NO];		
		[self saveSetting:[NSNumber numberWithBool:YES] forKey:@"togHdd"];
	}else {
		[hddConnector setHidden:YES];
		[self saveSetting:[NSNumber numberWithBool:NO] forKey:@"togHdd"];
		[self setMinRpm:@"hdd"];		
	}	
}

-(IBAction)togCpu:(id)sender{		
	if ([sender state] == 1){
		[cpuConnector setHidden:NO];		
		[self saveSetting:[NSNumber numberWithBool:YES] forKey:@"togCpu"];
	}else {
		[cpuConnector setHidden:YES];		
		[self saveSetting:[NSNumber numberWithBool:NO] forKey:@"togCpu"];
		[self setMinRpm:@"cpu"];		
	}		
}

-(void)syncUI{

	NSString *smcpath = [NSString stringWithFormat:@"%@/Library/Application Support/HeatSync/smc",NSHomeDirectory()];	    
	NSDictionary *fdict = [[NSFileManager defaultManager] attributesOfItemAtPath:smcpath error:nil];
	if ([[fdict valueForKey:@"NSFileOwnerAccountName"] isEqualToString:@"root"] && [[fdict valueForKey:@"NSFileGroupOwnerAccountName"] isEqualToString:@"admin"] && ([[fdict valueForKey:@"NSFilePosixPermissions"] intValue]==3437)) {
		[airButton setEnabled:YES];
		[cpuButton setEnabled:YES];
		[hddButton setEnabled:YES];	
	} else {
		[airButton setEnabled:NO];
		[cpuButton setEnabled:NO];
		[hddButton setEnabled:NO];
	}    
		
	NSDictionary *defaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:PREFS_PLIST_DOMAIN];	
	NSDictionary *settings = [[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"];	
	NSDictionary *temps = [settings objectForKey:@"temps"];
	NSDictionary *fans = [settings objectForKey:@"fans"];
	NSDictionary *allTemps = [settings objectForKey:@"allTemps"];	
		
	if ([[settings objectForKey:@"togAir"] boolValue] == YES) {
		[airButton setState:1];
		[airConnector setHidden:NO];
	}else {
		[airButton setState:0];		
		[airConnector setHidden:YES];		
	}
	
	if ([[settings objectForKey:@"togHdd"] boolValue] == YES) {
		[hddButton setState:1];
		[hddConnector setHidden:NO];		
	}else {
		[hddButton setState:0];
		[hddConnector setHidden:YES];		
	}
	
	if ([[settings objectForKey:@"togCpu"] boolValue] == YES) {
		[cpuButton setState:1];
		[cpuConnector setHidden:NO];		
	}else {
		[cpuButton setState:0];
		[cpuConnector setHidden:YES];		
	}	
	
	[thermometer setToolTip:[allTemps description]];	
	[fan setToolTip:[fans description]];	
	
	[airTempText setStringValue:[self noNilStr:[[temps objectForKey:@"ambient"] objectForKey:@"curr"]]];
	[hddTempText setStringValue:[self noNilStr:[[temps objectForKey:@"hdd"] objectForKey:@"curr"]]];
	[cpuTempText setStringValue:[self noNilStr:[[temps objectForKey:@"cpu"] objectForKey:@"curr"]]];
	
	[self changeDegrees:nil];	
	
	[airFanText setStringValue:[self noNilStr:[[fans objectForKey:@"ODD"] objectForKey:@"curr"]]];
	[hddFanText setStringValue:[self noNilStr:[[fans objectForKey:@"HDD"] objectForKey:@"curr"]]];
	[cpuFanText setStringValue:[self noNilStr:[[fans objectForKey:@"CPU"] objectForKey:@"curr"]]];	
	
	for (NSString *key in temps){
		NSLevelIndicator *indicator = nil;
		if ([key isEqualToString:@"ambient"]){
			indicator = airTempLevel;
		}	
		if ([key isEqualToString:@"hdd"]){
			indicator = hddTempLevel;
		}	
		if ([key isEqualToString:@"cpu"]){
			indicator = cpuTempLevel;
		}	
		if (indicator) {
			NSDictionary *dict = [temps objectForKey:key];
			int curr = [[dict objectForKey:@"curr"] intValue];
			if (curr >= [[dict objectForKey:@"max"] intValue]-1 ) {
				NSLog(@"%@ temp is max",key);
				[indicator setIntValue:3];
				//TODO also do notice
				continue;
			}
			if (curr >= [[dict objectForKey:@"high"] intValue] ) {
				//NSLog(@"%@ temp is high",key);
				[indicator setIntValue:3];		
				continue;
			}
			if (curr >= [[dict objectForKey:@"mid"] intValue] ) {
				//NSLog(@"%@ temp is mid",key);
				[indicator setIntValue:2];			
				continue;
			}	
			//NSLog(@"%@ temp is low",key);
			[indicator setIntValue:1];			
		}else {
			NSLog(@"Unbound temp type (%@)",key);
		}		
	}	
	
	for (NSString *key in fans){
		NSLevelIndicator *indicator = nil;
		if ([key isEqualToString:@"ODD"]) {
			indicator = airFanLevel;
		}
		if ([key isEqualToString:@"HDD"]) {
			indicator = hddFanLevel;
		}
		if ([key isEqualToString:@"CPU"]) {
			indicator = cpuFanLevel;
		}	
		if (indicator) {
			NSDictionary *dict = [fans objectForKey:key];
			double curr = [[dict objectForKey:@"curr"] doubleValue];
			double max = [[dict objectForKey:@"max"] doubleValue];
			double min = [[dict objectForKey:@"min"] doubleValue];
			double diff = (max-min)/2;
			[indicator setMaxValue:max];
			[indicator setMinValue:min-diff];		
			[indicator setDoubleValue:curr];		
			if (curr >= max) {
				//TODO also do notice
			}			
		}else {
			NSLog(@"Unbound fan type (%@)",key);
		}		
	}		
	
}

-(IBAction)changeDegrees:(id)sender{
	NSDictionary *defaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:PREFS_PLIST_DOMAIN];	
	NSDictionary *settings = [[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"];
	NSDictionary *temps = [settings objectForKey:@"temps"];	
	int air = [[[temps objectForKey:@"ambient"] objectForKey:@"curr"] intValue];
	int hdd = [[[temps objectForKey:@"hdd"] objectForKey:@"curr"] intValue];
	int cpu = [[[temps objectForKey:@"cpu"] objectForKey:@"curr"] intValue];		
	BOOL celsius = [[settings objectForKey:@"useCelsius"] boolValue];
	
	if (sender != nil) 	{
		if (celsius == NO) {
			[self saveSetting:[NSNumber numberWithBool:YES] forKey:@"useCelsius"];
			celsius = YES;
		}else {
			[self saveSetting:[NSNumber numberWithBool:NO] forKey:@"useCelsius"];			
			celsius = NO;			
		}		
	}			
	
	if (celsius == NO) {
		[airTempText setStringValue:[NSString stringWithFormat:@"%i",(int)(air*1.8)+32]];
		[hddTempText setStringValue:[NSString stringWithFormat:@"%i",(int)(hdd*1.8)+32]];
		[cpuTempText setStringValue:[NSString stringWithFormat:@"%i",(int)(cpu*1.8)+32]];
		[airDegree setStringValue:@"°F"];
		[hddDegree setStringValue:@"°F"];
		[cpuDegree setStringValue:@"°F"];	
	}else {		
		[airTempText setStringValue:[NSString stringWithFormat:@"%i",air]];
		[hddTempText setStringValue:[NSString stringWithFormat:@"%i",hdd]];
		[cpuTempText setStringValue:[NSString stringWithFormat:@"%i",cpu]];		
		[airDegree setStringValue:@"°C"];
		[hddDegree setStringValue:@"°C"];
		[cpuDegree setStringValue:@"°C"];		
	}
}

-(NSString*)noNilStr:(NSString*)str{
	if (str == nil) {
		return @"";
	}else {
		return str;
	}
}

@end

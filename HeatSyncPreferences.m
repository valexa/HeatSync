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

-(void)setMinRpm:(NSString*)fanName{  
	
	NSDictionary *defaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:PREFS_PLIST_DOMAIN];	
	NSDictionary *fans = [[[defaults objectForKey:PLUGIN_NAME_STRING] objectForKey:@"settings"] objectForKey:@"fans"];	
    NSDictionary *fan = [fans objectForKey:fanName];
    if (fan){
        NSNumber *min = [fan objectForKey:@"min"];
        int theId = [[fan objectForKey:@"id"] intValue];
        NSLog(@"Setting fan RPM to %@ for %@(%i)",min,fanName,theId);	
        [smcWrapper setFanRpm:[NSString stringWithFormat:@"F%dMn",theId] value:[min tohex]];        
    }else{
        NSLog(@"Unable to set min for fan %@",fanName);
    }		
}

-(IBAction)togAir:(id)sender{		
	if ([sender state] == 1){
		[airConnector setHidden:NO];		
		[self saveSetting:[NSNumber numberWithBool:YES] forKey:@"togAir"];
	}else {
		[airConnector setHidden:YES];		
		[self saveSetting:[NSNumber numberWithBool:NO] forKey:@"togAir"];
		[self setMinRpm:@"ODD"];
	}		
}

-(IBAction)togHdd:(id)sender{	
	if ([sender state] == 1){
		[hddConnector setHidden:NO];		
		[self saveSetting:[NSNumber numberWithBool:YES] forKey:@"togHdd"];
	}else {
		[hddConnector setHidden:YES];
		[self saveSetting:[NSNumber numberWithBool:NO] forKey:@"togHdd"];
		[self setMinRpm:@"HDD"];		
	}	
}

-(IBAction)togCpu:(id)sender{		
	if ([sender state] == 1){
		[cpuConnector setHidden:NO];		
		[self saveSetting:[NSNumber numberWithBool:YES] forKey:@"togCpu"];
	}else {
		[cpuConnector setHidden:YES];		
		[self saveSetting:[NSNumber numberWithBool:NO] forKey:@"togCpu"];
		[self setMinRpm:@"CPU"];		
	}		
}

-(IBAction)togMacbok:(id)sender{		
	if ([sender state] == 1){
		[macbookProConnector setHidden:NO];		
		[self saveSetting:[NSNumber numberWithBool:YES] forKey:@"togMacbookPro"];
	}else {
		[macbookProConnector setHidden:YES];		
		[self saveSetting:[NSNumber numberWithBool:NO] forKey:@"togMacbookPro"];
		[self setMinRpm:@"Leftside"];
		[self setMinRpm:@"Rightside"];        
	}		
}

-(IBAction)togMacbokAir:(id)sender{
	if ([sender state] == 1){
		[macbookAirConnector setHidden:NO];		
		[self saveSetting:[NSNumber numberWithBool:YES] forKey:@"togMacbookAir"];
	}else {
		[macbookAirConnector setHidden:YES];		
		[self saveSetting:[NSNumber numberWithBool:NO] forKey:@"togMacbookAir"];
		[self setMinRpm:@"Exhaust"];       
	}    
}

-(void)syncUI{
    
    [regularFansView setFrame:NSMakeRect(19, 0, 243, 170)];    
    [macbookProFansView setFrame:NSMakeRect(19, 0, 243, 170)];    
    [macbookAirFansView setFrame:NSMakeRect(19, 0, 243, 170)];        
    [regularFansView removeFromSuperview];
    [macbookProFansView removeFromSuperview]; 
    [macbookAirFansView removeFromSuperview];     

	NSString *smcpath = [NSString stringWithFormat:@"%@/Library/Application Support/HeatSync/smc",NSHomeDirectory()];	    
	NSDictionary *fdict = [[NSFileManager defaultManager] attributesOfItemAtPath:smcpath error:nil];
	if ([[fdict valueForKey:@"NSFileOwnerAccountName"] isEqualToString:@"root"] && [[fdict valueForKey:@"NSFileGroupOwnerAccountName"] isEqualToString:@"admin"] && ([[fdict valueForKey:@"NSFilePosixPermissions"] intValue]==3437)) {
		[airButton setEnabled:YES];
		[cpuButton setEnabled:YES];
		[hddButton setEnabled:YES];	
		[macbookProButton setEnabled:YES];	        
	} else {
		[airButton setEnabled:NO];
		[cpuButton setEnabled:NO];
		[hddButton setEnabled:NO];
		[macbookProButton setEnabled:NO];        
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
    
	if ([[settings objectForKey:@"togMacbookPro"] boolValue] == YES) {
		[macbookProButton setState:1];
		[macbookProConnector setHidden:NO];		
	}else {
		[macbookProButton setState:0];
		[macbookProConnector setHidden:YES];		
	}    
    
	if ([[settings objectForKey:@"togMacbookAir"] boolValue] == YES) {
		[macbookAirButton setState:1];
		[macbookAirConnector setHidden:NO];		
	}else {
		[macbookAirButton setState:0];
		[macbookAirConnector setHidden:YES];		
	}      
	
	[thermometerImage setToolTip:[allTemps description]];	
	[fanImage setToolTip:[fans description]];	
	
	[airTempText setStringValue:[self noNilStr:[[temps objectForKey:@"ambient"] objectForKey:@"curr"]]];
	[hddTempText setStringValue:[self noNilStr:[[temps objectForKey:@"hdd"] objectForKey:@"curr"]]];
	[cpuTempText setStringValue:[self noNilStr:[[temps objectForKey:@"cpu"] objectForKey:@"curr"]]];
	
	[self changeDegrees:nil];	
	
	[airFanText setStringValue:[self noNilStr:[[fans objectForKey:@"ODD"] objectForKey:@"curr"]]];
	[hddFanText setStringValue:[self noNilStr:[[fans objectForKey:@"HDD"] objectForKey:@"curr"]]];
	[cpuFanText setStringValue:[self noNilStr:[[fans objectForKey:@"CPU"] objectForKey:@"curr"]]];	

	[mbLeftFanText setStringValue:[self noNilStr:[[fans objectForKey:@"Leftside"] objectForKey:@"curr"]]];
	[mbRightFanText setStringValue:[self noNilStr:[[fans objectForKey:@"Rightside"] objectForKey:@"curr"]]];

    [mbAirFanText setStringValue:[self noNilStr:[[fans objectForKey:@"Exhaust"] objectForKey:@"curr"]]];
	
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
    
    //handle missing temps
    if ([temps objectForKey:@"ambient"] == nil || [[[temps objectForKey:@"ambient"] objectForKey:@"curr"] intValue] == 0) {
        [airTempLevel setHidden:YES];
		[airButton setHidden:YES];		
		[airConnector setHidden:YES];
		[airDegree setStringValue:@""]; 
        [airTempText setStringValue:@""];        
    }
    if ([temps objectForKey:@"hdd"] == nil || [[[temps objectForKey:@"hdd"] objectForKey:@"curr"] intValue] == 0) {
        [hddTempLevel setHidden:YES];
		[hddButton setHidden:YES];
		[hddConnector setHidden:YES];
		[hddDegree setStringValue:@""];         
        [hddTempText setStringValue:@""];        
    }
    if ([temps objectForKey:@"cpu"] == nil || [[[temps objectForKey:@"cpu"] objectForKey:@"curr"] intValue] == 0) {
        [cpuTempLevel setHidden:YES];
		[cpuButton setHidden:YES];
		[cpuConnector setHidden:YES];
		[cpuDegree setStringValue:@""];
        [cpuTempText setStringValue:@""];        
    }    
	
    NSString *background = nil;
	for (NSString *key in fans){
		NSLevelIndicator *indicator = nil;
        
		if ([key isEqualToString:@"ODD"]) {
			indicator = airFanLevel;
            background = @"header.png";            
		}else if ([key isEqualToString:@"HDD"]) {
			indicator = hddFanLevel;
            background = @"header.png";            
		}else if ([key isEqualToString:@"CPU"]) {
			indicator = cpuFanLevel;
            background = @"header.png";                                  
        }
        
		if ([key isEqualToString:@"Leftside"]) {
			indicator = mbLeftFanLevel;
            background = @"header_macbook_pro.png";
		}else if ([key isEqualToString:@"Rightside"]) {
			indicator = mbRightFanLevel;
            background = @"header_macbook_pro.png";            
        }     
        
		if ([key isEqualToString:@"Exhaust"]) {
			indicator = mbAirFanLevel;            
            background = @"header_macbook_air.png";            
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
    
    if (background) {
        NSImage *back = [[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:background]] autorelease];            
        [backgroundHeaders setImage:back];     
    }
    
    if ([background isEqualToString:@"header.png"]){
        [self.view addSubview:regularFansView];                    
    }
    
    if ([background isEqualToString:@"header_macbook_pro.png"]){
        [self.view addSubview:macbookProFansView];                     
    }   
    
    if ([background isEqualToString:@"header_macbook_air.png"]){
        [self.view addSubview:macbookAirFansView];             
    }    
    
    //hide connectors if there are no fans
    if ([fans objectForKey:@"ODD"] == nil) {      
		[airButton setHidden:YES];		
		[airConnector setHidden:YES];		        
    }
    if ([fans objectForKey:@"HDD"] == nil) {      
		[hddButton setHidden:YES];
		[hddConnector setHidden:YES];	        
    }
    if ([fans objectForKey:@"CPU"] == nil) {     
		[cpuButton setHidden:YES];
		[cpuConnector setHidden:YES];	        
    }
    if ([fans objectForKey:@"Leftside"] == nil || [fans objectForKey:@"Rightside"] == nil) {     
		[macbookProButton setHidden:YES];
		[macbookProConnector setHidden:YES];	        
    }   
    if ([fans objectForKey:@"Exhaust"] == nil) {     
		[macbookAirButton setHidden:YES];
		[macbookAirConnector setHidden:YES];	        
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
    
    if (air > 0) {
        if (celsius == NO) {
            [airTempText setStringValue:[NSString stringWithFormat:@"%i",(int)(air*1.8)+32]];
            [airDegree setStringValue:@"°F"];
        }else {		
            [airTempText setStringValue:[NSString stringWithFormat:@"%i",air]];
            [airDegree setStringValue:@"°C"];
        }        
    }
    
    if (hdd > 0) {
        if (celsius == NO) {
            [hddTempText setStringValue:[NSString stringWithFormat:@"%i",(int)(hdd*1.8)+32]];
            [hddDegree setStringValue:@"°F"];	
        }else {		
            [hddTempText setStringValue:[NSString stringWithFormat:@"%i",hdd]];
            [hddDegree setStringValue:@"°C"];	
        }  
    }
    
    if (cpu > 0) {
        if (celsius == NO) {
            [cpuTempText setStringValue:[NSString stringWithFormat:@"%i",(int)(cpu*1.8)+32]];
            [cpuDegree setStringValue:@"°F"];	
        }else {		
            [cpuTempText setStringValue:[NSString stringWithFormat:@"%i",cpu]];		
            [cpuDegree setStringValue:@"°C"];		
        }  
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

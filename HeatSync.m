//
//  HeatSync.m
//  HeatSync
//
//  Created by Vlad Alexa on 9/3/10.
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

#import "HeatSync.h"
#import "HeatSyncPreferences.h"
#import "MainCore.h"
#import "smcWrapper.h"

static NSBundle* pluginBundle = nil;

@implementation HeatSync

@synthesize preferences;

/*
 Plugin events : 
 N/A
 
 Plugin events (nondynamic):
 N/A
 
 Plugin settings :
 togAir
 togCpu
 togHdd
 
 Plugin preferences :
 N/A					
 */  

+ (BOOL)initializeClass:(NSBundle*)theBundle {
	if (pluginBundle) {
		return NO;
	}
	pluginBundle = [theBundle retain];
	return YES;
}

+ (void)terminateClass {
	if (pluginBundle) {
		[pluginBundle release];
		pluginBundle = nil;
	}
}

- (id)init{
    self = [super init];
    if(self != nil) {
		
		preferences = [[HeatSyncPreferences alloc] initWithNibName:@"HeatSyncPreferences" bundle:pluginBundle];	
		NSString *bundleId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];					
		if ([bundleId isEqualToString:@"com.apple.systempreferences"]) return self;				
			
		//your initialization here		
		//NSLog(@"HeatSync init");									
		
		defaults = [NSUserDefaults standardUserDefaults];			
		
		//set settings
		if ([[[defaults objectForKey:@"HeatSync"] objectForKey:@"settings"] objectForKey:@"togAir"] == nil){
			[self saveSetting:[NSNumber numberWithBool:NO] forKey:@"togAir"];
		}
		if ([[[defaults objectForKey:@"HeatSync"] objectForKey:@"settings"] objectForKey:@"togCpu"] == nil){
			[self saveSetting:[NSNumber numberWithBool:YES] forKey:@"togCpu"];
		}
		if ([[[defaults objectForKey:@"HeatSync"] objectForKey:@"settings"] objectForKey:@"togHdd"] == nil){
			[self saveSetting:[NSNumber numberWithBool:YES] forKey:@"togHdd"];
		}		
		
		[smcWrapper setupHelper];		
		
		main = [[MainCore alloc] init];
		
    }
    return self;
}

-(void)dealloc{
	[super dealloc];
	[preferences release];
	[main release];
}	

-(void)saveSetting:(id)object forKey:(NSString*)key{
	NSString *pluginName = @"HeatSync";
	if (![[object class] isKindOfClass:[NSObject class]]) {
		NSLog(@"The value to be set for %@ is not a object",key);
		return;
	}
	NSMutableDictionary *settings = [[[defaults objectForKey:pluginName] objectForKey:@"settings"] mutableCopy];
	if (settings == nil) settings = [[NSMutableDictionary alloc] initWithCapacity:1];	
	[settings setObject:object forKey:key];
	NSMutableDictionary *dict = [[defaults objectForKey:pluginName] mutableCopy];
	if (dict == nil) dict = [[NSMutableDictionary alloc] initWithCapacity:1];	
	[dict setObject:settings forKey:@"settings"];
	
	[defaults setObject:dict forKey:pluginName];
	[defaults synchronize];
	
	[settings release];		
	[dict release];
}

@end

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

#define PLUGIN_NAME_STRING @"HeatSync"

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
	[preferences release];
	[main release];
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

@end

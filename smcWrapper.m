//
//  smcWrapper.m
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

#import "smcWrapper.h"

#include "smc.h"
#include <sys/sysctl.h>
#include <sys/param.h>
#include <sys/mount.h>

io_connect_t conn;

@implementation smcWrapper

+(void)openConn{	
    if (!conn) {
        kern_return_t result = SMCOpen(&conn);
        if (result != kIOReturnSuccess) {
            NSLog(@"Failed to open connection to SMC");
        }
    }		
}

#pragma mark temps

+(NSDictionary*)getAllKeys
{
	NSMutableDictionary *keys = [NSMutableDictionary dictionaryWithCapacity:1];
	[keys setValue:@"Memory Controller" forKey:@"Tm0P"];
	[keys setValue:@"Mem Bank A1" forKey:@"TM0P"];
	[keys setValue:@"Mem Bank A2" forKey:@"TM1P"];
	[keys setValue:@"Mem Bank A3" forKey:@"TM2P"];
	[keys setValue:@"Mem Bank A4" forKey:@"TM3P"]; // guessing
	[keys setValue:@"Mem Bank A5" forKey:@"TM4P"]; // guessing
	[keys setValue:@"Mem Bank A6" forKey:@"TM5P"]; // guessing
	[keys setValue:@"Mem Bank A7" forKey:@"TM6P"]; // guessing
	[keys setValue:@"Mem Bank A8" forKey:@"TM7P"]; // guessing
	[keys setValue:@"Mem Bank B1" forKey:@"TM8P"];
	[keys setValue:@"Mem Bank B2" forKey:@"TM9P"];
	[keys setValue:@"Mem Bank B3" forKey:@"TMAP"];
	[keys setValue:@"Mem Bank B4" forKey:@"TMBP"];  // guessing
	[keys setValue:@"Mem Bank B5" forKey:@"TMCP"]; // guessing
	[keys setValue:@"Mem Bank B6" forKey:@"TMDP"]; // guessing
	[keys setValue:@"Mem Bank B7" forKey:@"TMEP"]; // guessing
	[keys setValue:@"Mem Bank B8" forKey:@"TMFP"]; // guessing
	[keys setValue:@"Mem module A1" forKey:@"TM0S"];
	[keys setValue:@"Mem module A2" forKey:@"TM1S"];
	[keys setValue:@"Mem module A3" forKey:@"TM2S"];
	[keys setValue:@"Mem module A4" forKey:@"TM3S"];// guessing
	[keys setValue:@"Mem module A5" forKey:@"TM4S"]; // guessing
	[keys setValue:@"Mem module A6" forKey:@"TM5S"]; // guessing
	[keys setValue:@"Mem module A7" forKey:@"TM6S"]; // guessing
	[keys setValue:@"Mem module A8" forKey:@"TM7S"]; // guessing
	[keys setValue:@"Mem module B1" forKey:@"TM8S"];
	[keys setValue:@"Mem module B2" forKey:@"TM9S"];
	[keys setValue:@"Mem module B3" forKey:@"TMAS"]; 
	[keys setValue:@"Mem module B4" forKey:@"TMBS"]; // guessing
	[keys setValue:@"Mem module B5" forKey:@"TMCS"]; // guessing
	[keys setValue:@"Mem module B6" forKey:@"TMDS"]; // guessing
	[keys setValue:@"Mem module B7" forKey:@"TMES"]; // guessing
	[keys setValue:@"Mem module B8" forKey:@"TMFS"]; // guessing
	[keys setValue:@"CPU A" forKey:@"TC0P"]; //core      
	[keys setValue:@"CPU A Diode" forKey:@"TC0D"]; //diode  
	[keys setValue:@"CPU A Heatsink" forKey:@"TC0H"]; //heatsink
	[keys setValue:@"CPU A Heatsink" forKey:@"TCAH"]; //heatsink	
	[keys setValue:@"CPU B" forKey:@"TC1P"]; //core    
	[keys setValue:@"CPU B Diode" forKey:@"TC1D"]; //diode    
	[keys setValue:@"CPU B Heatsink" forKey:@"TC1H"]; //heatsink
	[keys setValue:@"CPU B Heatsink" forKey:@"TCBH"]; //heatsink
	[keys setValue:@"GPU A" forKey:@"TG0P"];
	[keys setValue:@"GPU A Diode" forKey:@"TG0D"];
	[keys setValue:@"GPU A Heatsink" forKey:@"TG0H"];
	[keys setValue:@"GPU B" forKey:@"TG1P"];    
	[keys setValue:@"GPU B Diode" forKey:@"TG1D"];
	[keys setValue:@"GPU B Heatsink" forKey:@"TG1H"];	
	[keys setValue:@"Ambient" forKey:@"TA0P"];
	[keys setValue:@"LCD" forKey:@"TL0P"];    
	[keys setValue:@"HD Bay 1" forKey:@"TH0P"];
	[keys setValue:@"HD Bay 2" forKey:@"TH1P"];
	[keys setValue:@"HD Bay 3" forKey:@"TH2P"];
	[keys setValue:@"HD Bay 4" forKey:@"TH3P"];
	[keys setValue:@"Optical Drive" forKey:@"TO0P"];
	[keys setValue:@"Heatsink A" forKey:@"Th0H"];
	[keys setValue:@"Heatsink B" forKey:@"Th1H"];
	[keys setValue:@"Power supply 2" forKey:@"Tp1C"];
	[keys setValue:@"Power supply 1" forKey:@"Tp0C"];
	[keys setValue:@"Power supply 1" forKey:@"Tp0P"];
	[keys setValue:@"Enclosure Bottom" forKey:@"TB0T"];
	[keys setValue:@"Northbridge 1" forKey:@"TN0P"];
	[keys setValue:@"Northbridge 2" forKey:@"TN1P"];
	[keys setValue:@"Northbridge" forKey:@"TN0H"];
	[keys setValue:@"Expansion Slots" forKey:@"TS0C"];
	[keys setValue:@"Airport Card" forKey:@"TW0P"];	
	[keys setValue:@"PCI Slot 1 Pos 1" forKey:@"TA0S"];
	[keys setValue:@"PCI Slot 1 Pos 2" forKey:@"TA1S"];
	[keys setValue:@"PCI Slot 2 Pos 1" forKey:@"TA2S"];
	[keys setValue:@"PCI Slot 2 Pos 2" forKey:@"TA3S"];
	[keys setValue:@"Ambient 2" forKey:@"TA1P"];
	[keys setValue:@"Power supply 2" forKey:@"Tp1P"];
	[keys setValue:@"Power supply 3" forKey:@"Tp2P"];
	[keys setValue:@"Power supply 4" forKey:@"Tp3P"];
	[keys setValue:@"Power supply 5" forKey:@"Tp4P"];
	[keys setValue:@"Power supply 6" forKey:@"Tp5P"];
    //keys from SMART, not from SMC
	[keys setValue:@"SMART HDD Drive 1" forKey:@"SMART1"];
	[keys setValue:@"SMART HDD Drive 2" forKey:@"SMART2"];
	[keys setValue:@"SMART HDD Drive 3" forKey:@"SMART3"];
	[keys setValue:@"SMART HDD Drive 4" forKey:@"SMART4"];        
    /*    
	[keys setValue:@"MB unknown AC power related (ui8)" forKey:@"ACCL"];
	[keys setValue:@"MB unknown AC power related (ui8)" forKey:@"ACEN"];
	[keys setValue:@"MB unknown AC power related (flag)" forKey:@"ACFP"];
	[keys setValue:@"MB unknown AC power related (ch8*)" forKey:@"ACID"];
	[keys setValue:@"MB unknown AC power related (flag)" forKey:@"ACIN"];
	[keys setValue:@"MB unknown AC power related (flag)" forKey:@"ACOW"];    
	[keys setValue:@"MB unknown battery related (si16)" forKey:@"B0AC"];
	[keys setValue:@"MB unknown battery related (flag)" forKey:@"B0AP"];
	[keys setValue:@"MB unknown battery related (ui16)" forKey:@"B0AV"];
	[keys setValue:@"MB unknown battery related (ui16)" forKey:@"B0Ad"];
	[keys setValue:@"MB unknown battery related (ui16)" forKey:@"B0Al"];
	[keys setValue:@"MB unknown battery related (ui8)" forKey:@"B0Am"];
	[keys setValue:@"MB unknown battery related (ui8)" forKey:@"B0Ar"];  
    */     
	return keys;
}

+ (NSDictionary*)getKeyValues
{
	NSString *cachePath = [NSString stringWithFormat:@"%@/Library/Application Support/HeatSync/keys.plist",NSHomeDirectory()];
    NSMutableDictionary *cachedKeys = [NSMutableDictionary dictionaryWithContentsOfFile:cachePath];
    if (cachedKeys == nil) cachedKeys = [NSMutableDictionary dictionaryWithDictionary:[smcWrapper getAllKeys]];
    NSMutableDictionary *loopKeys = [NSMutableDictionary dictionaryWithContentsOfFile:cachePath];   
    if (loopKeys == nil) loopKeys = [NSMutableDictionary dictionaryWithDictionary:[smcWrapper getAllKeys]];    
	NSMutableDictionary *foundKeys = [NSMutableDictionary dictionaryWithCapacity:1];
    SMCVal_t      val;	
	for(NSString *key in loopKeys){
		kern_return_t result = SMCReadKey2((char *)[key cStringUsingEncoding:NSASCIIStringEncoding], &val,conn);
		if (result == kIOReturnSuccess){
			if (val.dataSize > 0) {
                int value = ((val.bytes[0] * 256 + val.bytes[1]) >> 2)/64;
				if(value <= 0) continue;				
				[foundKeys setValue:[NSNumber numberWithInt:value] forKey:key];				
			}else {
                [cachedKeys removeObjectForKey:key];                
            }
		}
	}
    [cachedKeys writeToFile:cachePath atomically:YES];
	if ([foundKeys count] == 0) NSLog(@"getKeyValues found nothing");
	return foundKeys;
}

#pragma mark fans

+(int) get_fan_rpm:(int)fan_number{
	UInt32Char_t  key;
	SMCVal_t      val;
	//kern_return_t result;
	sprintf(key, "F%dAc", fan_number);
	SMCReadKey2(key, &val,conn);
	int running= _strtof(val.bytes, val.dataSize, 2);
	return running;
}	

+(int) get_fan_num{
    SMCVal_t      val;
    int           totalFans;
	SMCReadKey2("FNum", &val,conn);
    totalFans = _strtoul(val.bytes, val.dataSize, 10); 
	return totalFans;
}

+(NSString*) get_fan_descr:(int)fan_number{
	UInt32Char_t  key;
	char temp;
	SMCVal_t      val;
	NSMutableString *desc = [[NSMutableString alloc] init];
	sprintf(key, "F%dID", fan_number);
	SMCReadKey2(key, &val,conn);
	int i;
	for (i = 0; i < val.dataSize; i++) {
		if ((int)val.bytes[i]>32) {
			temp=(unsigned char)val.bytes[i];
			[desc appendFormat:@"%c",temp];
		}
	}	
	return [desc autorelease];
}	


+(int) get_min_speed:(int)fan_number{
	UInt32Char_t  key;
	SMCVal_t      val;
	sprintf(key, "F%dMn", fan_number);
	SMCReadKey2(key, &val,conn);
	int min= _strtof(val.bytes, val.dataSize, 2);
	return min;
}	

+(int) get_max_speed:(int)fan_number{
	UInt32Char_t  key;
	SMCVal_t      val;
	sprintf(key, "F%dMx", fan_number);
	SMCReadKey2(key, &val,conn);
	int max= _strtof(val.bytes, val.dataSize, 2);
	return max;
}	

#pragma mark write

+(void)setFanRpm:(NSString *)key value:(NSString *)value{
	//NSString *launchPath = [[NSBundle mainBundle] pathForResource:@"smc" ofType:@""];	
	NSString *launchPath = [NSString stringWithFormat:@"%@/Library/Application Support/HeatSync/smc",NSHomeDirectory()];	
    NSArray *argsArray = [NSArray arrayWithObjects: @"-k",key,@"-w",value,nil];    
	if (launchPath && [[NSFileManager defaultManager] fileExistsAtPath:launchPath]) {	
		NSTask *task = [[NSTask alloc] init];
		[task setLaunchPath:launchPath];
		[task setArguments:argsArray];
		[task launch];
		[task release];		
		//NSLog(@"Setting smc -w %@ -k %@",value,key);			
	}else {
		NSLog(@"smc binary was not found at %@",launchPath);
	}
}

+ (NSString*)installAndCheckHelper:(NSString*)copyFrom{
	
	NSString *folder = [NSString stringWithFormat:@"%@/Library/Application Support/HeatSync",NSHomeDirectory()];	
	NSString *copyTo = [NSString stringWithFormat:@"%@/smc",folder];	
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:folder]) {			
		BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:folder withIntermediateDirectories:TRUE attributes:nil error:nil];
		if (success == FALSE) {
			NSLog(@"Failed to create folder (%@).",folder);			
		}else {
			//NSLog(@"Created folder (%@).",folder);
		}					
	}	
	if ([[NSFileManager defaultManager] fileExistsAtPath:copyTo]) {	
		//check md5
		NSString *output = [[smcWrapper execTask:@"/sbin/md5" args:[NSArray arrayWithObjects:@"-q",copyTo,nil]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		NSString *md5 = @"8d0bdb6253cf2bb2b9cd3a1e9af1f95d";
		if (output) {
			if ([output isEqualToString:md5]) {
				return copyTo;
			}else {
				NSLog(@"md5 does not match (%@) should be (%@)",output,md5);
				BOOL success = [[NSFileManager defaultManager] removeItemAtPath:copyTo error:nil];	
				if (success == FALSE) {
					NSLog(@"Failed to delete old smc (%@).",copyTo);	
				}				
			}
		}else {
			NSLog(@"could not get md5 hash");
		}	
	}	
	BOOL success = [[NSFileManager defaultManager] copyItemAtPath:copyFrom toPath:copyTo error:nil];
	if (success == FALSE) {
		NSString *message = [NSString stringWithFormat:@"Failed to copy smc (%@ to %@).",copyFrom,copyTo];
		NSLog(@"%@",message); //TODO
		[[NSNotificationCenter defaultCenter] postNotificationName:@"MPpluginsEvent" object:@"local" userInfo:
		 [NSDictionary dictionaryWithObjectsAndKeys:@"doAlert",@"what",
		  @"Unable to install the smc helper",@"title",
		  message,@"text",
		  @"OK",@"action",
		  nil]
		 ];		
	}else {
		NSLog(@"Copied smc to %@",copyTo);
	}
	return copyTo;
}

+ (void)removeHelper{
	NSString *launchPath = [NSString stringWithFormat:@"%@/Library/Application Support/HeatSync/smc",NSHomeDirectory()];	
	BOOL success = [[NSFileManager defaultManager] removeItemAtPath:launchPath error:nil];	
	if (success == FALSE) {
		NSLog(@"Failed to delete smc (%@).",launchPath);	
	}	

}

+(void)setupHelper{	
	//copy it if it does not exist or if md5 does not match	
	NSString *bundlePath = [[NSBundle bundleForClass:[smcWrapper class]] pathForResource:@"smc" ofType:@""];
	NSString *smcpath = [smcWrapper installAndCheckHelper:bundlePath];
	
	//check if the helper allready has the proper settings
	NSDictionary *fdict = [[NSFileManager defaultManager] attributesOfItemAtPath:smcpath error:nil];
	if ([[fdict valueForKey:@"NSFileOwnerAccountName"] isEqualToString:@"root"] && [[fdict valueForKey:@"NSFileGroupOwnerAccountName"] isEqualToString:@"admin"] && ([[fdict valueForKey:@"NSFilePosixPermissions"] intValue]==3437)) {
		return;
	} else {
		//NSLog(@"Setting rights for %@",smcpath);
	}
	
	//set them
	OSStatus status;
	AuthorizationRef authorizationRef;	
	AuthorizationFlags myFlags = kAuthorizationFlagExtendRights | kAuthorizationFlagInteractionAllowed;	
	AuthorizationItem myItems = {kAuthorizationRightExecute,0,NULL, 0};
	AuthorizationRights myRights = {1, &myItems};	
	status = AuthorizationCreate(&myRights,  kAuthorizationEmptyEnvironment, myFlags, &authorizationRef);

    if (status == errAuthorizationSuccess){
		char *pathChar = (char *)[smcpath cStringUsingEncoding:NSUTF8StringEncoding];
		//set owner
		char *chownPath = "/usr/sbin/chown";
		char *chownArgs[] = { "root:admin", pathChar , NULL };
		status = AuthorizationExecuteWithPrivileges(authorizationRef,chownPath,kAuthorizationFlagDefaults,chownArgs,NULL);
		if (status != errAuthorizationSuccess) {
			//NSLog(@"Set owner failed");			
		}
		//set suid-bit		
		char *chmodPath = "/bin/chmod";
		char *chmodArgs[] = { "6555", pathChar , NULL };		
		status = AuthorizationExecuteWithPrivileges(authorizationRef,chmodPath,kAuthorizationFlagDefaults,chmodArgs,NULL);
		if (status != errAuthorizationSuccess) {
			//NSLog(@"Set suid failed");			
		}	
	}else {
		NSLog(@"Authorization failed");
	}
}

#pragma mark tools

+(BOOL)volHasOwnershipSuid:(NSString*)path{
	//check if the volume has ownership and suid 
	NSArray *pathComponents = [path pathComponents];
	NSString *volume = [NSString stringWithFormat:@"/%@/%@",[pathComponents objectAtIndex:1],[pathComponents objectAtIndex:2]];
	struct statfs sb;
	int err = statfs([volume cStringUsingEncoding:NSUTF8StringEncoding], &sb);	
	if (err == 0) {
		if (sb.f_flags & MNT_IGNORE_OWNERSHIP) {
			NSLog(@"Ownership ignored on %@",volume);			
			return NO;			
		}
		if (sb.f_flags & MNT_NOSUID) {
			NSLog(@"NO setuid bits on %@",volume);			
			return NO;			
		}		
	}else {
		NSLog(@"Failed to statfs %@",volume);
		return NO;		
	}
	return YES;
}

+(NSString*)execTask:(NSString*)launch args:(NSArray*)args{
    //NSLog(@"Exec: %@",launch);
	NSTask *task = [[[NSTask alloc] init] autorelease];
	[task setLaunchPath:launch];
	[task setArguments:args];
	
	NSPipe *pipe = [NSPipe pipe];
	[task setStandardOutput:pipe];
	
	NSFileHandle *file = [pipe fileHandleForReading];
	
	[task launch];
	
	NSData *data = [file readDataToEndOfFile];
	
	NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	return [string autorelease];
}

+ (NSString *)machineName{
    NSString *modelString = nil;
    io_service_t pexpdev;
    if ((pexpdev = IOServiceGetMatchingService (kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))))
    {
        CFDataRef data;
        if ((data = IORegistryEntryCreateCFProperty(pexpdev, CFSTR("product-name"), kCFAllocatorDefault, 0))) {
            modelString = [[NSString alloc] initWithCString:[(NSData*)data bytes] encoding:NSASCIIStringEncoding];
            CFRelease(data);
        }
    }    
    return [modelString autorelease];
}

+ (NSString*)machineModel {
    NSString * modelString  = nil;
    int        modelInfo[2] = { CTL_HW, HW_MODEL };
    size_t     modelSize;
	
    if (sysctl(modelInfo,2,NULL,&modelSize,NULL, 0) == 0)
    {
        void * modelData = malloc(modelSize);        
        if (modelData){
            if (sysctl(modelInfo,2,modelData,&modelSize,NULL, 0) == 0){
                modelString = [NSString stringWithUTF8String:modelData];
            }            
            free(modelData);
        }
    }    
    return modelString;
}

+ (BOOL)isIntel {
	SInt32 gestaltReturnValue;	
	OSType returnType = Gestalt(gestaltSysArchitecture, &gestaltReturnValue);	
	if (!returnType && gestaltReturnValue == gestaltIntel)	return YES;	
	return NO;
}

+ (BOOL) isDesktop {
	NSString *machineName = [smcWrapper machineModel];	
	if ([machineName rangeOfString:@"PowerBook"].location != NSNotFound) return NO;
	if ([machineName rangeOfString:@"MacBook"].location != NSNotFound) return NO;	
	return YES;	
}

@end


@implementation NSNumber (NumberAdditions)

- (NSString*) tohex{
	if ([self intValue] < 100)	NSLog(@"Will set fan rpm lower than 100");
	return [NSString stringWithFormat:@"%0.4x",[self intValue]<<2];
}


- (NSNumber*) celsius_fahrenheit{
	float celsius=[self floatValue];
	float fahrenheit=(celsius*9)/5+32;
	return [NSNumber numberWithFloat:fahrenheit];
}

@end

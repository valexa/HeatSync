//
//  VADiskPooler.m
//  HeatSync
//
//  Created by Vlad Alexa on 6/16/11.
//  Copyright 2011 NextDesign. 
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

#import "VADiskPooler.h"
#import "SMARTQuery.h"

@implementation VADiskPooler

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

+(int)smartTemperature:(NSString*)iopath{
    int ret = 0;
    const char *path = [iopath UTF8String];            
    io_service_t service = IORegistryEntryFromPath(kIOMasterPortDefault,path);
    if (service) {
        NSDictionary *smartDict = [SMARTQuery getSMARTData:service]; 
        if (smartDict) {
            ret = [[smartDict objectForKey:@"Temp"] intValue];
            if ([[smartDict objectForKey:@"deviceOK"] intValue] != 1) {
                NSLog(@"SMART reports drive at %@ is failing",iopath);
            }               
        }else{
            NSLog(@"ERROR getting SMART data from drive at %@",iopath);            
        }      
    }      
    return ret;    
}

+(NSArray*)getDrives{      
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:1];    
	io_service_t root = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleACPIPlatformExpert"));    
    if (root) {
        io_iterator_t  iter;        
        // Create an iterator across all children of the root service object passed in.
        IORegistryEntryCreateIterator(root,kIOServicePlane,kIORegistryIterateRecursively,&iter);           
        if (iter){
            io_service_t service;            
            while ( ( service = IOIteratorNext( iter ) ) )  {
                if (service) {                                     
                    if ( IOObjectConformsTo( service, "IOBlockStorageDriver") ) {                                                
                        io_service_t parent;
                        IORegistryEntryGetParentEntry(service,kIOServicePlane,&parent);
                        if (parent) {
                            NSString *interface = [VADiskPooler interfaceType:parent];
                            if (interface) {
                                NSDictionary *powerstatus = [VADiskPooler getPower:parent interface:interface];
                                if (powerstatus) {
                                    BOOL sleeping = [VADiskPooler isSleeping:powerstatus];            
                                    BOOL capable = [VADiskPooler isSmartCapable:parent];                             
                                    NSString *path = [VADiskPooler getPathAsStringFor:parent];        
                                    if (path && capable && !sleeping) {
                                        [ret addObject:path];
                                    }                                       
                                }                             
                            }
                            IOObjectRelease(parent);
                        }
                    }                    
                    IOObjectRelease(service);                        
                }                
            }
            IOObjectRelease(iter);            
        }else{
            NSLog(@"Error iterating AppleACPIPlatformExpert");        
        }  
        IOObjectRelease(root);        
    }else{
        NSLog(@"No AppleACPIPlatformExpert found");      
    }          
    return ret;
}

+(NSString*)interfaceType:(io_service_t)device{
    if (IOObjectConformsTo(device,"IOATABlockStorageDevice")) return @"ATA";    
    if (IOObjectConformsTo(device,"IOAHCIBlockStorageDevice")) return @"SATA"; 
    if (IOObjectConformsTo(device,"IOBlockStorageServices")) return @"USB"; //IOSCSIPeripheralDeviceType00
    if (IOObjectConformsTo(device,"IOReducedBlockServices")) return @"FireWire"; //IOSCSIPeripheralDeviceType0E
    CFStringRef class = IOObjectCopyClass(device);
    if (class) {
        //NSLog(@"Unknown device type %@",(NSString*)class);
        CFRelease(class);
    }
    return nil;
}

+(NSString*)getPathAsStringFor:(io_service_t)service{
    io_string_t   devicePath;
    if (IORegistryEntryGetPath(service, kIOServicePlane, devicePath) == KERN_SUCCESS)    {
        return [NSString stringWithFormat:@"%s",&devicePath];
    }else{
        NSLog(@"Error getting path");
    }
    return nil;
}

+(BOOL)isSmartCapable:(io_service_t)device{    
    BOOL ret = NO;    
    CFTypeRef theCFProperty = IORegistryEntryCreateCFProperty(device, CFSTR("SMART Capable"), kCFAllocatorDefault, 0);        
    if (theCFProperty) {
        ret = CFBooleanGetValue(theCFProperty) ? YES : NO;
        CFRelease(theCFProperty);
    }       
    return ret;
}

+(BOOL)isSleeping:(NSDictionary*)dict{ 
    //check if IdleTimerPeriod is not greater than checkFrequency which would prevent it from sleeping
    int64_t checkFrequency = 660;    
    int64_t IdleTimerPeriod = [[dict objectForKey:@"IdleTimerPeriod"] intValue] / 1000ULL;
    if (IdleTimerPeriod > checkFrequency && [[dict objectForKey:@"DevicePowerState"] intValue] > 1) {
        NSLog(@"Drive is not sleeping and checkFrequency %lld is higher than IdleTimerPeriod %lld, will lie about the drive being asleep as to not prevent it from falling asleep",checkFrequency,IdleTimerPeriod);
        return YES;
    }
    //actual check
    if ([[dict objectForKey:@"DevicePowerState"] intValue] > 1) {
        return NO;
    }else{
        return YES;    
    }
    return NO;
}

+(NSDictionary*)getPower:(io_service_t)root interface:(NSString*)interface{  
    NSDictionary *ret = nil;
    if ([interface isEqualToString:@"USB"] || [interface isEqualToString:@"FireWire"]) {
        io_service_t parent;
        IORegistryEntryGetParentEntry(root,kIOServicePlane,&parent);
        if (parent) {  
            ret = [VADiskPooler getDictForProperty:@"IOPowerManagement" device:parent];            
            IOObjectRelease(parent);            
        }    
        if (ret == nil) NSLog(@"ERROR getting power management info for %@ device",interface);        
    }else if ([interface isEqualToString:@"SATA"]){
        io_iterator_t  iter;        
        // Create an iterator across all parents of object passed in
        IORegistryEntryCreateIterator(root,kIOServicePlane,kIORegistryIterateParents|kIORegistryIterateRecursively,&iter);          
        if (iter){
            io_service_t service;            
            while ( ( service = IOIteratorNext( iter ) ) )  {
                if (service) {
                    if ( IOObjectConformsTo( service, "AppleAHCIPort") ) {                    
                        //descend into IOPowerConnection/AppleAHCIDiskQueueManager                        
                        io_service_t child;
                        IORegistryEntryGetChildEntry(service,kIOPowerPlane,&child);
                        if (child) {               
                            io_service_t childofchild;
                            IORegistryEntryGetChildEntry(child,kIOPowerPlane,&childofchild);
                            if (childofchild) {
                                ret = [VADiskPooler getDictForProperty:@"IOPowerManagement" device:childofchild];                                            
                                IOObjectRelease( childofchild );   
                            }  
                            IOObjectRelease( child );                            
                        }  
                    }   
                    IOObjectRelease( service );
                }                
            }
            IOObjectRelease( iter );            
        }else{
            NSLog(@"Error iterating root for %@ device",interface);        
        }  
        if (ret == nil) NSLog(@"ERROR getting power management info for %@ device",interface);
    }else{
        NSLog(@"Power management info is not supported for %@ device",interface);
    } 
    return ret;
}

+(NSDictionary*)getDictForProperty:(NSString*)propertyName device:(io_service_t)device{
	NSDictionary *ret = nil;		
    CFTypeRef theCFProperty = IORegistryEntryCreateCFProperty(device, (CFStringRef)propertyName, kCFAllocatorDefault, 0);        
    if (theCFProperty) {
        if (CFGetTypeID(theCFProperty) != CFDictionaryGetTypeID()){
            NSLog(@"Value for %@ is not a dict",propertyName);                    
        }else{
            ret = [NSDictionary dictionaryWithDictionary:(NSDictionary *)theCFProperty];
        }        
        CFRelease(theCFProperty);           
	}else{
        NSLog(@"Could not get %@",propertyName);
    }    
	return ret;
}

@end

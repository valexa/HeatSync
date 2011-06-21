//
//  HeatSyncPreferences.h
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


#import <Cocoa/Cocoa.h>

@interface HeatSyncPreferences : NSViewController {	
	
	IBOutlet NSImageView *thermometerImage;
	IBOutlet NSImageView *fanImage;	

	IBOutlet NSButton *airButton;
	IBOutlet NSButton *hddButton;
	IBOutlet NSButton *cpuButton;
	
	IBOutlet NSTextField *airTempText;
	IBOutlet NSTextField *hddTempText;
	IBOutlet NSTextField *cpuTempText;
	
	IBOutlet NSTextField *airFanText;
	IBOutlet NSTextField *hddFanText;
	IBOutlet NSTextField *cpuFanText;
	
	IBOutlet NSLevelIndicator *airTempLevel;
	IBOutlet NSLevelIndicator *hddTempLevel;
	IBOutlet NSLevelIndicator *cpuTempLevel;
	
	IBOutlet NSLevelIndicator *airFanLevel;
	IBOutlet NSLevelIndicator *hddFanLevel;
	IBOutlet NSLevelIndicator *cpuFanLevel;	
	
	IBOutlet NSImageView *airConnector;
	IBOutlet NSImageView *hddConnector;
	IBOutlet NSImageView *cpuConnector;		
	
	IBOutlet NSTextField *airDegree;
	IBOutlet NSTextField *hddDegree;
	IBOutlet NSTextField *cpuDegree;	
	
	IBOutlet NSImageView *backgroundHeaders; 
    
	IBOutlet NSView *regularFansView;
	IBOutlet NSView *macbookProFansView;     
	IBOutlet NSView *macbookAirFansView;    
    
	IBOutlet NSButton *macbookProButton;
	IBOutlet NSButton *macbookAirButton;

	IBOutlet NSImageView *macbookProConnector;    
	IBOutlet NSImageView *macbookAirConnector;    
    
	IBOutlet NSLevelIndicator *mbLeftFanLevel;
	IBOutlet NSLevelIndicator *mbRightFanLevel;
	IBOutlet NSLevelIndicator *mbAirFanLevel;    
	
	IBOutlet NSTextField *mbLeftFanText;
	IBOutlet NSTextField *mbRightFanText;    
	IBOutlet NSTextField *mbAirFanText;    
	
}

-(void)saveSetting:(id)object forKey:(NSString*)key;
-(void)setMinRpm:(NSString*)fanName;
-(void)syncUI;
-(IBAction)togAir:(id)sender;
-(IBAction)togHdd:(id)sender;
-(IBAction)togCpu:(id)sender;
-(IBAction)togMacbok:(id)sender;
-(IBAction)togMacbokAir:(id)sender;
-(IBAction)changeDegrees:(id)sender;
-(NSString*)noNilStr:(NSString*)str;
	
@end

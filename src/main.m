// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Pathways Into Mischief contributors
#import <Cocoa/Cocoa.h>
static const NSUInteger Header=0x6f4,Stride=0xb3c,Inventory=828,Slots=10,Count=256;
static int rd(NSData*d,NSUInteger p){if(p+2>d.length)return -99999;const unsigned char*b=d.bytes;return (int16_t)((b[p]<<8)|b[p+1]);}
static void wr(NSMutableData*d,NSUInteger p,int v){unsigned char*b=d.mutableBytes;b[p]=(v>>8)&255;b[p+1]=v&255;}

static uint32_t rd32(NSData*d,NSUInteger p){if(p+4>d.length)return 0;const uint8_t*b=d.bytes;return ((uint32_t)b[p]<<24)|((uint32_t)b[p+1]<<16)|((uint32_t)b[p+2]<<8)|b[p+3];}
static void wr32(NSMutableData*d,NSUInteger p,uint32_t v){uint8_t*b=d.mutableBytes;for(int k=0;k<4;k++)b[p+k]=(v>>(24-8*k))&255;}
static BOOL container(int t){return t==6||t==8||t==9||t==10||(t>=25&&t<=28)||(t>=46&&t<=50);}
static BOOL ammo(int t){return t>=51&&t<=60;}
static NSDictionary*names;
static NSString*name(int t){return names[@(t)]?:[NSString stringWithFormat:@"Unknown item (%d)",t];}
static NSUInteger base(int s){return Header+s*Stride;}
static NSUInteger item(int s,int i){return base(s)+Inventory+i*8;}
static NSString*slotName(NSData*d,int s){const unsigned char*b=d.bytes;int n=b[s*128];if(n>127)return nil;return [[NSString alloc]initWithBytes:b+s*128+1 length:n encoding:NSMacOSRomanStringEncoding];}
static NSArray*active(NSData*d,int s){NSMutableArray*a=[NSMutableArray array];for(int i=0;i<256;i++)if(rd(d,item(s,i))>=0)[a addObject:@(i)];return a;}
static BOOL graph(NSData*d,int s,int*root,NSString**why){
 if(d.length<Header+Slots*Stride){if(why)*why=@"File is too short for the supported save format.";return NO;}
 NSArray*a=active(d,s);if(!a.count){if(why)*why=@"Empty inventory or unsupported format.";return NO;}
 NSMutableSet*refs=[NSMutableSet set];
 for(NSNumber*n in a){int i=n.intValue,t=rd(d,item(s,i)),state=rd(d,item(s,i)+2);if(!names[@(t)]||state<0||state>7){if(why)*why=@"Unrecognised item type or state.";return NO;}
  int links[2]={rd(d,item(s,i)+6),container(t)?rd(d,item(s,i)+4):-1};
  for(int k=0;k<2;k++){int j=links[k];if(j==-1)continue;if(j<0||j>=256||rd(d,item(s,j))<0||[refs containsObject:@(j)]){if(why)*why=@"Ambiguous inventory links: no changes were made.";return NO;}[refs addObject:@(j)];}
 }
 NSMutableSet*roots=[NSMutableSet setWithArray:a];[roots minusSet:refs];if(roots.count!=1){if(why)*why=@"Unrecognised inventory root.";return NO;}
 int r=[[roots anyObject]intValue];NSMutableArray*q=[NSMutableArray arrayWithObject:@(r)];NSMutableSet*seen=[NSMutableSet set];
 while(q.count){NSNumber*n=q.lastObject;[q removeLastObject];if([seen containsObject:n]){if(why)*why=@"Inventory cycle detected.";return NO;}[seen addObject:n];int i=n.intValue,t=rd(d,item(s,i));int next=rd(d,item(s,i)+6);if(next>=0)[q addObject:@(next)];if(container(t)){int child=rd(d,item(s,i)+4);if(child>=0)[q addObject:@(child)];}}
 if(seen.count!=a.count){if(why)*why=@"Disconnected inventory items.";return NO;}
 if(root)*root=r;return YES;
}
static BOOL add(NSMutableData*d,int s,int t,NSString**why){int root;if(!names[@(t)]||!graph(d,s,&root,why))return NO;int free=-1;for(int i=0;i<256;i++)if(rd(d,item(s,i))==-1){free=i;break;}if(free<0){if(why)*why=@"All 256 inventory slots are occupied.";return NO;}
 int tail=root;while(rd(d,item(s,tail)+6)>=0)tail=rd(d,item(s,tail)+6);
 int value=container(t)?-1:ammo(t)?(t==51||t==57?8:t==52?32:t>=58?1:30):t==2?2880:0;
 wr(d,item(s,free),t);wr(d,item(s,free)+2,0);wr(d,item(s,free)+4,value);wr(d,item(s,free)+6,-1);wr(d,item(s,tail)+6,free);return graph(d,s,0,why);
}

static int findType(NSData*d,int s,int t){for(int i=0;i<256;i++)if(rd(d,item(s,i))==t)return i;return -1;}
static BOOL removeItem(NSMutableData*d,int s,int i,NSString**why){int root;if(!graph(d,s,&root,why))return NO;if(i==root){if(why)*why=@"Removing the inventory's first item is not supported yet.";return NO;}NSUInteger off=item(s,i);int t=rd(d,off);if(rd(d,off+2)){if(why)*why=@"Unequip this item in the game before removing it.";return NO;}
 int after=rd(d,off+6),child=container(t)?rd(d,off+4):-1,replacement=after;
 if(child>=0){replacement=child;int tail=child;while(rd(d,item(s,tail)+6)>=0)tail=rd(d,item(s,tail)+6);wr(d,item(s,tail)+6,after);}
 for(int j=0;j<256;j++){if(j==i||rd(d,item(s,j))<0)continue;if(rd(d,item(s,j)+6)==i)wr(d,item(s,j)+6,replacement);if(container(rd(d,item(s,j)))&&rd(d,item(s,j)+4)==i)wr(d,item(s,j)+4,replacement);}
 wr(d,off,-1);wr(d,off+2,0);wr(d,off+4,0);wr(d,off+6,0);return graph(d,s,0,why);
}
static BOOL arsenal(NSMutableData*d,int s,NSString**why){NSMutableData*test=[d mutableCopy];
 for(int t=45;t<=50;t++){if(findType(test,s,t)<0&&!add(test,s,t,why))return NO;}
 // Every existing magazine is refilled; add missing ammunition types once.
 for(int t=51;t<=60;t++){
  if(findType(test,s,t)<0&&!add(test,s,t,why))return NO;
  for(int i=0;i<256;i++)if(rd(test,item(s,i))==t)wr(test,item(s,i)+4,10000);
 }

 // Load each empty gun with a matching magazine, preserving existing loaded ones.
 int ammoTypes[]={51,57,52,53,58};
 for(int t=46;t<=50;t++){int gun=findType(test,s,t);if(rd(test,item(s,gun)+4)>=0)continue;int mag=findType(test,s,ammoTypes[t-46]);int next=rd(test,item(s,mag)+6);BOOL linked=NO;
  for(int j=0;j<256;j++){if(rd(test,item(s,j))<0||j==mag)continue;if(rd(test,item(s,j)+6)==mag){wr(test,item(s,j)+6,next);linked=YES;break;}if(container(rd(test,item(s,j)))&&rd(test,item(s,j)+4)==mag){wr(test,item(s,j)+4,next);linked=YES;break;}}
  if(!linked){if(why)*why=@"Could not load a matching magazine into this weapon.";return NO;}wr(test,item(s,mag)+6,-1);wr(test,item(s,gun)+4,mag);
 }
 if(!graph(test,s,0,why))return NO;[d setData:test];return YES;
}

static NSDictionary*counts(NSData*d,int s){NSMutableDictionary*m=[NSMutableDictionary dictionary];for(NSNumber*t in names)m[t]=@0;for(NSNumber*i in active(d,s)){NSNumber*t=@(rd(d,item(s,i.intValue)));m[t]=@([m[t]intValue]+1);}return m;}

static NSArray*groups(void){return @[
 @[@"Crystals",@[@64,@65,@66,@68,@69,@70]],
 @[@"Potions",@[@18,@19,@20,@21]],
 @[@"Weapons",@[@45,@46,@47,@48,@49,@50]],
 @[@"Ammunition",@[@51,@52,@53,@54,@55,@56,@57,@58,@59,@60]],
 @[@"Tools and equipment",@[@0,@1,@2,@3,@4,@14,@33]],
 @[@"Bags and boxes",@[@6,@8,@9,@10]],
 @[@"Quest items and treasure",@[@12,@16,@17,@29,@30,@31,@32,@34,@35,@36,@37,@38,@40,@41,@61]],
 @[@"Documents and curiosities",@[@22,@23,@24,@62,@63]],
 @[@"Damaged weapons",@[@25,@26,@27,@28]]];}
static void crystalPreset(NSMutableDictionary*m){for(NSNumber*t in @[@64,@65,@66,@68,@69,@70])if([m[t]intValue]<1)m[t]=@1;}
static BOOL setCounts(NSMutableData*d,int s,NSDictionary*target,NSString**why){NSInteger total=0;for(NSNumber*t in names){NSInteger n=[target[t]integerValue];if(n<0||n>256){if(why)*why=@"Each quantity must be an integer from 0 to 256.";return NO;}total+=n;}if(total>256){if(why)*why=[NSString stringWithFormat:@"%ld items requested, but only 256 slots are available. Reduce some quantities.",(long)total];return NO;}
 NSMutableData*test=[d mutableCopy];NSArray*types=[[names allKeys]sortedArrayUsingSelector:@selector(compare:)];
 for(NSNumber*t in types){int wanted=[target[t]intValue];while([counts(test,s)[t]intValue]>wanted){int root;NSString*err;if(!graph(test,s,&root,&err)){if(why)*why=err;return NO;}int candidate=-1;for(int i=255;i>=0;i--)if(i!=root&&rd(test,item(s,i))==t.intValue&&rd(test,item(s,i)+2)==0){candidate=i;break;}if(candidate<0){if(why)*why=[NSString stringWithFormat:@"Cannot reduce %@ to %d: the remaining item is equipped or is the inventory root.",name(t.intValue),wanted];return NO;}if(!removeItem(test,s,candidate,why))return NO;}}
 for(NSNumber*t in types)while([counts(test,s)[t]intValue]<[target[t]intValue])if(!add(test,s,t.intValue,why))return NO;
 if(!graph(test,s,0,why))return NO;[d setData:test];return YES;
}
static BOOL saveReplacing(NSURL*url,NSData*expected,NSData*data,NSURL**backup,NSError**error){
 NSFileManager*fm=NSFileManager.defaultManager;NSData*current=[NSData dataWithContentsOfURL:url options:0 error:error];if(!current)return NO;
 if(![current isEqual:expected]){if(error)*error=[NSError errorWithDomain:@"PathwaysIntoMischief" code:1 userInfo:@{NSLocalizedDescriptionKey:@"The file has changed since it was opened. Reopen it before saving."}];return NO;}
 NSURL*temp=[url.URLByDeletingLastPathComponent URLByAppendingPathComponent:[NSString stringWithFormat:@".pathways-%@.tmp",NSUUID.UUID.UUIDString]];
 NSURL*bak=[url.URLByDeletingLastPathComponent URLByAppendingPathComponent:[NSString stringWithFormat:@"%@ — before edit %@.pathways",url.lastPathComponent.stringByDeletingPathExtension,NSUUID.UUID.UUIDString]];
 if(![data writeToURL:temp options:NSDataWritingWithoutOverwriting error:error])return NO;
 if(![fm moveItemAtURL:url toURL:bak error:error]){[fm removeItemAtURL:temp error:nil];return NO;}
 if(![fm moveItemAtURL:temp toURL:url error:error]){[fm moveItemAtURL:bak toURL:url error:nil];[fm removeItemAtURL:temp error:nil];return NO;}
 if(backup)*backup=bak;return YES;
}
static void rows(NSData*d,int s,int i,int depth,NSMutableArray*a){while(i>=0){int t=rd(d,item(s,i));[a addObject:@{@"index":@(i),@"depth":@(depth)}];if(container(t)){int ch=rd(d,item(s,i)+4);if(ch>=0)rows(d,s,ch,depth+1,a);}i=rd(d,item(s,i)+6);}}

static const NSUInteger MapStride=16834,MapHeader=450;
static NSArray*skillNames(void){return @[@"Melee Combat",@"Colt .45 Pistol",@"Walther P4 Pistol",@"MP-41 Submachine Gun",@"M-16 Rifle",@"AK-47 Assault Rifle",@"M-79 Grenade Launcher"];}
static BOOL setSkills(NSMutableData*d,int slot,NSArray*values){if(values.count!=7)return NO;for(NSNumber*v in values)if(v.intValue<0||v.intValue>3)return NO;for(int i=0;i<7;i++)wr(d,base(slot)+102+i*6,[values[i]intValue]);return YES;}
static BOOL setClock(NSMutableData*d,int slot,int day,int hour,int minute,int second){if(day<0||day>6||hour<0||hour>23||minute<0||minute>59||second<0||second>59)return NO;int64_t elapsed=day*86400+hour*3600+minute*60+second-(6*3600+13*60);if(elapsed<0)return NO;wr32(d,base(slot)+6,(uint32_t)(elapsed*60));return YES;}
static NSString*clockText(NSData*d,int slot){uint64_t sec=rd32(d,base(slot)+6)/60+(6*3600+13*60);NSArray*days=@[@"Sunday",@"Monday",@"Tuesday",@"Wednesday",@"Thursday",@"Friday",@"Saturday"];NSUInteger day=sec/86400;return [NSString stringWithFormat:@"%@ %02llu:%02llu:%02llu",day<7?days[day]:[NSString stringWithFormat:@"Day %lu",(unsigned long)day],(sec/3600)%24,(sec/60)%60,sec%60];}
static int sectorType(NSData*maps,int level,int x,int y){if(level<0||level>=maps.length/MapStride||x<0||x>31||y<0||y>31)return -1;const uint8_t*b=maps.bytes;return b[level*MapStride+MapHeader+(y*32+x)*16+14];}
static BOOL teleport(NSMutableData*d,int slot,NSData*maps,int level,int x,int y,NSString**why){int t=sectorType(maps,level,x,y);if(t!=1&&t!=9){if(why)*why=@"Choose an ordinary floor tile or a save rune.";return NO;}
 int idx=rd(d,0x500+slot*50+level*2);NSUInteger blocks=(d.length-(Header+Slots*Stride))/9112;if(idx<0||idx>=blocks){if(why)*why=@"This save does not contain the selected floor's state.";return NO;}
 wr(d,base(slot)+84,level);wr32(d,base(slot)+86,x*1024+512);wr32(d,base(slot)+90,y*1024+512);return YES;}
static NSTextField*panelLabel(NSWindow*w,NSString*text,int x,int y,int width){NSTextField*f=[NSTextField labelWithString:text];f.frame=NSMakeRect(x,y,width,26);[w.contentView addSubview:f];return f;}
static NSButton*panelButton(NSWindow*w,NSString*text,id target,SEL sel,int x,int y,int width){NSButton*b=[NSButton buttonWithTitle:text target:target action:sel];b.frame=NSMakeRect(x,y,width,30);[w.contentView addSubview:b];return b;}
@protocol PIDMapDelegate
-(void)mapSelected:(id)sender;
@end
@interface PIDMapView:NSView
@property NSData*maps;@property int level;@property int selectedX;@property int selectedY;@property int currentLevel;@property double currentX;@property double currentY;@property(weak) id<PIDMapDelegate>target;
@end
@implementation PIDMapView
-(BOOL)isFlipped{return YES;}
-(void)drawRect:(NSRect)dirty{[[NSColor colorWithWhite:0.14 alpha:1]setFill];NSRectFill(self.bounds);CGFloat cell=self.bounds.size.width/32;
 for(int y=0;y<32;y++)for(int x=0;x<32;x++){int t=sectorType(self.maps,self.level,x,y);if(t<=0)continue;NSColor*c=(t==9)?NSColor.systemOrangeColor:(t==3)?NSColor.systemGreenColor:(t==7)?NSColor.darkGrayColor:[NSColor colorWithWhite:0.8 alpha:1];[c setFill];NSRectFill(NSMakeRect(x*cell+.5,y*cell+.5,cell-1,cell-1));}
 if(self.currentLevel==self.level){[NSColor.systemRedColor setFill];NSRect p=NSMakeRect(self.currentX*cell-4,self.currentY*cell-4,8,8);[[NSBezierPath bezierPathWithOvalInRect:p]fill];}
 if(self.selectedX>=0){[NSColor.systemBlueColor setStroke];NSBezierPath*p=[NSBezierPath bezierPathWithRect:NSMakeRect(self.selectedX*cell+1,self.selectedY*cell+1,cell-2,cell-2)];p.lineWidth=3;[p stroke];}}
-(void)mouseDown:(NSEvent*)event{NSPoint p=[self convertPoint:event.locationInWindow fromView:nil];int x=floor(p.x/(self.bounds.size.width/32)),y=floor(p.y/(self.bounds.size.width/32));int type=sectorType(self.maps,self.level,x,y);if(type!=1&&type!=9){NSBeep();return;}self.selectedX=x;self.selectedY=y;self.needsDisplay=YES;[self.target mapSelected:self];}
@end
@interface Editor:NSObject<NSApplicationDelegate,NSTableViewDataSource,NSTableViewDelegate,NSComboBoxDelegate,PIDMapDelegate>
@property NSWindow*w;@property NSPopUpButton*slots;@property NSPopUpButton*types;@property NSTextField*health;@property NSTextField*maxHealth;@property NSTextField*reserve;@property NSTextField*status;@property NSTableView*table;@property NSMutableData*data;@property NSData*original;@property NSURL*source;@property NSArray*entries;@property int slot;@property NSURL*backupURL;@property NSURL*directoryAccessURL;@property NSWindow*quantityWindow;@property NSTableView*quantityTable;@property NSArray*quantityTypes;@property NSMutableDictionary*draftCounts;@property NSTextField*quantityStatus;@property NSWindow*progressWindow;@property NSArray*skillPopups;@property NSPopUpButton*clockDay;@property NSPopUpButton*clockHour;@property NSComboBox*clockMinute;@property NSComboBox*clockSecond;@property NSTextField*clockStatus;@property NSWindow*mapWindow;@property NSPopUpButton*mapLevel;@property PIDMapView*mapView;@property NSTextField*mapStatus;
@end
@implementation Editor
-(void)alert:(NSString*)s{NSAlert*a=[NSAlert new];a.messageText=s;[a runModal];}
-(NSTextField*)label:(NSString*)s x:(int)x y:(int)y w:(int)w{NSTextField*t=[NSTextField labelWithString:s];t.frame=NSMakeRect(x,y,w,24);[self.w.contentView addSubview:t];return t;}
-(NSTextField*)field:(int)x y:(int)y w:(int)w{NSTextField*t=[[NSTextField alloc]initWithFrame:NSMakeRect(x,y,w,26)];[self.w.contentView addSubview:t];return t;}
-(NSButton*)button:(NSString*)s action:(SEL)a x:(int)x y:(int)y w:(int)w{NSButton*b=[NSButton buttonWithTitle:s target:self action:a];b.frame=NSMakeRect(x,y,w,30);[self.w.contentView addSubview:b];return b;}
-(void)applicationDidFinishLaunching:(NSNotification*)n{
 self.w=[[NSWindow alloc]initWithContentRect:NSMakeRect(0,0,900,650) styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskMiniaturizable backing:NSBackingStoreBuffered defer:NO];self.w.title=@"Pathways Into Mischief — 0.7 beta";[self.w center];
 NSMenu*menu=[NSMenu new];NSMenuItem*app=[NSMenuItem new];[menu addItem:app];NSMenu*sub=[NSMenu new];NSMenuItem*about=[[NSMenuItem alloc]initWithTitle:@"About Pathways Into Mischief" action:@selector(orderFrontStandardAboutPanel:) keyEquivalent:@""];about.target=NSApp;[sub addItem:about];[sub addItem:NSMenuItem.separatorItem];NSMenuItem*quit=[[NSMenuItem alloc]initWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@"q"];[sub addItem:quit];app.submenu=sub;NSApp.mainMenu=menu;
 [self button:@"Open save file…" action:@selector(open:) x:20 y:600 w:210];[self button:@"Reopen last file" action:@selector(reopen:) x:235 y:600 w:170];self.status=[self label:@"Open a save file to begin." x:420 y:603 w:460];
 [self label:@"Game" x:20 y:561 w:55];self.slots=[[NSPopUpButton alloc]initWithFrame:NSMakeRect(75,559,350,30)];self.slots.target=self;self.slots.action=@selector(selectSlot:);[self.w.contentView addSubview:self.slots];[self button:@"Skills / time" action:@selector(progression:) x:445 y:559 w:210];[self button:@"Map / teleport" action:@selector(mapPanel:) x:660 y:559 w:220];
 [self label:@"Health" x:20 y:513 w:60];self.health=[self field:80 y:512 w:70];[self label:@"of" x:158 y:513 w:30];self.maxHealth=[self field:190 y:512 w:70];[self button:@"Apply" action:@selector(healthApply:) x:275 y:510 w:100];[self button:@"Health 1,000" action:@selector(immortal:) x:390 y:510 w:130];
 [self label:@"Inventory — indented items are inside a container or weapon" x:20 y:470 w:650];[self button:@"Remove" action:@selector(delete:) x:760 y:471 w:120];
 NSScrollView*scroll=[[NSScrollView alloc]initWithFrame:NSMakeRect(20,190,860,280)];scroll.hasVerticalScroller=YES;self.table=[[NSTableView alloc]initWithFrame:scroll.bounds];
 for(NSArray*c in @[@[@"object",@"Item",@480],@[@"detail",@"State / ammunition",@355]]){NSTableColumn*col=[[NSTableColumn alloc]initWithIdentifier:c[0]];col.title=c[1];col.width=[c[2]doubleValue];[self.table addTableColumn:col];}self.table.dataSource=self;self.table.delegate=self;self.table.rowHeight=25;scroll.documentView=self.table;[self.w.contentView addSubview:scroll];
 [self label:@"Ammunition in the selected item" x:20 y:150 w:250];self.reserve=[self field:280 y:150 w:80];[self button:@"Apply" action:@selector(ammoApply:) x:375 y:148 w:180];
 [self button:@"Items and quantities…" action:@selector(quantities:) x:20 y:100 w:265];[self button:@"Arsenal + 10,000" action:@selector(bundle:) x:300 y:100 w:210];[self button:@"Potion bundle" action:@selector(potions:) x:525 y:100 w:190];
 [self button:@"Discard unsaved changes" action:@selector(reset:) x:20 y:40 w:220];[self button:@"Restore original" action:@selector(restore:) x:255 y:40 w:190];[self button:@"Export…" action:@selector(export:) x:460 y:40 w:130];[self button:@"Save" action:@selector(save:) x:650 y:40 w:230];
 [self label:@"Experimental editor. Saving keeps a restorable backup." x:20 y:7 w:860];[self.w makeKeyAndOrderFront:nil];[NSApp activateIgnoringOtherApps:YES];
}
-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)sender{return YES;}

-(void)rememberURL{NSUserDefaults*u=NSUserDefaults.standardUserDefaults;[u setObject:self.source.path forKey:@"lastPath"];NSData*b=[self.source bookmarkDataWithOptions:0 includingResourceValuesForKeys:nil relativeToURL:nil error:nil];if(b)[u setObject:b forKey:@"lastBookmark"];}
-(void)open:(id)sender{NSOpenPanel*p=[NSOpenPanel openPanel];p.allowedFileTypes=@[@"pathways"];p.allowsMultipleSelection=NO;NSString*last=[NSUserDefaults.standardUserDefaults stringForKey:@"lastPath"];if(last)p.directoryURL=[NSURL fileURLWithPath:last.stringByDeletingLastPathComponent];if([p runModal]==NSModalResponseOK)[self loadURL:p.URL];}
-(void)reopen:(id)sender{NSUserDefaults*u=NSUserDefaults.standardUserDefaults;NSData*b=[u dataForKey:@"lastBookmark"];BOOL stale=NO;NSURL*url=b?[NSURL URLByResolvingBookmarkData:b options:NSURLBookmarkResolutionWithoutUI relativeToURL:nil bookmarkDataIsStale:&stale error:nil]:nil;NSString*last=[u stringForKey:@"lastPath"];if(!url&&last)url=[NSURL fileURLWithPath:last];if(url)[self loadURL:url];else [self open:nil];}
-(void)loadURL:(NSURL*)url{[url startAccessingSecurityScopedResource];NSError*error=nil;NSData*d=[NSData dataWithContentsOfURL:url options:0 error:&error];if(!d){[self alert:[NSString stringWithFormat:@"Could not read the file. Use Open save file to select it again.\n%@",error.localizedDescription]];return;}
 if(d.length<Header+Slots*Stride||(d.length-(Header+Slots*Stride))%9112){[self alert:@"This file does not match the supported save format."];return;}
 NSMutableArray*valid=[NSMutableArray array];for(int ss=0;ss<10;ss++){NSString*n=slotName(d,ss);if(n.length){NSString*why;if(!graph(d,ss,0,&why)){[self alert:why];return;}[valid addObject:@(ss)];}}if(!valid.count){[self alert:@"No active saved games were found."];return;}
 self.original=d;self.data=[d mutableCopy];self.source=url;[self.slots removeAllItems];for(NSNumber*n in valid){int ss=n.intValue;[self.slots addItemWithTitle:[NSString stringWithFormat:@"%d — %@",ss+1,slotName(d,ss)]];self.slots.lastItem.representedObject=n;}
 NSString*backup=[NSUserDefaults.standardUserDefaults dictionaryForKey:@"originalBackups"][url.path];self.backupURL=backup?[NSURL fileURLWithPath:backup]:nil;
 [self rememberURL];self.status.stringValue=url.lastPathComponent;self.status.toolTip=url.path;[self selectSlot:nil];}
-(void)selectSlot:(id)sender{self.slot=[self.slots.selectedItem.representedObject intValue];[self refresh];}
-(void)refresh{if(!self.data)return;self.health.doubleValue=rd(self.data,base(self.slot)+96)/10.0;self.maxHealth.doubleValue=rd(self.data,base(self.slot)+98)/10.0;int root;NSString*why;if(!graph(self.data,self.slot,&root,&why)){[self alert:why];return;}NSMutableArray*a=[NSMutableArray array];rows(self.data,self.slot,root,0,a);self.entries=a;[self.table reloadData];self.reserve.stringValue=@"";if(self.table.selectedRow>=0&&self.table.selectedRow<self.entries.count)[self tableViewSelectionDidChange:[NSNotification notificationWithName:NSTableViewSelectionDidChangeNotification object:self.table]];}
-(NSInteger)numberOfRowsInTableView:(NSTableView*)t{return t==self.quantityTable?self.quantityTypes.count:self.entries.count;}
-(id)tableView:(NSTableView*)t objectValueForTableColumn:(NSTableColumn*)c row:(NSInteger)row{if(t==self.quantityTable){id type=self.quantityTypes[row];if([type isKindOfClass:NSString.class])return [c.identifier isEqual:@"name"]?type:@"";return [c.identifier isEqual:@"name"]?name([type intValue]):self.draftCounts[type];}NSDictionary*e=self.entries[row];int i=[e[@"index"]intValue],type=rd(self.data,item(self.slot,i)),state=rd(self.data,item(self.slot,i)+2),v=rd(self.data,item(self.slot,i)+4);
 if([c.identifier isEqual:@"object"]){return [[@"" stringByPaddingToLength:[e[@"depth"]unsignedIntegerValue]*5 withString:@" " startingAtIndex:0]stringByAppendingString:name(type)];}
 if(ammo(type))return [NSString stringWithFormat:@"%d rounds",v];if(container(type))return v==-1?@"Empty":@"Contains items";if(state)return @"In use / equipped";return @"";}
-(void)tableViewSelectionDidChange:(NSNotification*)n{if(n.object==self.quantityTable)return;NSInteger row=self.table.selectedRow;if(row<0)return;int i=[self.entries[row][@"index"]intValue],t=rd(self.data,item(self.slot,i));self.reserve.enabled=ammo(t);self.reserve.stringValue=ammo(t)?[NSString stringWithFormat:@"%d",rd(self.data,item(self.slot,i)+4)]:@"";}
-(void)healthApply:(id)sender{if(!self.data)return;double h=self.health.doubleValue,m=self.maxHealth.doubleValue;if(m<0.1||m>3276.7||h<0.1||h>m){[self alert:@"Health must be positive and no higher than its maximum (maximum 3,276.7)."];return;}wr(self.data,base(self.slot)+96,(int)lround(h*10));wr(self.data,base(self.slot)+98,(int)lround(m*10));[self refresh];self.status.stringValue=@"Health changed in the working copy. Save to update the file.";}
-(void)ammoApply:(id)sender{if(!self.data||self.table.selectedRow<0)return;int i=[self.entries[self.table.selectedRow][@"index"]intValue],t=rd(self.data,item(self.slot,i)),q=self.reserve.intValue;if(!ammo(t)){[self alert:@"Select a magazine or ammunition item (inside the weapon if loaded)."];return;}if(q<0||q>32767){[self alert:@"Ammunition must be between 0 and 32,767."];return;}wr(self.data,item(self.slot,i)+4,q);[self refresh];self.status.stringValue=@"Ammunition changed in the working copy. Save to update the file.";}
-(void)addItem:(id)sender{if(!self.data)return;NSString*why;int t=[self.types.selectedItem.representedObject intValue];if(!add(self.data,self.slot,t,&why)){[self alert:why];return;}[self refresh];self.status.stringValue=[NSString stringWithFormat:@"%@ added to the working copy.",name(t)];}
-(void)reset:(id)sender{if(!self.original)return;self.data=[self.original mutableCopy];[self refresh];self.status.stringValue=@"Unsaved changes discarded.";}


-(void)updateQuantityStatus{NSInteger total=0;for(NSNumber*k in self.draftCounts)total+=[self.draftCounts[k]integerValue];self.quantityStatus.stringValue=[NSString stringWithFormat:@"%ld / 256 slots requested — TOTAL quantity per item type.",(long)total];}
-(void)tableView:(NSTableView*)table setObjectValue:(id)value forTableColumn:(NSTableColumn*)column row:(NSInteger)row{if(table!=self.quantityTable||![column.identifier isEqual:@"count"])return;NSString*text=[[value description]stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];NSScanner*scan=[NSScanner scannerWithString:text];NSInteger n=0;if(![scan scanInteger:&n]||!scan.isAtEnd||n<0||n>256){[self alert:@"Enter an integer from 0 to 256."];[table reloadData];return;}self.draftCounts[self.quantityTypes[row]]=@(n);[self updateQuantityStatus];}

-(NSView*)tableView:(NSTableView*)table viewForTableColumn:(NSTableColumn*)column row:(NSInteger)row{
 if(table!=self.quantityTable){NSTextField*label=[NSTextField labelWithString:[[self tableView:table objectValueForTableColumn:column row:row]description]];label.frame=NSMakeRect(0,2,column.width,22);return label;}
 id entry=self.quantityTypes[row];BOOL group=[entry isKindOfClass:NSString.class];
 if(group){if(![column.identifier isEqual:@"name"])return [NSView new];NSTextField*label=[NSTextField labelWithString:entry];label.font=[NSFont boldSystemFontOfSize:13];label.textColor=NSColor.secondaryLabelColor;label.frame=NSMakeRect(0,5,column.width,23);return label;}
 NSNumber*type=entry;int n=[self.draftCounts[type]intValue];
 if([column.identifier isEqual:@"on"]){NSButton*box=[NSButton checkboxWithTitle:@"" target:self action:@selector(quantityCheck:)];box.tag=type.intValue;box.state=n>0?NSControlStateValueOn:NSControlStateValueOff;box.frame=NSMakeRect(5,4,25,24);return box;}
 if([column.identifier isEqual:@"name"]){NSTextField*label=[NSTextField labelWithString:name(type.intValue)];label.frame=NSMakeRect(0,5,column.width,23);label.toolTip=name(type.intValue);return label;}
 NSComboBox*combo=[[NSComboBox alloc]initWithFrame:NSMakeRect(2,2,column.width-8,27)];combo.editable=YES;combo.completes=NO;combo.usesDataSource=NO;combo.numberOfVisibleItems=12;[combo addItemsWithObjectValues:@[@0,@1,@2,@3,@4,@5,@6,@7,@8,@9,@10,@20,@50,@100,@200,@256]];combo.stringValue=[NSString stringWithFormat:@"%d",n];combo.tag=type.intValue;combo.delegate=self;combo.toolTip=@"Choose a quantity or type an integer.";return combo;
}
-(BOOL)tableView:(NSTableView*)table isGroupRow:(NSInteger)row{return NO;}
-(BOOL)tableView:(NSTableView*)table shouldSelectRow:(NSInteger)row{return !(table==self.quantityTable&&[self.quantityTypes[row]isKindOfClass:NSString.class]);}
-(CGFloat)tableView:(NSTableView*)table heightOfRow:(NSInteger)row{return table==self.quantityTable?32:25;}
-(void)quantityCheck:(NSButton*)box{NSNumber*t=@(box.tag);if(box.state==NSControlStateValueOn){if([self.draftCounts[t]intValue]<1)self.draftCounts[t]=@1;}else self.draftCounts[t]=@0;[self.quantityTable reloadData];[self updateQuantityStatus];}
-(void)quantityCombo:(NSComboBox*)combo selected:(BOOL)selected{
 NSString*text=(selected&&combo.indexOfSelectedItem>=0)?[[combo objectValueOfSelectedItem]description]:combo.stringValue;
 NSScanner*scanner=[NSScanner scannerWithString:[text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]];NSInteger n=0;
 if(![scanner scanInteger:&n]||!scanner.isAtEnd||n<0||n>256){[self alert:@"Enter an integer from 0 to 256."];combo.stringValue=[self.draftCounts[@(combo.tag)]description];return;}
 self.draftCounts[@(combo.tag)]=@(n);[self updateQuantityStatus];NSUInteger row=[self.quantityTypes indexOfObject:@(combo.tag)];if(row!=NSNotFound)[self.quantityTable reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
}
-(void)comboBoxSelectionDidChange:(NSNotification*)n{if(n.object==self.clockMinute||n.object==self.clockSecond)return;[self quantityCombo:n.object selected:YES];}
-(void)controlTextDidEndEditing:(NSNotification*)n{if(n.object==self.clockMinute||n.object==self.clockSecond)return;if([n.object isKindOfClass:NSComboBox.class])[self quantityCombo:n.object selected:NO];}
-(void)allCrystals:(id)sender{[self.quantityWindow makeFirstResponder:nil];crystalPreset(self.draftCounts);[self.quantityTable reloadData];[self updateQuantityStatus];}
-(void)quantities:(id)sender{if(!self.data)return;self.draftCounts=[counts(self.data,self.slot)mutableCopy];NSMutableArray*order=[NSMutableArray array];for(NSArray*g in groups()){[order addObject:g[0]];[order addObjectsFromArray:g[1]];}self.quantityTypes=order;
 self.quantityWindow=[[NSWindow alloc]initWithContentRect:NSMakeRect(0,0,730,700) styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];self.quantityWindow.title=@"Choose inventory items";[self.quantityWindow center];
 NSTextField*help=[NSTextField labelWithString:@"Tick to include one item. Choose a quantity from the list, or type your own."];help.frame=NSMakeRect(20,650,690,30);[self.quantityWindow.contentView addSubview:help];
 NSButton*crystals=[NSButton buttonWithTitle:@"All crystals — one of each" target:self action:@selector(allCrystals:)];crystals.frame=NSMakeRect(20,610,320,30);[self.quantityWindow.contentView addSubview:crystals];
 NSScrollView*scroll=[[NSScrollView alloc]initWithFrame:NSMakeRect(20,105,690,495)];scroll.hasVerticalScroller=YES;self.quantityTable=[[NSTableView alloc]initWithFrame:scroll.bounds];self.quantityTable.rowHeight=32;
 for(NSArray*spec in @[@[@"on",@"",@35],@[@"name",@"Item",@435],@[@"count",@"Total quantity",@190]]){NSTableColumn*col=[[NSTableColumn alloc]initWithIdentifier:spec[0]];col.title=spec[1];col.width=[spec[2]doubleValue];col.editable=NO;[self.quantityTable addTableColumn:col];}
 self.quantityTable.dataSource=self;self.quantityTable.delegate=self;scroll.documentView=self.quantityTable;[self.quantityWindow.contentView addSubview:scroll];
 self.quantityStatus=[NSTextField labelWithString:@""];self.quantityStatus.frame=NSMakeRect(20,67,690,25);[self.quantityWindow.contentView addSubview:self.quantityStatus];[self updateQuantityStatus];
 NSButton*cancel=[NSButton buttonWithTitle:@"Cancel" target:self action:@selector(cancelQuantities:)];cancel.frame=NSMakeRect(20,20,120,30);[self.quantityWindow.contentView addSubview:cancel];NSButton*apply=[NSButton buttonWithTitle:@"Apply quantities" target:self action:@selector(applyQuantities:)];apply.frame=NSMakeRect(470,20,240,30);[self.quantityWindow.contentView addSubview:apply];
 [self.quantityWindow makeKeyAndOrderFront:nil];[NSApp runModalForWindow:self.quantityWindow];[self.quantityWindow orderOut:nil];self.quantityTable=nil;self.quantityWindow=nil;self.draftCounts=nil;
}
-(void)cancelQuantities:(id)sender{[self.quantityWindow endEditingFor:nil];[NSApp stopModal];}
-(void)applyQuantities:(id)sender{[self.quantityWindow makeFirstResponder:nil];NSString*why;if(!setCounts(self.data,self.slot,self.draftCounts,&why)){[self alert:why];return;}[self refresh];self.status.stringValue=[NSString stringWithFormat:@"Quantities applied — %lu items. Save to update the game file.",(unsigned long)self.entries.count];[NSApp stopModal];}

-(void)refreshClockControls{uint64_t sec=rd32(self.data,base(self.slot)+6)/60+22380;[self.clockDay selectItemAtIndex:MIN(sec/86400,6)];[self.clockHour selectItemAtIndex:(sec/3600)%24];self.clockMinute.stringValue=[NSString stringWithFormat:@"%llu",(sec/60)%60];self.clockSecond.stringValue=[NSString stringWithFormat:@"%llu",sec%60];self.clockStatus.stringValue=clockText(self.data,self.slot);}
-(void)progression:(id)sender{if(!self.data)return;self.progressWindow=[[NSWindow alloc]initWithContentRect:NSMakeRect(0,0,650,650) styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];self.progressWindow.title=@"Skills and time";[self.progressWindow center];panelLabel(self.progressWindow,@"Weapon proficiencies",20,607,600);NSMutableArray*popups=[NSMutableArray array];
 for(int i=0;i<7;i++){int y=565-i*38;panelLabel(self.progressWindow,skillNames()[i],20,y,260);NSPopUpButton*b=[[NSPopUpButton alloc]initWithFrame:NSMakeRect(295,y,330,29)];[b addItemsWithTitles:@[@"Unlearned (hidden)",@"Beginner",@"Novice",@"Expert"]];int rank=rd(self.data,base(self.slot)+102+i*6);[b selectItemAtIndex:MAX(0,MIN(rank,3))];[self.progressWindow.contentView addSubview:b];[popups addObject:b];}self.skillPopups=popups;
 panelButton(self.progressWindow,@"All Expert",self,@selector(allExpert:),20,290,160);panelButton(self.progressWindow,@"Apply skills",self,@selector(applySkills:),370,290,255);
 panelLabel(self.progressWindow,@"Game clock — starts Sunday at 06:13",20,245,610);self.clockDay=[[NSPopUpButton alloc]initWithFrame:NSMakeRect(20,200,160,29)];[self.clockDay addItemsWithTitles:@[@"Sunday",@"Monday",@"Tuesday",@"Wednesday",@"Thursday",@"Friday",@"Saturday"]];[self.progressWindow.contentView addSubview:self.clockDay];self.clockHour=[[NSPopUpButton alloc]initWithFrame:NSMakeRect(190,200,85,29)];for(int h=0;h<24;h++)[self.clockHour addItemWithTitle:[NSString stringWithFormat:@"%02d h",h]];[self.progressWindow.contentView addSubview:self.clockHour];
 NSMutableArray*small=[NSMutableArray array];for(int i=0;i<2;i++){NSComboBox*b=[[NSComboBox alloc]initWithFrame:NSMakeRect(285+i*85,200,75,28)];for(int v=0;v<60;v+=5)[b addItemWithObjectValue:@(v)];b.editable=YES;b.toolTip=i?@"Seconds":@"Minutes";[self.progressWindow.contentView addSubview:b];[small addObject:b];}self.clockMinute=small[0];self.clockSecond=small[1];
 panelButton(self.progressWindow,@"Apply time",self,@selector(applyClock:),465,198,160);panelButton(self.progressWindow,@"Reset to start",self,@selector(resetClock:),20,150,180);panelButton(self.progressWindow,@"Rewind 1 hour",self,@selector(rewindHour:),210,150,180);panelButton(self.progressWindow,@"Rewind 24 hours",self,@selector(rewindDay:),400,150,225);
 self.clockStatus=panelLabel(self.progressWindow,@"",20,103,605);panelLabel(self.progressWindow,@"Apply changes the working copy; Save writes the file.",20,65,610);panelButton(self.progressWindow,@"Close",self,@selector(closeProgress:),490,20,135);[self refreshClockControls];[self.progressWindow makeKeyAndOrderFront:nil];[NSApp runModalForWindow:self.progressWindow];[self.progressWindow orderOut:nil];self.progressWindow=nil;}
-(void)closeProgress:(id)sender{[NSApp stopModal];}
-(void)applySkills:(id)sender{NSMutableArray*a=[NSMutableArray array];for(NSPopUpButton*p in self.skillPopups)[a addObject:@(p.indexOfSelectedItem)];if(!setSkills(self.data,self.slot,a)){[self alert:@"Invalid proficiency rank."];return;}self.status.stringValue=@"Skills applied. Save to update the game file.";}
-(void)allExpert:(id)sender{for(NSPopUpButton*p in self.skillPopups)[p selectItemAtIndex:3];[self applySkills:nil];}
-(void)applyClock:(id)sender{[self.progressWindow makeFirstResponder:nil];NSScanner*a=[NSScanner scannerWithString:self.clockMinute.stringValue],*b=[NSScanner scannerWithString:self.clockSecond.stringValue];NSInteger m=0,ss=0;if(![a scanInteger:&m]||!a.isAtEnd||![b scanInteger:&ss]||!b.isAtEnd||!setClock(self.data,self.slot,(int)self.clockDay.indexOfSelectedItem,(int)self.clockHour.indexOfSelectedItem,(int)m,(int)ss)){[self alert:@"Choose a time on or after Sunday 06:13, with minutes and seconds from 0 to 59."];return;}[self refreshClockControls];self.status.stringValue=@"Time applied. Save to update the game file.";}
-(void)resetClock:(id)sender{wr32(self.data,base(self.slot)+6,0);[self refreshClockControls];self.status.stringValue=@"Clock reset to the beginning. Save to update the game file.";}
-(void)rewind:(uint32_t)ticks{uint32_t now=rd32(self.data,base(self.slot)+6);wr32(self.data,base(self.slot)+6,now>ticks?now-ticks:0);[self refreshClockControls];self.status.stringValue=@"Clock moved back. Save to update the game file.";}
-(void)rewindHour:(id)sender{[self rewind:216000];}
-(void)rewindDay:(id)sender{[self rewind:5184000];}
-(NSData*)gameMaps{NSURL*app=[NSWorkspace.sharedWorkspace URLForApplicationWithBundleIdentifier:@"com.manuptimestudios.pathwaysintodarkness"];if(!app)app=[NSURL fileURLWithPath:@"/Applications/Pathways Into Darkness.app"];return [NSData dataWithContentsOfURL:[app URLByAppendingPathComponent:@"Contents/Resources/Maps"]];}
-(void)mapPanel:(id)sender{if(!self.data)return;NSData*maps=[self gameMaps];if(maps.length!=25*MapStride){[self alert:@"Could not read the 25 maps from the installed Pathways Into Darkness application."];return;}
 self.mapWindow=[[NSWindow alloc]initWithContentRect:NSMakeRect(0,0,900,650) styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];self.mapWindow.title=@"Map and teleport — experimental";[self.mapWindow center];panelLabel(self.mapWindow,@"Choose a floor, then click a floor tile.",20,605,860);
 self.mapView=[[PIDMapView alloc]initWithFrame:NSMakeRect(20,80,512,512)];self.mapView.maps=maps;self.mapView.target=self;self.mapView.currentLevel=rd(self.data,base(self.slot)+84);self.mapView.currentX=rd32(self.data,base(self.slot)+86)/1024.;self.mapView.currentY=rd32(self.data,base(self.slot)+90)/1024.;self.mapView.selectedX=-1;self.mapView.selectedY=-1;[self.mapWindow.contentView addSubview:self.mapView];
 self.mapLevel=[[NSPopUpButton alloc]initWithFrame:NSMakeRect(550,550,330,32)];const uint8_t*bytes=maps.bytes;for(int i=0;i<25;i++){NSUInteger off=i*MapStride;NSString*n=[[NSString alloc]initWithBytes:bytes+off+1 length:MIN(bytes[off],127) encoding:NSMacOSRomanStringEncoding];[self.mapLevel addItemWithTitle:[NSString stringWithFormat:@"%d — %@",i,n]];}[self.mapLevel selectItemAtIndex:MAX(0,MIN(self.mapView.currentLevel,24))];self.mapLevel.target=self;self.mapLevel.action=@selector(changeMap:);[self.mapWindow.contentView addSubview:self.mapLevel];[self changeMap:nil];
 panelLabel(self.mapWindow,@"Red: current position",550,490,330);panelLabel(self.mapWindow,@"Blue: selected destination",550,455,330);panelLabel(self.mapWindow,@"Orange: save rune",550,420,330);panelLabel(self.mapWindow,@"Green: passage to another floor",550,385,330);self.mapStatus=panelLabel(self.mapWindow,@"Choose a floor tile.",550,315,330);panelButton(self.mapWindow,@"Apply teleport",self,@selector(applyTeleport:),550,240,330);panelLabel(self.mapWindow,@"Then click Save in the main window.",550,160,330);panelButton(self.mapWindow,@"Close",self,@selector(closeMap:),735,20,145);[self.mapWindow makeKeyAndOrderFront:nil];[NSApp runModalForWindow:self.mapWindow];[self.mapWindow orderOut:nil];self.mapWindow=nil;}
-(void)changeMap:(id)sender{self.mapView.level=(int)self.mapLevel.indexOfSelectedItem;self.mapView.selectedX=-1;self.mapView.selectedY=-1;self.mapView.needsDisplay=YES;self.mapStatus.stringValue=@"Choose a floor tile.";}
-(void)mapSelected:(id)sender{self.mapStatus.stringValue=[NSString stringWithFormat:@"Destination: tile %d, %d",self.mapView.selectedX,self.mapView.selectedY];}
-(void)applyTeleport:(id)sender{NSString*why;if(!teleport(self.data,self.slot,self.mapView.maps,self.mapView.level,self.mapView.selectedX,self.mapView.selectedY,&why)){[self alert:why];return;}self.mapView.currentLevel=self.mapView.level;self.mapView.currentX=self.mapView.selectedX+.5;self.mapView.currentY=self.mapView.selectedY+.5;self.mapView.needsDisplay=YES;self.status.stringValue=@"Teleport applied. Save, then load the saved game.";self.mapStatus.stringValue=@"Destination applied to the working copy.";}
-(void)closeMap:(id)sender{[NSApp stopModal];}
-(void)immortal:(id)sender{if(!self.data)return;wr(self.data,base(self.slot)+96,10000);wr(self.data,base(self.slot)+98,10000);[self refresh];self.status.stringValue=@"Health set to 1,000 / 1,000. Save to update the game file.";}
-(void)delete:(id)sender{if(!self.data||self.table.selectedRow<0)return;int i=[self.entries[self.table.selectedRow][@"index"]intValue];NSMutableData*copy=[self.data mutableCopy];NSString*why;if(!removeItem(copy,self.slot,i,&why)){[self alert:why];return;}self.data=copy;[self refresh];self.status.stringValue=@"Item removed; its contents were preserved.";}
-(void)bundle:(id)sender{if(!self.data)return;NSString*why;if(!arsenal(self.data,self.slot,&why)){[self alert:why];return;}[self refresh];self.status.stringValue=@"Weapons added; all magazines refilled to 10,000.";}
-(void)potions:(id)sender{if(!self.data)return;NSMutableData*copy=[self.data mutableCopy];NSString*why;for(int t=18;t<=21;t++)for(int n=0;n<10;n++)if(!add(copy,self.slot,t,&why)){[self alert:why];return;}self.data=copy;[self refresh];self.status.stringValue=@"Added 10 potions of each colour.";}

-(BOOL)authorizeDirectory{
 NSURL*expected=self.source.URLByDeletingLastPathComponent;NSString*path=expected.URLByResolvingSymlinksInPath.path;
 if([self.directoryAccessURL.URLByResolvingSymlinksInPath.path isEqual:path])return YES;
 NSDictionary*bookmarks=[NSUserDefaults.standardUserDefaults dictionaryForKey:@"directoryBookmarks"];
 NSData*b=bookmarks[path];BOOL stale=NO;
 if(b){NSURL*u=[NSURL URLByResolvingBookmarkData:b options:NSURLBookmarkResolutionWithSecurityScope|NSURLBookmarkResolutionWithoutUI relativeToURL:nil bookmarkDataIsStale:&stale error:nil];
  if(!u)u=[NSURL URLByResolvingBookmarkData:b options:NSURLBookmarkResolutionWithoutUI relativeToURL:nil bookmarkDataIsStale:&stale error:nil];
  if(u&&!stale&&[u.URLByResolvingSymlinksInPath.path isEqual:path]){[u startAccessingSecurityScopedResource];self.directoryAccessURL=u;return YES;}}
 NSOpenPanel*panel=[NSOpenPanel openPanel];panel.canChooseFiles=NO;panel.canChooseDirectories=YES;panel.allowsMultipleSelection=NO;panel.canCreateDirectories=NO;panel.directoryURL=expected;panel.prompt=@"Allow this folder";panel.message=@"Select the folder containing Saved Games.pathways. macOS must allow this app to create temporary files and restorable backups there.";
 if([panel runModal]!=NSModalResponseOK)return NO;
 NSURL*u=panel.URL;if(![u.URLByResolvingSymlinksInPath.path isEqual:path]){[self alert:[NSString stringWithFormat:@"Select the folder containing the open file:\n%@",expected.path]];return NO;}
 [u startAccessingSecurityScopedResource];self.directoryAccessURL=u;
 NSData*data=[u bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:nil relativeToURL:nil error:nil];if(!data)data=[u bookmarkDataWithOptions:0 includingResourceValuesForKeys:nil relativeToURL:nil error:nil];
 if(data){NSMutableDictionary*m=[bookmarks mutableCopy]?:[NSMutableDictionary dictionary];m[path]=data;[NSUserDefaults.standardUserDefaults setObject:m forKey:@"directoryBookmarks"];}
 return YES;
}
-(void)forgetDirectoryAuthorization{
 NSString*path=self.source.URLByDeletingLastPathComponent.URLByResolvingSymlinksInPath.path;NSMutableDictionary*m=[[NSUserDefaults.standardUserDefaults dictionaryForKey:@"directoryBookmarks"]mutableCopy];[m removeObjectForKey:path];if(m)[NSUserDefaults.standardUserDefaults setObject:m forKey:@"directoryBookmarks"];[self.directoryAccessURL stopAccessingSecurityScopedResource];self.directoryAccessURL=nil;
}
-(BOOL)readyToWrite{if(!self.data)return NO;for(int ss=0;ss<10;ss++)if(slotName(self.data,ss).length){NSString*why;if(!graph(self.data,ss,0,&why)){[self alert:why];return NO;}}if([NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.manuptimestudios.pathwaysintodarkness"].count){[self alert:@"Quit Pathways Into Darkness before saving or restoring."];return NO;}return YES;}
-(void)save:(id)sender{if(![self readyToWrite]||![self authorizeDirectory])return;NSError*error=nil;NSURL*bak=nil;if(!saveReplacing(self.source,self.original,self.data,&bak,&error)){[self forgetDirectoryAuthorization];[self alert:[error.localizedDescription stringByAppendingString:@"\nOn your next save, select the folder again to grant access."]];return;}
 if(!self.backupURL||![NSFileManager.defaultManager fileExistsAtPath:self.backupURL.path]){self.backupURL=bak;NSMutableDictionary*m=[[NSUserDefaults.standardUserDefaults dictionaryForKey:@"originalBackups"]mutableCopy]?:[NSMutableDictionary dictionary];m[self.source.path]=bak.path;[NSUserDefaults.standardUserDefaults setObject:m forKey:@"originalBackups"];}
 self.original=[self.data copy];[self rememberURL];NSData*check=[NSData dataWithContentsOfURL:self.source];if(![check isEqual:self.data]){[self alert:@"The saved file does not match the working copy. Do not launch the game yet."];return;}self.status.stringValue=[NSString stringWithFormat:@"Saved — health %.1f / %.1f, %lu items.",rd(check,base(self.slot)+96)/10.,rd(check,base(self.slot)+98)/10.,(unsigned long)active(check,self.slot).count];}
-(void)restore:(id)sender{if(![self readyToWrite]||![self authorizeDirectory])return;if(!self.backupURL){[self alert:@"No original backup has been recorded for this file."];return;}NSError*error=nil;NSData*d=[NSData dataWithContentsOfURL:self.backupURL options:0 error:&error];if(!d){[self alert:error.localizedDescription];return;}NSURL*bak=nil;if(!saveReplacing(self.source,self.original,d,&bak,&error)){[self forgetDirectoryAuthorization];[self alert:error.localizedDescription];return;}NSURL*url=self.source;[self loadURL:url];self.status.stringValue=@"Original restored; the replaced version was also preserved.";}
-(void)export:(id)sender{if(!self.data)return;for(int s=0;s<10;s++)if(slotName(self.data,s).length){NSString*why;if(!graph(self.data,s,0,&why)){[self alert:why];return;}}
 NSSavePanel*p=[NSSavePanel savePanel];p.allowedFileTypes=@[@"pathways"];p.nameFieldStringValue=@"Saved Games — edited.pathways";if([p runModal]!=NSModalResponseOK)return;if([p.URL.URLByResolvingSymlinksInPath.path isEqual:self.source.URLByResolvingSymlinksInPath.path]){[self alert:@"Use Save to replace the open file with an automatic backup."];return;}
 NSError*err=nil;NSString*backup=[p.URL.path.stringByDeletingPathExtension stringByAppendingFormat:@" — original-%@.pathways",NSUUID.UUID.UUIDString];if(![self.original writeToFile:backup options:NSDataWritingWithoutOverwriting error:&err]||![self.data writeToURL:p.URL options:NSDataWritingAtomic error:&err]){[self alert:err.localizedDescription];return;}self.status.stringValue=@"Edited copy exported, with an original backup alongside it.";[self alert:@"Exported under a different name. Use Save to update the open file directly."];}
@end
static void initNames(void){names=@{
@0:@"Map",@1:@"Watch",@2:@"Flashlight",@3:@"Goggles",@4:@"Gas mask",@6:@"Canvas bag",@8:@"Cedar box",@9:@"Velvet bag",@10:@"Lead box",@12:@"Glass vial",@14:@"Red cloak",@16:@"Nuclear device",@17:@"Beacon",@18:@"Blue potion",@19:@"Red potion",@20:@"Brown potion",@21:@"Violet potion",@22:@"Mein Kampf",@23:@"Propaganda",@24:@"Easter egg",@25:@"Broken M16",@26:@"Broken AK47",@27:@"Broken MP41",@28:@"Broken P4",@29:@"Ruby ring",@30:@"Amethyst ring",@31:@"Necklace",@32:@"Gemstone",@33:@"Alien pipes",@34:@"Silver key",@35:@"Bowl",@36:@"Gold key",@37:@"Gold ingot",@38:@"Sapphire",@40:@"Emerald",@41:@"Pearl",@45:@"Knife",@46:@"Walther P4",@47:@"Colt .45",@48:@"MP41",@49:@"AK47",@50:@"40mm launcher",@51:@"P4 magazine",@52:@"MP41 magazine",@53:@"AK47 ammunition",@54:@"AK47 HE ammunition",@55:@"AK47 sabot ammunition",@56:@"M16 ammunition",@57:@"Colt magazine",@58:@"40mm HE",@59:@"40mm fragmentation",@60:@"40mm projectiles",@61:@"Silver medal",@62:@"Note",@63:@"Bungie Propaganda (promotional note)",@64:@"Yellow crystal",@65:@"Blue crystal",@66:@"Orange crystal",@68:@"Violet crystal",@69:@"Green crystal",@70:@"Black crystal"};}

// Tests use generated data only. No personal save files or game resources ship here.
static int runSelfTests(void){
 #define CHECK(condition) do { if(!(condition)){fprintf(stderr,"Self-test failed at line %d: %s\n",__LINE__,#condition);return 1;} } while(0)
 const int slot=0;NSMutableData*d=[NSMutableData dataWithLength:Header+Slots*Stride+25*9112];uint8_t*bytes=d.mutableBytes;bytes[0]=4;memcpy(bytes+1,"Test",4);
 wr(d,base(slot),12);wr(d,base(slot)+2,Stride);wr(d,base(slot)+4,2);wr(d,base(slot)+96,60);wr(d,base(slot)+98,60);
 for(int i=0;i<25;i++)wr(d,0x500+i*2,i);for(int i=0;i<256;i++)wr(d,item(slot,i),-1);
 int initial[][4]={{0,0,0,1},{1,1,0,2},{2,1,2880,3},{6,0,-1,4},{45,0,0,5},{47,0,6,-1},{57,0,0,-1}};
 for(int i=0;i<7;i++)for(int j=0;j<4;j++)wr(d,item(slot,i)+j*2,initial[i][j]);NSString*why=nil;CHECK(graph(d,slot,0,&why));CHECK(active(d,slot).count==7);
 NSMutableData*all=[d mutableCopy];for(NSNumber*t in names)CHECK(add(all,slot,t.intValue,&why));CHECK(graph(all,slot,0,&why));CHECK(all.length==d.length);
 NSMutableSet*catalog=[NSMutableSet set];for(NSArray*g in groups())for(NSNumber*t in g[1]){CHECK(names[t]&&![catalog containsObject:t]);[catalog addObject:t];}CHECK(catalog.count==names.count);
 NSMutableData*bulk=[d mutableCopy];NSMutableDictionary*request=[counts(bulk,slot)mutableCopy];request[@70]=@200;request[@3]=@1;for(int t=18;t<=21;t++)request[@(t)]=@3;
 CHECK(setCounts(bulk,slot,request,&why));CHECK([counts(bulk,slot)[@70]intValue]==200);CHECK([counts(bulk,slot)[@3]intValue]==1);NSUInteger n=active(bulk,slot).count;CHECK(setCounts(bulk,slot,request,&why)&&active(bulk,slot).count==n);
 NSData*snapshot=[bulk copy];request[@70]=@256;CHECK(!setCounts(bulk,slot,request,&why)&&[bulk isEqual:snapshot]);request[@70]=@0;CHECK(setCounts(bulk,slot,request,&why)&&[counts(bulk,slot)[@70]intValue]==0);
 NSMutableDictionary*crystals=[counts(d,slot)mutableCopy];crystalPreset(crystals);NSDictionary*once=[crystals copy];crystalPreset(crystals);CHECK([once isEqual:crystals]);for(NSNumber*t in @[@64,@65,@66,@68,@69,@70])CHECK([crystals[t]intValue]==1);
 NSMutableData*kit=[d mutableCopy];CHECK(arsenal(kit,slot,&why));n=active(kit,slot).count;CHECK(arsenal(kit,slot,&why)&&active(kit,slot).count==n);for(int t=51;t<=60;t++){int i=findType(kit,slot,t);CHECK(i>=0&&rd(kit,item(slot,i)+4)==10000);}for(int t=46;t<=50;t++)CHECK(rd(kit,item(slot,findType(kit,slot,t))+4)>=0);
 NSMutableData*removed=[kit mutableCopy];int gun=findType(removed,slot,47),bag=findType(removed,slot,6);n=active(removed,slot).count;CHECK(removeItem(removed,slot,bag,&why));CHECK(active(removed,slot).count==n-1&&findType(removed,slot,47)==gun&&graph(removed,slot,0,&why));snapshot=[removed copy];CHECK(!removeItem(removed,slot,1,&why)&&[removed isEqual:snapshot]);
 CHECK(setSkills(kit,slot,@[@3,@3,@3,@3,@3,@3,@3]));for(int i=0;i<7;i++)CHECK(rd(kit,base(slot)+102+i*6)==3);snapshot=[kit copy];CHECK(!setSkills(kit,slot,@[@4,@3,@3,@3,@3,@3,@3])&&[kit isEqual:snapshot]);
 CHECK(setClock(kit,slot,0,6,13,0)&&rd32(kit,base(slot)+6)==0);CHECK(setClock(kit,slot,1,6,13,0)&&rd32(kit,base(slot)+6)==5184000);snapshot=[kit copy];CHECK(!setClock(kit,slot,0,6,12,59)&&[kit isEqual:snapshot]);
 NSMutableData*maps=[NSMutableData dataWithLength:25*MapStride];uint8_t*mapBytes=maps.mutableBytes;for(int level=0;level<25;level++){mapBytes[level*MapStride+MapHeader+(2*32+2)*16+14]=1;int angle=rd(kit,base(slot)+94);CHECK(teleport(kit,slot,maps,level,2,2,&why));CHECK(rd(kit,base(slot)+84)==level&&rd32(kit,base(slot)+86)==2560&&rd32(kit,base(slot)+90)==2560&&rd(kit,base(slot)+94)==angle&&graph(kit,slot,0,&why));}snapshot=[kit copy];CHECK(!teleport(kit,slot,maps,0,0,0,&why)&&[kit isEqual:snapshot]);
 NSString*dir=[NSTemporaryDirectory()stringByAppendingPathComponent:NSUUID.UUID.UUIDString];CHECK([NSFileManager.defaultManager createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil]);NSURL*url=[NSURL fileURLWithPath:[dir stringByAppendingPathComponent:@"Saved Games.pathways"]];CHECK([d writeToURL:url atomically:YES]);NSURL*backup=nil;NSError*error=nil;
 CHECK(saveReplacing(url,d,kit,&backup,&error));CHECK([[NSData dataWithContentsOfURL:backup]isEqual:d]&&[[NSData dataWithContentsOfURL:url]isEqual:kit]);NSData*foreign=[@"changed externally" dataUsingEncoding:NSUTF8StringEncoding];CHECK([foreign writeToURL:url atomically:YES]);CHECK(!saveReplacing(url,kit,d,0,&error)&&[[NSData dataWithContentsOfURL:url]isEqual:foreign]);CHECK([kit writeToURL:url atomically:YES]);CHECK(saveReplacing(url,kit,[NSData dataWithContentsOfURL:backup],0,&error));CHECK([[NSData dataWithContentsOfURL:url]isEqual:d]);[NSFileManager.defaultManager removeItemAtPath:dir error:nil];
 puts("All synthetic save tests passed: inventory, quantities, containers, bundles, skills, clock, teleport, backup, restore and concurrent-change detection.");return 0;
 #undef CHECK
}
int main(int argc,const char**argv){@autoreleasepool{initNames();if(argc==2&&strcmp(argv[1],"--self-test")==0)return runSelfTests();if(argc==3&&strcmp(argv[1],"--inspect")==0){NSData*d=[NSData dataWithContentsOfFile:@(argv[2])];if(!d||d.length<Header+Slots*Stride||(d.length-(Header+Slots*Stride))%9112)return 2;int live=0;for(int slot=0;slot<10;slot++)if(slotName(d,slot).length){NSString*why;if(!graph(d,slot,0,&why)){fprintf(stderr,"%s\n",why.UTF8String);return 3;}printf("Slot %d: %s, health %.1f/%.1f, %lu items, %s\n",slot+1,slotName(d,slot).UTF8String,rd(d,base(slot)+96)/10.,rd(d,base(slot)+98)/10.,(unsigned long)active(d,slot).count,clockText(d,slot).UTF8String);live++;}return live?0:4;}NSApplication*a=[NSApplication sharedApplication];a.activationPolicy=NSApplicationActivationPolicyRegular;Editor*e=[Editor new];a.delegate=e;[a run];}return 0;}

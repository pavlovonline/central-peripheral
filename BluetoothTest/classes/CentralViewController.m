//
//  CentralViewController.m
//  BluetoothTest
//
//  Created by Anton Pavlov on 3/25/14.
//  Copyright (c) 2014 Anton Pavlov. All rights reserved.
//

#import "CentralViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface CentralViewController () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *discoveredPeripheral;
@property (nonatomic, strong) NSMutableData *data;

@end

@implementation CentralViewController

- (id)init {
    self = [super init];

    if (self) {
        self.centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:nil];\
        self.data = [NSMutableData new];
    }
    return self;
}


#pragma mark - Lifecycle methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGFloat marginX = 50.0f;
    
    self.textView = [[UITextView alloc]initWithFrame:CGRectMake(marginX, (self.view.bounds.size.height / 4), (self.view.bounds.size.width - (marginX * 2)), (self.view.bounds.size.height / 4))];
    [self.view addSubview:self.textView];
}


- (void)viewWillDisappear:(BOOL)iAnimated {
    [self.centralManager stopScan];
    if (self.discoveredPeripheral && (self.discoveredPeripheral.state == CBPeripheralStateConnected)) {
        [self.centralManager cancelPeripheralConnection:self.discoveredPeripheral];
    }
    self.discoveredPeripheral = nil;
    [super viewWillDisappear:iAnimated];
}


#pragma mark - CBCentralManagerDelegate methods

- (void)centralManagerDidUpdateState:(CBCentralManager *)iCentral {
    if (iCentral.state == CBCentralManagerStatePoweredOn) {
        NSLog(@"CBCentralManager powered on");
        [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:kMainServiceUUID]] options:nil];
    }
}


- (void)centralManager:(CBCentralManager *)iCentral didDiscoverPeripheral:(CBPeripheral *)iPeripheral advertisementData:(NSDictionary *)iAdvertisementData RSSI:(NSNumber *)iRSSI {
    NSLog(@"discovered peripheral %@, advertisement data %@, rssi %@", iPeripheral, iAdvertisementData, iRSSI);    self.discoveredPeripheral = iPeripheral;
    self.discoveredPeripheral.delegate = self;
    [self.centralManager stopScan];
    [self.centralManager connectPeripheral:iPeripheral options:nil];
}


- (void)centralManager:(CBCentralManager *)iCentral didConnectPeripheral:(CBPeripheral *)iPeripheral {
    NSLog(@"connected to peripheral");
    [iPeripheral discoverServices:nil];
}


- (void)centralManager:(CBCentralManager *)iCentral didDisconnectPeripheral:(CBPeripheral *)iPeripheral error:(NSError *)iError {
    NSLog(@"disconnecting from peripheral");
    self.discoveredPeripheral = nil;
    
    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:kMainServiceUUID]] options:nil];
}


- (void)centralManager:(CBCentralManager *)iCentral didFailToConnectPeripheral:(CBPeripheral *)iPeripheral error:(NSError *)iError {
    NSLog(@"failed to connect to peripheral");
    [self cleanup];
}


#pragma mark - CBPeripheral delegate

- (void)peripheral:(CBPeripheral *)iPeripheral didDiscoverServices:(NSError *)iError {
    NSLog(@"did discover services %@", iPeripheral.services);

    for (CBService *aService in iPeripheral.services) {
        [iPeripheral discoverCharacteristics:nil forService:aService];
    }
}


- (void)peripheral:(CBPeripheral *)iPeripheral didDiscoverCharacteristicsForService:(CBService *)iService error:(NSError *)iError {
    NSLog(@"discovered characteristics %@ for service %@", iService.characteristics, iService);
    
    for (CBCharacteristic *aCharacteristic in iService.characteristics) {
        if ([aCharacteristic.UUID isEqual:[CBUUID UUIDWithString:kMainCharacteristicUUID]]) {
            [iPeripheral setNotifyValue:YES forCharacteristic:aCharacteristic];
            NSLog(@"set notify to yes");
        }
    }
}


- (void)peripheral:(CBPeripheral *)iPeripheral didUpdateValueForCharacteristic:(CBCharacteristic *)iCharacteristic error:(NSError *)iError {
    if (iError) {
        NSLog(@"%@", iError);
        return;
    }
    
    NSString *stringFromData = [[NSString alloc]initWithData:iCharacteristic.value encoding:NSUTF8StringEncoding];
    
    if ([stringFromData isEqualToString:@"EOM"]) {
        [self.textView setText:[[[NSString alloc]initWithData:self.data encoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"EOM" withString:@""]];
//        self.data = nil;
//        self.data = [NSMutableData new];
//        [iPeripheral setNotifyValue:NO forCharacteristic:iCharacteristic];
//        [self.centralManager cancelPeripheralConnection:iPeripheral];
    }
    
    [self.data appendData:iCharacteristic.value];
}


- (void)peripheral:(CBPeripheral *)iPeripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)iCharacteristic error:(NSError *)iError {
    if (![iCharacteristic isEqual:[CBUUID UUIDWithString:kMainCharacteristicUUID]]) {
        return;
    }
    
    if (iCharacteristic.isNotifying) {
        NSLog(@"notification began on %@", iCharacteristic);
    } else {
        //notification stopped
//        [self.centralManager cancelPeripheralConnection:iPeripheral];
    }
}


#pragma mark - Private Methods

- (void)cleanup {
    if (self.discoveredPeripheral.services != nil) {
        for (CBService *service in self.discoveredPeripheral.services) {
            for (CBCharacteristic *aCharacteristic in service.characteristics) {
                if ([aCharacteristic isEqual:[CBUUID UUIDWithString:kMainCharacteristicUUID]]) {
//                    if (aCharacteristic.isNotifying)
//                        [self.discoveredPeripheral setNotifyValue:NO forCharacteristic:aCharacteristic];
                }
            }
        }
    }
//    [self.centralManager cancelPeripheralConnection:self.discoveredPeripheral];
}


@end

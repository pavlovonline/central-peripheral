//
//  PeripheralViewController.m
//  BluetoothTest
//
//  Created by Anton Pavlov on 3/25/14.
//  Copyright (c) 2014 Anton Pavlov. All rights reserved.
//

#import "PeripheralViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface PeripheralViewController () <CBPeripheralManagerDelegate, UITextViewDelegate>

@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) CBMutableCharacteristic *transferCharacteristic;
@property (nonatomic, strong) NSData *dataToSend;
@property (nonatomic, assign) NSInteger sendDataIndex;
@property (nonatomic, strong) UITextView *textView;

@end

@implementation PeripheralViewController


- (id)init {
    self = [super init];
    
    if (self) {
        self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:NULL];
    }
    return self;
}


#pragma mark - Lifecycle methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGFloat marginX = 50.0f;
    
    self.textView = [[UITextView alloc]initWithFrame:CGRectMake(marginX, (self.view.bounds.size.height / 4), (self.view.bounds.size.width - (marginX * 2)), (self.view.bounds.size.height / 4))];
    [self.textView setBackgroundColor:[UIColor lightGrayColor]];
    self.textView.delegate = self;
    [self.view addSubview:self.textView];
}


#pragma mark - CBPeripheralManagerDelegate

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)iPeripheral {
    if (iPeripheral.state == CBPeripheralManagerStatePoweredOn) {
        NSLog(@"CBPeripheralManager powered on");
        [self setupService];
    }
}


- (void)peripheralManager:(CBPeripheralManager *)iPeripheral central:(CBCentral *)iCentral didSubscribeToCharacteristic:(CBCharacteristic *)iCharacteristic {
    self.dataToSend = [self.textView.text dataUsingEncoding:NSUTF8StringEncoding];
    self.sendDataIndex = 0;
    [self sendData];
}


- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)iPeripheral {
    [self sendData];
}


- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {
    NSLog(@"started advertising! %i, state %i", peripheral.isAdvertising, (int)peripheral.state);
}


- (void)peripheralManager:(CBPeripheralManager *)iPeripheral didAddService:(CBService *)iService error:(NSError *)iError {
    if (!iError) {
        NSLog(@"added service successfully %@", iService);
        [self.peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:kMainServiceUUID]]}];
    }
}

#pragma mark - Private Methods 

- (void) sendData {
    static BOOL sendingEOM = NO;
    
    if (sendingEOM) {
        BOOL didSend = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
        
        if (didSend) {
            sendingEOM = NO;
        }
        return;
    }
    
    if (self.sendDataIndex >= self.dataToSend.length) {
        // no data left, do nothing
        return;
    }
    
    BOOL didSend = YES;
    
    while (didSend) {
        //work out how big it should be
        NSInteger amountToSend = self.dataToSend.length - self.sendDataIndex;
        
        //can't be longer than 20 bytes
        if (amountToSend > 20) amountToSend = 20;
        
        NSData *chunk = [NSData dataWithBytes:(self.dataToSend.bytes + self.sendDataIndex) length:amountToSend];
        didSend = [self.peripheralManager updateValue:chunk forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
        
        if (!didSend) {
            return;
        }
        
        NSString *stringFromData = [[NSString alloc]initWithData:chunk encoding:NSUTF8StringEncoding];
        NSLog(@"sent %@", stringFromData);
        
        self.sendDataIndex += amountToSend;
        
        if (self.sendDataIndex >= self.dataToSend.length) {
            sendingEOM = YES;
            BOOL eomSent = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
            
            if (eomSent) {
                sendingEOM = NO;
                NSLog(@"sent eom");
            }
            
            return;
        }
    }
}


- (void)setupService {
    self.transferCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:kMainCharacteristicUUID] properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable];
    CBMutableService *transferService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:kMainServiceUUID] primary:YES];
    transferService.characteristics = @[self.transferCharacteristic];
    [self.peripheralManager addService:transferService];
}


#pragma mark - UITextViewDelegate methods

- (void)textViewDidChange:(UITextView *)textView {
    self.dataToSend = [self.textView.text dataUsingEncoding:NSUTF8StringEncoding];
    [self sendData];
}

@end

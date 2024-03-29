//
//  LZBLEPeripheral.m
//  LZMH
//
//  Created by 肖忠肯 on 2019/6/19.
//  Copyright © 2019 xmlzmh. All rights reserved.
//

#import "LZBLEPeripheral.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface LZService()

- (instancetype)initWithService:(CBUUID *)service writeCharacteristic:(CBUUID *)writeChar notifyCharacteristic:(CBUUID *)notifyCharacteristic;

- (NSArray *)allCharacters;

@end

@implementation LZService

- (instancetype)initWithService:(CBUUID *)service writeCharacteristic:(CBUUID *)writeChar notifyCharacteristic:(CBUUID *)notifyChar {
    self = [self init];
    if (self) {
        _service = service;
        _writeCharacteristic = writeChar;
        _notifyCharacteristic = notifyChar;
    }
    return self;
}

- (NSArray *)allCharacters {
    return @[self.writeCharacteristic, self.notifyCharacteristic];
}

@end


static NSString *const kOpenDoorService = @"FF00";
static NSString *const kOpenDoorServiceNotifyCharacter = @"FF01";
static NSString *const kOpenDoorServiceWriteCharacter = @"FF02";

#define UUID(X) [CBUUID UUIDWithString: X]
#define OPN_DOR_SERVICE UUID(kOpenDoorService)
#define OPN_DOR_SERVICE_NOTIFY_CHAR UUID(kOpenDoorServiceNotifyCharacter)
#define OPN_DOR_SERVICE_WRITE_CHAR UUID(kOpenDoorServiceWriteCharacter)

@interface LZBLEPeripheral ()


@property (nonatomic, strong) CBCharacteristic *writeChar;
@property (nonatomic, strong) CBCharacteristic *notifyChar;
@property (nonatomic, copy) void (^responseBlock)(NSData *reponse);

@end

@implementation LZBLEPeripheral

- (instancetype)init
{
    self = [super init];
    if (self) {
        LZService *mainService = [[LZService alloc] initWithService:OPN_DOR_SERVICE writeCharacteristic:OPN_DOR_SERVICE_WRITE_CHAR notifyCharacteristic:OPN_DOR_SERVICE_NOTIFY_CHAR];
        _serviceOfInterest = mainService;
    }
    return self;
}

- (instancetype)initWithMac:(NSString *)mac {
    self = [self init];
    if (self) {
        _MAC = mac;
    }
    return self;
}

- (void)writeData:(NSData *)data withResponseHandler:(void (^)(NSData *returnData))handler {
    self.responseBlock = handler;
    if (CBCharacteristicPropertyWriteWithoutResponse == self.writeChar.properties) {
        [self.cperipheral writeValue:data forCharacteristic:self.writeChar type:CBCharacteristicWriteWithoutResponse];
    } else if (CBCharacteristicPropertyWrite == self.writeChar.properties) {
        [self.cperipheral writeValue:data forCharacteristic:self.writeChar type:CBCharacteristicWriteWithResponse];
    }
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error {
    if (error) {
        
    }
    
    for (CBService *service in peripheral.services) {
        if ([service.UUID isEqual:self.serviceOfInterest.service]) {
            [peripheral discoverCharacteristics:[self.serviceOfInterest allCharacters] forService:service];
            break;
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error {
    
    if (error) {
        
    }
    
    if ([service.UUID isEqual:OPN_DOR_SERVICE]) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ([characteristic.UUID isEqual:OPN_DOR_SERVICE_NOTIFY_CHAR]) {
                self.notifyChar = characteristic;
            } else if ([characteristic.UUID isEqual:OPN_DOR_SERVICE_WRITE_CHAR]) {
                self.writeChar = characteristic;
            }
        }
    }
    
    if (self.notifyChar && self.writeChar) {
        [self peripheral:peripheral isReadyToReceiveDataWithWriteChar:self.writeChar andNotifyCharacter:self.notifyChar];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral isReadyToReceiveDataWithWriteChar:(CBCharacteristic *)writeCharacter andNotifyCharacter:(CBCharacteristic *)notifyChar {
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    if (error) {
        
        return;
    }
    
    self.responseBlock(characteristic.value);
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    
}

- (NSString *)description {
    return [NSString stringWithFormat:@"MAC: %@", self.MAC];
}



@end

//
//  BluetoothState.swift
//  uB1-SlideAdvance
//
//  Created by William LaFrance on 3/27/15.
//  Copyright (c) 2015 LS Research. All rights reserved.
//

import CoreBluetooth

enum BluetoothState {

    case Uninitialized

    case Discovering

    case Connecting(CBPeripheral)

    case InterrogatingServices(CBPeripheral)

    case InterrogatingCharacteristics(CBPeripheral,
        gpioService: CBService)

    case Connected(CBPeripheral,
        inputCharacteristic: CBCharacteristic,
        outputCharacteristic: CBCharacteristic)

}

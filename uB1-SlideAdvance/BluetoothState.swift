//
//  BluetoothState.swift
//  uB1-SlideAdvance
//
//  Created by William LaFrance on 3/27/15.
//  Copyright (c) 2015 LS Research. All rights reserved.
//

import CoreBluetooth

enum BluetoothState: CustomStringConvertible {

    case Uninitialized

    case Discovering

    case Connecting(CBPeripheral)

    case InterrogatingServices(CBPeripheral)

    case InterrogatingCharacteristics(CBPeripheral,
        gpioService: CBService)

    case Subscribing(CBPeripheral,
        inputCharacteristic: CBCharacteristic,
        outputCharacteristic: CBCharacteristic)

    case Connected(CBPeripheral,
        inputCharacteristic: CBCharacteristic,
        outputCharacteristic: CBCharacteristic)

    var description: String {
        switch self {
            case .Uninitialized:                return "Uninitialized"
            case .Discovering:                  return "Discovering"
            case .Connecting:                   return "Connecting"
            case .InterrogatingServices:        return "InterrogatingServices"
            case .InterrogatingCharacteristics: return "InterrogatingCharacteristics"
            case .Subscribing:                  return "Subscribing"
            case .Connected:                    return "Connected"
        }
    }

}

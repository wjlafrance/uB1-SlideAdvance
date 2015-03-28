//
//  BluetoothState.swift
//  uB1-SlideAdvance
//
//  Created by William LaFrance on 3/27/15.
//  Copyright (c) 2015 LS Research. All rights reserved.
//

import CoreBluetooth

enum BluetoothState : Printable {

    case Uninitialized

    case Discovering

    case Connecting(CBPeripheral)

    case InterrogatingServices(CBPeripheral)

    case InterrogatingCharacteristics(CBPeripheral,
        gpioService: CBService)

    case Connected(CBPeripheral,
        inputCharacteristic: CBCharacteristic,
        outputCharacteristic: CBCharacteristic)

    //MARK: Printable conformance
    var description: String {
        get {
            switch self {

                case .Uninitialized:
                    return ".Uninitialized"

                case .Discovering:
                    return ".Discovering"

                case let .Connecting(peripheral):
                    return ".Connecting (peripheral: \(peripheral))"

                case let .InterrogatingServices(peripheral):
                    return ".InterrogatingServices (peripheral: \(peripheral))"

                case let .InterrogatingCharacteristics(peripheral, service):
                    return ".InterrogatingCharacteristics (peripheral: \(peripheral), service: \(service))"

                case let .Connected(peripheral, inputCharacteristic, outputCharacteristic):
                    return ".Connected (peripheral: \(peripheral), inputCharacteristic: \(inputCharacteristic), outputCharacteristic: \(outputCharacteristic))"
            }
        }
    }

}

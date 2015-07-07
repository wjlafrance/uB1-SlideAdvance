//
//  BluetoothRemoteControl.swift
//  uB1-SlideAdvance
//
//  Created by William LaFrance on 3/27/15.
//  Copyright (c) 2015 LS Research. All rights reserved.
//

import Foundation
import CoreBluetooth

class BluetoothRemoteController : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    private let deviceName          = "TiWi-uB1"
    private let gpioServiceUuid     = CBUUID(string: "3347AAA0-FB94-11E2-A8E4-F23C91AEC05E")
    private let gpioInputStateUuid  = CBUUID(string: "3347AAA3-FB94-11E2-A8E4-F23C91AEC05E") // Read Notify
    private let gpioOutputStateUuid = CBUUID(string: "3347AAA4-FB94-11E2-A8E4-F23C91AEC05E") // Read Write

    private let centralManager: CBCentralManager = CBCentralManager(delegate: nil, queue: nil)

    private let controlledObject: RemoteControllable

    private var state: BluetoothState {
        willSet {
            switch state {
                case .Discovering:
                    centralManager.stopScan()

                default:
                    print("No action for leaving state")
            }
        }

        didSet {
            print("BluetoothRemoteController transitioned to state \(state)")

            switch state {
                case .Discovering:
                    centralManager.scanForPeripheralsWithServices([], options: nil)

                case let .Connecting(peripheral):
                    peripheral.delegate = self
                    centralManager.connectPeripheral(peripheral, options: [:])

                case let .InterrogatingServices(peripheral):
                    peripheral.discoverServices([gpioServiceUuid])

                case let .InterrogatingCharacteristics(peripheral, service):
                    peripheral.discoverCharacteristics([gpioInputStateUuid, gpioOutputStateUuid], forService: service)

                case let .Connected(peripheral, inputCharacteristic, _):
                    peripheral.setNotifyValue(true, forCharacteristic: inputCharacteristic)

                default:
                    print("No action for entering state")
            }
        }
    }

    init(keynoteController: RemoteControllable) {
        state = .Uninitialized
        self.controlledObject = keynoteController

        super.init()

        centralManager.delegate = self
        state = .Discovering
    }

    //MARK: CBCentralManagerDelegate conformance

    func centralManagerDidUpdateState(central: CBCentralManager) {
        if central.state == .PoweredOn {
            state = .Discovering
        } else {
            state = .Uninitialized
        }
    }

    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        print("Discovered \(peripheral)")
        if let peripheralName = peripheral.name where peripheralName == deviceName {
            state = .Connecting(peripheral)
        }
    }

    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        state = .InterrogatingServices(peripheral)
    }

    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        state = .Discovering
    }

    //MARK: CBPeripheralDelegate conformance

    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        if let services = peripheral.services {
            for service in services {
                if service.UUID == gpioServiceUuid {
                    state = .InterrogatingCharacteristics(peripheral, gpioService: service)
                    return
                }
                print("Discovered services, but failed to find GPIO service.")
            }
        } else {
            print("Failed to discover services. \(error)")
        }
        state = .Uninitialized
    }

    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if let characteristics = service.characteristics {
            var gpioInputStateCharacteristic: CBCharacteristic?
            var gpioOutputStateCharacteristic: CBCharacteristic?

            for characteristic in characteristics {
                peripheral.discoverDescriptorsForCharacteristic(characteristic)

                if characteristic.UUID == gpioInputStateUuid {
                    gpioInputStateCharacteristic = characteristic
                }
                if characteristic.UUID == gpioOutputStateUuid {
                    gpioOutputStateCharacteristic = characteristic
                }
            }

            if let input = gpioInputStateCharacteristic, output = gpioOutputStateCharacteristic {
                state = .Connected(peripheral, inputCharacteristic: input, outputCharacteristic: output)
            } else {
                print("Discovered characteristics, but failed to find GPIO characteristics.")
            }
        } else {
            print("Failed to discover characteristics. \(error)")
            state = .Uninitialized
        }
    }

    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        print("Updated notification state for characteristic: \(characteristic.UUID)")
    }

    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        print("Updated value for characteristic: \(characteristic.UUID)")

        // GPIO state is a bitmask. Since there is only one input, the possible values are 0 and 1
        if characteristic.UUID == gpioInputStateUuid {
            if let value = characteristic.value {
                var state: UInt8 = 0
                value.getBytes(&state, length: 1)
                if state == 1 {
                    controlledObject.performAction()
                }
            }
        }
    }
}

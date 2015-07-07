//
//  BluetoothRemoteControl.swift
//  uB1-SlideAdvance
//
//  Created by William LaFrance on 3/27/15.
//  Copyright (c) 2015 LS Research. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol CBUUIDSearchable {
    var UUID: CBUUID { get }
}
extension CBService : CBUUIDSearchable {}
extension CBCharacteristic : CBUUIDSearchable {}

extension CollectionType where Generator.Element : CBUUIDSearchable {
    func findUUID(uuid: CBUUID) -> Generator.Element? {
        return filter({ $0.UUID == uuid }).first
    }
}

class BluetoothRemoteController : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private enum UUIDs {
        static let GpioService     = CBUUID(string: "3347AAA0-FB94-11E2-A8E4-F23C91AEC05E")
        static let GpioInputState  = CBUUID(string: "3347AAA3-FB94-11E2-A8E4-F23C91AEC05E") // Read Notify
        static let GpioOutputState = CBUUID(string: "3347AAA4-FB94-11E2-A8E4-F23C91AEC05E") // Read Write
    }

    private let deviceName: String

    private let centralManager: CBCentralManager = CBCentralManager(delegate: nil, queue: nil)

    private let controlledObject: RemoteControllable

    private var state: BluetoothState {
        willSet {
            switch state {
                case .Discovering:
                    centralManager.stopScan()

                default: ()
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
                    peripheral.discoverServices([UUIDs.GpioService])

                case let .InterrogatingCharacteristics(peripheral, service):
                    peripheral.discoverCharacteristics([UUIDs.GpioInputState, UUIDs.GpioOutputState], forService: service)

                case let .Subscribing(peripheral, inputCharacteristic, _):
                    peripheral.setNotifyValue(true, forCharacteristic: inputCharacteristic)

                default: ()
            }
        }
    }

    init(controlledObject: RemoteControllable, deviceName: String) {
        state = .Uninitialized
        self.controlledObject = controlledObject
        self.deviceName = deviceName

        super.init()

        centralManager.delegate = self
        state = .Discovering
    }

    //MARK: CBCentralManagerDelegate conformance

    func centralManagerDidUpdateState(central: CBCentralManager) {
        state = (central.state == .PoweredOn) ? .Discovering : .Uninitialized
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
        guard let services = peripheral.services, gpioService = services.findUUID(UUIDs.GpioService) else {
            print("Could not find GPIO service! Error? \(error)")
            state = .Uninitialized
            return
        }

        state = .InterrogatingCharacteristics(peripheral, gpioService: gpioService)
    }

    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        guard let characteristics = service.characteristics, input = characteristics.findUUID(UUIDs.GpioInputState), output = characteristics.findUUID(UUIDs.GpioOutputState) else {
            print("Could not find GPIO characteristics! Error? \(error)")
            state = .Uninitialized
            return
        }

        state = .Subscribing(peripheral, inputCharacteristic: input, outputCharacteristic: output)
    }

    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        guard characteristic.isNotifying else {
            print("Failed to subscribe to characteristic! Error? \(error)")
            state = .Uninitialized
            return
        }

        guard case let .Subscribing(peripheral, input, output) = state else {
            preconditionFailure("How did we get subscribed when we're not in .Subscribing?")
        }

        state = .Connected(peripheral, inputCharacteristic: input, outputCharacteristic: output)
    }

    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        guard characteristic.UUID == UUIDs.GpioInputState else {
            print("didUpdateValueForCharacteristic but UUID is not GPIO input!")
            return
        }

        guard let value = characteristic.value else {
            print("didUpdateValueForCharacteristic but value is nil NSData! Error? \(error)")
            return
        }

        // GPIO state is a bitmask. Since there is only one input, the possible values are 0 and 1
        var state: UInt8 = 0
        value.getBytes(&state, length: 1)
        if state == 1 {
            controlledObject.performAction()
        }
    }

}

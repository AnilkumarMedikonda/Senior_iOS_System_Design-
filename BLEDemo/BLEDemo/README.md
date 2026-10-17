# Bluetooth (BLE) Integration — iOS / SwiftUI / MVVM

A SwiftUI demo that scans for, connects to, and streams live data from nearby
Bluetooth Low Energy devices using **CoreBluetooth**. It uses the standard
**Heart Rate** service as the example, and the same pattern works for medical
devices such as pulse oximeters, glucose meters and blood pressure cuffs.

---

## Features

- Scan for BLE devices by service UUID, with a 10s auto-stop
- Device list sorted by signal strength (RSSI)
- Connect with a custom 10s timeout (`connect()` has none)
- Discover services and characteristics, then subscribe to live updates
- Parse raw GATT bytes into BPM (UInt8 / UInt16 flag handling)
- Live heart rate screen with min / avg / max stats
- Auto-reconnect on unexpected disconnects (not when the user taps Disconnect)
- Resets state when Bluetooth is turned off
- Mock service for SwiftUI Previews and unit tests, so no hardware is needed

---

## Architecture

```
   DeviceListView / DeviceDetailView   (display only)
      |  taps               ^ @Published
      v                     |
   DeviceListViewModel / DeviceDetailViewModel
      |  scan / connect     ^ Combine publishers
      v                     |
   BluetoothServiceProtocol  <---- MockBluetoothService
      |                     ^      (previews, tests)
      v                     |
   BluetoothService -- HeartRateParser (bytes -> BPM)
      |                     ^
      v  CBCentralManager   | delegate callbacks
   BLE Device (Peripheral -> Service -> Characteristic)
```

| Layer | Responsibility |
|---|---|
| **Models** | Plain data: `BLEDevice`, `BluetoothState`, `ConnectionState` |
| **Service** | All CoreBluetooth code behind a protocol, with output through Combine |
| **ViewModels** | Turn service events into `@Published` UI state (`@MainActor`) |
| **Views** | SwiftUI only, no logic. They forward taps to the ViewModel. |

Only `BluetoothService` imports CoreBluetooth.

---

## Project Structure

```
BLEDemo/
├── App/
│   └── BLEDemoApp.swift              # Entry point, dependency injection
├── Models/
│   ├── BLEDevice.swift               # id, name, rssi, signal text
│   ├── BluetoothState.swift          # poweredOn / off / unauthorized ...
│   └── ConnectionState.swift         # connecting / connected / reconnecting / failed
├── Services/
│   ├── BLEConstants.swift            # UUIDs and timeouts
│   ├── HeartRateParser.swift         # Raw bytes -> BPM
│   ├── BluetoothServiceProtocol.swift
│   ├── BluetoothService.swift        # Real CoreBluetooth implementation
│   └── MockBluetoothService.swift    # Fake data for previews and tests
├── ViewModels/
│   ├── DeviceListViewModel.swift
│   └── DeviceDetailViewModel.swift
└── Views/
    ├── DeviceListView.swift
    ├── DeviceRowView.swift
    └── DeviceDetailView.swift
BLEDemoTests/
└── BLEDemoTests.swift                # Parser and ViewModel tests
```

---

## Requirements

- Xcode 15+
- iOS 17+ (`navigationDestination(item:)`, `symbolEffect`)
- Swift 5.9+
- **A real iPhone.** The Simulator does not support Bluetooth.

---

## Setup

1. Open the project in Xcode.
2. **Target → Info**: add the Bluetooth permission (the app crashes without it):
   ```
   Privacy - Bluetooth Always Usage Description
   "This app uses Bluetooth to connect to medical devices."
   ```
3. *(Optional)* **Signing & Capabilities → Background Modes →**
   *Uses Bluetooth LE accessories*.
4. **Signing & Capabilities**: select your Team.
5. Choose your iPhone and press **Run**.

> If newer Xcode reports Swift 6 concurrency errors, set **Swift Language
> Version** to Swift 5 and **Strict Concurrency Checking** to Minimal.

---

## Testing Without a Real Medical Device

**Option 1: SwiftUI Previews (no iPhone needed)**
Open `DeviceListView.swift`. The preview uses `MockBluetoothService`:
tap Scan, then a device, and fake heart rate data streams in.

**Option 2: Virtual device on a second phone**
1. Install **LightBlue** on another iPhone.
2. **Virtual Devices → + → Heart Rate** and turn it on.
3. In the app, tap **Scan**, then tap the device to see live BPM.

**Option 3: Real hardware**
Any BLE heart rate strap or band that supports the standard Heart Rate service (`180D`).

---

## Running Tests

Press **⌘U**. The tests cover:

- `HeartRateParser`: UInt8 values, UInt16 values, invalid data
- `DeviceListViewModel`: tapping Scan calls the service
- `DeviceDetailViewModel`: min / avg / max calculations

All tests use `MockBluetoothService`, so no Bluetooth is required.

---

## Using Your Own Device

1. Get the **Service UUID** and **Characteristic UUID** from the device spec,
   or inspect them with **nRF Connect** / **LightBlue**.
2. Update `Services/BLEConstants.swift`.
3. Write a parser for the device's byte format (like `HeartRateParser`).
4. Publish the parsed value from `BluetoothService` and show it in a ViewModel.

---

## Connection Flow

```
1. Create CBCentralManager
2. Wait for .poweredOn
3. scanForPeripherals(withServices: [serviceUUID])
4. didDiscover          -> keep strong reference
5. stopScan + connect   -> start 10s timeout
6. didConnect           -> cancel timeout
7. discoverServices
8. discoverCharacteristics
9. setNotifyValue(true)
10. didUpdateValueFor   -> parse -> publish
11. didDisconnect       -> user tapped? reset : reconnect
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Crash on launch | Add the Bluetooth permission to Info |
| "Bluetooth not supported" | You're on the Simulator. Use a real iPhone. |
| No devices found | Check the UUID, make sure the device is advertising, or scan with `nil` to see everything |
| Connects, then drops right away | The peripheral needs a strong reference (handled in `BluetoothService`) |
| No data | The characteristic must support Notify |
| Wrong values | Check the parser: flags, byte order (little-endian), data type |

---

## Key Takeaways

- Wait for `.poweredOn` before scanning.
- Scan with a service UUID: it's faster, uses less battery, and is required in the background.
- Keep a strong reference to `CBPeripheral`.
- `connect()` never times out, so add your own.
- Model the connection as a state machine.
- Auto-reconnect only on unexpected drops.
- Keep CoreBluetooth behind a protocol so it's testable and mockable.

---

## Security Notes (Medical Apps)

- iOS handles pairing and bonding. A popup appears when the app accesses encrypted characteristics.
- Encrypt stored patient data (Keychain, Data Protection).
- Never log sensitive values.
- Follow HIPAA / GDPR requirements.


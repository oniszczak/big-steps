# Big Steps

A simple SwiftUI pedometer for iPhone with two live counters:

- **Today** — steps recorded since local midnight
- **This Session** — steps recorded since the app started or the session was reset

Big Steps uses `CMPedometer`, part of Core Motion. It requests Motion & Fitness permission on first launch and does not require HealthKit access.

## Requirements

- Xcode 16 or newer
- iOS 17 or newer
- A physical iPhone for step counting (the Simulator has no pedometer data)

## Run

1. Open `BigSteps.xcodeproj` in Xcode.
2. Select your development team under **Signing & Capabilities**.
3. Connect your iPhone and press Run.
4. Allow Motion & Fitness access when prompted.

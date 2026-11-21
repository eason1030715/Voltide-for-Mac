# Voltide for Mac — early beta

Voltide for Mac is an **unofficial macOS adaptation** of [Voltide](https://github.com/sdparklab/Voltide), originally created by **Joko (sdparklab)** and contributors. It is not affiliated with or endorsed by the upstream project. Original copyright belongs to the original copyright holders. The original MIT license and copyright notice are included in `LICENSE`; the upstream source is preserved in this fork. This project does not claim that attribution alone transfers copyright in subsequent modifications.

## Current status

This is an incomplete early beta, not feature parity with the original Windows application. It has been tried on one Apple silicon Mac mini with an Apple Bluetooth keyboard and mouse, a Logi Bolt receiver, a Logitech LIFT and a Pebble Mouse 2 M350s. Other machines, Bluetooth devices, and receivers may not work.

- Apple accessories that macOS exposes through its device management registry can show their battery level; an internal Mac battery is detected when the system reports one.
- Logitech HID++ devices using a compatible receiver can be queried, including multiple slots. Other original Voltide 2.4 GHz protocols have **not** been ported. Bluetooth devices generally are **not** supported yet.
- Battery values that are not reported are unknown. The app can retain a last reading for an unresponsive Logitech device during the current run; it may label a disconnected device as sleeping. Charging state is not detected reliably.
- Cards sort by battery level descending; Bluetooth is first for equal levels. Scroll over the cards to move horizontally.
- The interface is a recreation and is **not yet identical** to Voltide. The original tray menu, startup option and some animation behaviors are not fully ported.

## Requirements and distribution

The beta build targets **macOS 13 or newer on Apple silicon (arm64)**. The minimum OS version is a build target, not proof of testing every supported version. It is ad-hoc signed and **not notarized**, so Gatekeeper may warn or refuse it when downloaded. It is not an App Store build. App Sandbox, App Store review, additional devices, and Intel Macs have not been validated.

## Build

Install Apple Command Line Tools, then from `macos/` run:

```sh
./script/build_and_run.sh --build
```

The resulting local app is `dist/VoltideMac.app`. The script draws the icon with Swift/AppKit and assembles an `.icns`; it does not produce a Developer ID signature or notarization. This beta uses hardware information locally; its source contains no network requests.

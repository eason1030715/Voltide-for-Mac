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

## 首次開啟 / Opening the beta on macOS

此測試版只有臨時簽章，**未經 Apple 公證**。macOS 無法確認它是否含有惡意軟體；請只在確認下載來源可信且檔案未遭竄改、並自行決定信任後繼續。

1. 從本專案的 GitHub Release 下載 ZIP，解壓縮後嘗試開啟 `Voltide for Mac.app`。
2. 若 macOS 因無法驗證開發者而阻擋，打開 **系統設定 → 隱私權與安全性**，向下捲至「安全性」，找到該 App 並選擇 **強制打開**（部分地區顯示「仍要打開」）。
3. 按系統提示輸入 Mac 登入密碼，並確認打開。此按鈕通常在首次嘗試開啟後約一小時內出現；若已消失，可再嘗試打開一次。

這會為該 App 建立例外，而非替它完成 Apple 公證。如果系統警告 App **已損壞、遭竄改、含惡意軟體或會損壞電腦**，不要強制開啟；請停止使用並重新確認檔案。操作介面因 macOS 版本而異。詳見 [Apple：在 Mac 上安全地開啟 App](https://support.apple.com/zh-tw/102445)。

This beta is ad-hoc signed and **not notarized**. macOS cannot verify it is free of malware. Only if you trust its source and have checked that it has not been modified, try opening the app, then go to **System Settings → Privacy & Security → Security → Open Anyway** and follow the prompts. If macOS says the app is damaged, modified, contains malware, or will damage your computer, stop and verify the download rather than overriding the warning. See [Apple's instructions](https://support.apple.com/en-us/102445).

## Build

Install Apple Command Line Tools, then from `macos/` run:

```sh
./script/build_and_run.sh --build
```

The resulting local app is `dist/VoltideMac.app`. The script draws the icon with Swift/AppKit and assembles an `.icns`; it does not produce a Developer ID signature or notarization. This beta uses hardware information locally; its source contains no network requests.

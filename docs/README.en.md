# SMS Forwarder Mac

[简体中文](../README.md) · [English](README.en.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Español](README.es.md)

A native macOS serial monitor for SMS forwarding devices. Connect via USB to inspect supported SMS records, device logs and notification delivery logs without a Windows virtual machine.

[Installation and first SMS (Chinese)](快速上手.md) · [DMG / macOS](下载安装.md)

## Status and language support

Version 0.1.0 (Build 6) is a preview. Download the Developer ID signed and Apple-notarized DMG from [GitHub Releases](https://github.com/koi-lee/sms-forwarder-mac/releases/tag/v0.1.0-preview.6). The code uses the [MIT License](../LICENSE). Repository introductions are available in six languages; the app and detailed guides are in Chinese.

## Windows users

Open the [device manual](https://my.feishu.cn/docx/QgfudtgpPobjvsxliVlcDkR9nod) and look for `my_uart_V2.1.rar` in the “串口工具” row under “4.1 硬件准备”.

The Windows tool is supplied and maintained by the device provider. This project only links to it; it does not host the package or verify its operation or compatibility. Feishu may require sign-in or access permission. Contact your device seller if you cannot access it.

## Features

- Discover serial ports, with a USB-based hint for possible ESP32 devices. The hint does not guarantee compatibility.
- View live logs, follow the latest entries, change font size and optionally save logs to a file.
- Display the latest 100 supported SMS records: sender, message, sending time, device IP and related push logs. Follow new messages or return to the latest one.
- Manually send text or HEX bytes with optional CRLF. No AT commands are sent automatically.

## Requirements and limitations

Requires macOS 13+, a data-capable USB cable and a serial port recognized by macOS. Uses 8-N-1; supported baud rates: 9600, 19200, 38400, 57600, 115200, 230400.

Hardware checks cover the current ML307-series WIFI forwarding device, not every ML307A/ML307C firmware. Structured parsing supports SMS-DELIVER PDU with numeric senders and GSM 7-bit (DCS=0) or UCS-2 (DCS=8). Multipart SMS messages remain separate. Calls appear in raw logs, without dedicated missed-call cards.

Push status is associated with logs received within the next 60 seconds. Concurrent messages or channels can require manual verification. A success label does not prove receipt on the phone. Bark was verified with the current device; other channel tutorials are reference material. Firmware forwards notifications independently of this app.

SMS cards exist only in memory for the current session. Save logs explicitly if needed. The app currently implements no network upload or telemetry; serial logs and PDU data may still contain private information.

## Quick start

1. Connect your authorized device to the Mac using a USB data cable. Close other software using its serial port.
2. Refresh the list and verify the port. With several devices, compare the list before and after reconnecting the device.
3. Select the baud rate specified by the device (115200 for the tested device), then connect.
4. Send a test SMS to the device SIM. Inspect the message and push logs, then check receipt on the phone.
5. Save logs if needed and disconnect when finished. Everyday forwarding needs device power and network access, not a permanent Mac connection.

## Build and documentation

Run from the repository root with Xcode and the macOS SDK installed. The default build uses ad-hoc signing. Developer ID signing and Apple notarization are separate steps; the published Build 6 package is notarized.

```sh
./build-app.sh
open dist/WIFI转发宝串口助手.app
```

[Detailed guides (Chinese)](使用与排查.md) · [Bark / Telegram / Feishu](tutorial/推送渠道教程.md)

## Contact

- [service@starshoreai.com](mailto:service@starshoreai.com)
- [GitHub: koi-lee](https://github.com/koi-lee)
- [Starshore AI](https://www.starshoreai.com)

Use only devices you are authorized to access. Redact phone numbers, message contents, passwords and notification keys before sharing logs. This project is not affiliated with hardware vendors, carriers or Bark.

## Buy me a coffee

If this little tool saved you some time, you’re welcome to buy me a coffee and support future updates. Any amount is appreciated.

No pressure—a star, a suggestion, or sharing it with someone who needs it helps too. Thank you!

<table>
  <tr><th>Alipay</th><th>WeChat Pay</th></tr>
  <tr>
    <td><img src="assets/support/alipay.jpg" alt="Alipay" width="220"></td>
    <td><img src="assets/support/wechat-pay.jpg" alt="WeChat Pay" width="220"></td>
  </tr>
</table>

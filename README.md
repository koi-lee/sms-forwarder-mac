# SMS Forwarder Mac · WIFI 转发宝串口助手

[简体中文](README.md) · [English](docs/README.en.md) · [日本語](docs/README.ja.md) · [한국어](docs/README.ko.md) · [Français](docs/README.fr.md) · [Español](docs/README.es.md)

在 Mac 上通过 USB 查看短信转发设备的短信、运行日志和推送结果，无需安装 Windows 虚拟机。

Native macOS serial monitor for SMS forwarding devices. Inspect supported SMS records, device logs and notification delivery logs over USB.

<img src="Resources/AppIcon-source.png" alt="应用图标" width="128">

以上六种语言覆盖仓库介绍文档；App 界面及详细教程目前为中文。

## 当前状态

0.1.0 (Build 3) 预览版，项目代码采用 [MIT License](LICENSE)。安装包使用 Developer ID 签名并完成 Apple 公证，通过 [GitHub Releases](https://github.com/koi-lee/sms-forwarder-mac/releases/tag/v0.1.0-preview.3) 分发，无需 App Store。

面向使用 WIFI 转发宝、短信宝类设备的 Mac 用户。短信结构化解析按本次设备固件的串口输出适配；不保证所有同类硬件兼容。

## 开始使用

你需要一台 Mac、一台有收短信功能的转发设备、已启用短信服务的 SIM 卡，以及支持数据传输的 USB 线。本软件用于查看设备输出，不能让没有短信硬件的 Mac 独立接收短信。

1. [下载并安装](docs/下载安装.md)：选择 Build 3 的 DMG；普通使用无需 Xcode。
2. [按步骤连接并验证第一条短信](docs/快速上手.md)：包括如何认串口、短信发给谁、在哪里看结果。
3. 遇到问题按[使用与排查](docs/使用与排查.md)中的现象定位。

新设备尚未配网或配置推送时，先按设备说明书完成配置，再开始串口验证。已正常收到 Bark 推送的设备可直接连接。配置入口与验证范围见[推送渠道教程](docs/tutorial/推送渠道教程.md)。

## 能做什么

- 扫描 macOS 串口，按 USB 信息提示“可能是短信宝（ESP32）”，保留完整端口名供核对。
- 连接后查看原始日志，自动跟随、调整字号，手动选择文件持续保存日志。
- 从支持的 `+CMT` / PDU 输出整理发送号码、短信正文、短信发送时间、设备网络地址和推送日志。
- 最近 100 条短信独立显示；默认跟随最新短信，也可点击“回到最新”。
- 手动发送文本或 HEX 字节，按需追加 CRLF；不会自动发送 AT 命令。

## 兼容性与限制

| 项目 | 当前范围 |
| --- | --- |
| 系统 | macOS 13 或更新版本 |
| 串口 | macOS 已识别的 `/dev/cu.*`，固定 8 数据位、无校验、1 停止位 |
| 波特率 | 9600、19200、38400、57600、115200、230400 |
| 设备实测 | 本次 ML307 系列配套 WIFI 转发宝；未逐型号验证 ML307A / ML307C 全部固件 |
| 短信解析 | 数字发送号码的 SMS-DELIVER PDU，UCS-2；其他编码显示限制提示 |
| 长短信 | 分段展示，不自动合并 |
| 来电 | 在原始日志中查看；暂无独立未接来电卡片 |
| 推送状态 | 关联随后 60 秒内相关日志，密集短信、多通道并发时需核对原始日志 |
| 历史记录 | 短信卡片保存在本次运行内存中，退出不会保留；日志需主动保存 |

Bark 已有本次真实设备接收验证。飞书、钉钉、企业微信、邮件、Telegram 等是设备固件的推送渠道，教程收录不代表本 App 已逐一实测或独立实现推送。串口显示“推送成功”也不能代替手机实际收到通知的确认。

安装包下载与系统拦截处理见[完整安装教程](docs/下载安装.md)。

## 教程

- [串口、波特率、HEX、CRLF 入门](docs/使用与排查.md)
- [推送渠道与个人飞书教程索引](docs/tutorial/推送渠道教程.md)
- [脱敏配置截图](docs/tutorial/截图归档.md)
- [隐私说明](docs/隐私与来源.md)
- [构建与发布](docs/构建与发布.md)
- [Agent 入口与边界](llms.txt)

## Windows 用户

Windows 用户可打开[设备说明书中的串口工具入口](https://my.feishu.cn/docx/QgfudtgpPobjvsxliVlcDkR9nod)，在“4.1 硬件准备”的“串口工具”一行查找附件 `my_uart_V2.1.rar`。

该 Windows 工具由设备提供方提供与维护，本项目仅收录获取入口，不托管安装包，也未验证其运行与兼容性。飞书页面或附件可能需要登录及访问权限；无法打开时，请联系设备卖家获取。

## 本地构建（开发者）

需要 Xcode 及其 macOS SDK：

```sh
./build-app.sh
open dist/WIFI转发宝串口助手.app
```

默认构建仅使用 ad-hoc 本地签名；正式站外包运行 `./build-app.sh --developer-id`，要求作者指定的 Developer ID 身份。签名不等于 Apple 公证，详见发布说明。

## 联系与来源

- 作者：[koi-lee](https://github.com/koi-lee)
- 星岸 AI：[starshoreai.com](https://www.starshoreai.com)
- 产品反馈：[星岸 AI 反馈入口](https://www.starshoreai.com/feedback)
- 联系邮箱：service@starshoreai.com

配置说明参考用户提供的 WIFI 转发宝说明书及其渠道教程，来源保留在教程中。本项目不代表硬件商家、运营商或 Bark 官方。仅连接和调试你有权使用的设备。

## 请我喝杯咖啡

如果这个小工具帮你省了点时间，欢迎请我喝杯咖啡，支持我继续更新。金额随意，心意收到就很开心。

不打赏也没关系，点个 Star、提个建议，或者推荐给需要的朋友，同样是支持。谢谢你！

<table>
  <tr><th>支付宝</th><th>微信支付</th></tr>
  <tr>
    <td><img src="docs/assets/support/alipay.jpg" alt="支付宝" width="220"></td>
    <td><img src="docs/assets/support/wechat-pay.jpg" alt="微信支付" width="220"></td>
  </tr>
</table>

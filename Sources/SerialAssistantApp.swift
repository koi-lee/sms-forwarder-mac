import AppKit
import IOKit
import SwiftUI
import Darwin
import UniformTypeIdentifiers

@main
struct WiFiForwarderSerialApp: App {
    @State private var showingSupport = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, minHeight: 780)
                .sheet(isPresented: $showingSupport) {
                    SupportView()
                }
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .help) {
                Button("请我喝杯咖啡…") { showingSupport = true }
                Link("联系支持：service@starshoreai.com", destination: URL(string: "mailto:service@starshoreai.com")!)
                Link("作者 GitHub 主页", destination: URL(string: "https://github.com/koi-lee")!)
                Link("使用教程（飞书）", destination: URL(string: "https://my.feishu.cn/docx/Vzl2dnYp8oK08lxSAUhcU9kInpf")!)
            }
            CommandGroup(replacing: .appInfo) {
                Button("关于 WIFI 转发宝串口助手") {
                    NSApplication.shared.orderFrontStandardAboutPanel(options: [
                        .applicationName: "WIFI 转发宝串口助手",
                        .credits: NSAttributedString(string: "星岸 AI · SMS Forwarder Mac\n支持邮箱：service@starshoreai.com\nGitHub：https://github.com/koi-lee\n仅支持已适配固件；原始日志可能包含隐私信息。")
                    ])
                }
            }
        }
    }
}

private struct SupportView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("请我喝杯咖啡")
                .font(.title2.weight(.semibold))
            Text("如果这个工具对你有帮助，可以自愿支持作者。打赏与应用下载和功能无关，也没有固定金额。请用另一部手机扫描下方二维码。")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: 16) {
                DonationCodeCard(title: "支付宝", resourceName: "AlipayDonation")
                DonationCodeCard(title: "微信支付", resourceName: "WeChatDonation")
            }

            HStack {
                Spacer()
                Button("完成") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(minWidth: 720, minHeight: 560)
    }
}

private struct DonationCodeCard: View {
    let title: String
    let resourceName: String

    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.headline)
            if let url = Bundle.main.url(forResource: resourceName, withExtension: "jpg"),
               let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300, maxHeight: 390)
                    .accessibilityLabel("\(title)打赏二维码")
            } else {
                Label("二维码暂不可用", systemImage: "qrcode")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 260)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
    }
}


struct SerialPortIdentity {
    var name: String
    var likelyForwarder: Bool
    static func discover() -> [String: SerialPortIdentity] {
        var result: [String: SerialPortIdentity] = [:]
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOSerialBSDClient"), &iterator) == KERN_SUCCESS else { return result }
        defer { IOObjectRelease(iterator) }
        while case let service = IOIteratorNext(iterator), service != 0 {
            func property(_ entry: io_registry_entry_t, _ key: String) -> Any? {
                IORegistryEntryCreateCFProperty(entry, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
            }
            let path = property(service, "IOCalloutDevice") as? String
            var node = service
            var product: String?
            var vendor: String?
            var vendorID: Int?
            var productID: Int?
            while node != 0 {
                product = product ?? property(node, "USB Product Name") as? String
                vendor = vendor ?? property(node, "USB Vendor Name") as? String
                vendorID = vendorID ?? (property(node, "idVendor") as? NSNumber)?.intValue
                productID = productID ?? (property(node, "idProduct") as? NSNumber)?.intValue
                if vendorID != nil && product != nil { IOObjectRelease(node); break }
                var parent: io_registry_entry_t = 0
                let status = IORegistryEntryGetParentEntry(node, kIOServicePlane, &parent)
                IOObjectRelease(node)
                if status != KERN_SUCCESS { break }
                node = parent
            }
            if let path {
                let likely = vendorID == 0x303A && productID == 0x1001
                let description = [vendor, product].compactMap { $0 }.joined(separator: " · ")
                result[path] = SerialPortIdentity(name: description.isEmpty ? "其他串口" : description, likelyForwarder: likely)
            }
        }
        return result
    }
}

// Serial reads may end in the middle of a UTF-8 scalar or a CRLF pair.
struct SerialLogRenderer {
    private var pending: [UInt8] = []
    private var lineStart = true
    private var previousCR = false

    mutating func append(_ data: Data, timestamp: String, finish: Bool = false) -> String {
        pending.append(contentsOf: data)
        var end = pending.count
        if !finish, !pending.isEmpty {
            var start = pending.count - 1
            while start > 0 && pending[start] & 0xC0 == 0x80 { start -= 1 }
            let lead = pending[start]
            let length: Int
            switch lead {
            case 0xC2...0xDF: length = 2
            case 0xE0...0xEF: length = 3
            case 0xF0...0xF4: length = 4
            default: length = 1
            }
            if pending.count - start < length { end = start }
        }
        let text = String(decoding: pending.prefix(end), as: UTF8.self)
        pending.removeFirst(end)
        var rendered = ""
        for scalar in text.unicodeScalars {
            if scalar == "\n" && previousCR {
                previousCR = false
                continue
            }
            previousCR = scalar == "\r"
            if scalar == "\r" || scalar == "\n" {
                rendered += "\n"
                lineStart = true
            } else {
                if lineStart { rendered += "[\(timestamp)] "; lineStart = false }
                rendered.unicodeScalars.append(scalar)
            }
        }
        return rendered
    }
}

struct SMSRecord: Identifiable {
    let id = UUID()
    var sender: String
    var time: String
    var body: String
    var address = "未获取"
    var result = "等待推送日志"
}

enum SMSDecoder {
    static func decode(_ hex: String) -> SMSRecord? {
        guard hex.count % 2 == 0 else { return nil }
        let chars = Array(hex)
        var b: [UInt8] = []
        for i in stride(from: 0, to: chars.count, by: 2) {
            guard let v = UInt8(String(chars[i...i+1]), radix: 16) else { return nil }
            b.append(v)
        }
        guard let smsc = b.first else { return nil }
        var i = 1 + Int(smsc)
        guard i + 3 <= b.count else { return nil }
        let flags = b[i]; i += 1
        guard flags & 3 == 0 else { return nil }
        let digits = Int(b[i]); let toa = b[i+1]; i += 2
        guard toa & 0x70 != 0x50 else { return nil }
        let n = (digits + 1) / 2
        guard i + n + 10 <= b.count else { return nil }
        let address = b[i..<i+n].map { String(format: "%X%X", $0 & 15, $0 >> 4) }.joined()
        let sender = (toa & 0x70 == 0x10 ? "+" : "") + String(address.prefix(digits))
        i += n + 1
        let dcs = b[i]; i += 1
        func decimal(_ x: UInt8) -> Int { Int(x & 15) * 10 + Int(x >> 4) }
        let date = b[i..<i+7].map { decimal($0) }
        let time = String(format: "20%02d/%02d/%02d %02d:%02d:%02d", date[0], date[1], date[2], date[3], date[4], date[5])
        i += 7
        let length = Int(b[i]); i += 1
        guard dcs == 0 || dcs == 8 else {
            return SMSRecord(sender: sender, time: time, body: "此短信编码暂不支持（DCS=\(dcs)），请查看原始日志")
        }
        // GSM-7 UDL counts septets; UCS-2 UDL counts octets.
        let byteCount = dcs == 0 ? (length * 7 + 7) / 8 : length
        guard i + byteCount <= b.count else { return nil }
        let payload = Array(b[i..<i+byteCount])
        var headerBytes = 0
        var prefix = ""
        if flags & 0x40 != 0 {
            guard let h = payload.first, Int(h) + 1 <= payload.count else { return nil }
            headerBytes = Int(h) + 1
            var cursor = 1
            while cursor < headerBytes {
                guard cursor + 2 <= headerBytes else { return nil }
                let identifier = payload[cursor]
                let size = Int(payload[cursor + 1])
                guard cursor + 2 + size <= headerBytes else { return nil }
                // National language shifts need their own tables; never silently decode them as default.
                if dcs == 0 && (identifier == 0x24 || identifier == 0x25) {
                    return SMSRecord(sender: sender, time: time, body: "此短信语言移位表暂不支持，请查看原始日志")
                }
                if identifier == 0x00 || identifier == 0x08 { prefix = "[分段短信，当前片段] " }
                cursor += 2 + size
            }
        }
        let body: String
        if dcs == 0 {
            let headerSeptets = (headerBytes * 8 + 6) / 7
            guard headerSeptets <= length,
                  let decoded = decodeGSM7(payload, startBit: headerSeptets * 7, count: length - headerSeptets) else { return nil }
            body = decoded
        } else {
            let text = Array(payload.dropFirst(headerBytes))
            guard text.count % 2 == 0, let decoded = String(data: Data(text), encoding: .utf16BigEndian) else { return nil }
            body = decoded
        }
        return SMSRecord(sender: sender, time: time, body: prefix + body)
    }

    private static func decodeGSM7(_ bytes: [UInt8], startBit: Int, count: Int) -> String? {
        // 3GPP TS 23.038 default alphabet, indexed by unpacked seven-bit value.
        let alphabet = Array("@£$¥èéùìòÇ\nØø\rÅåΔ_ΦΓΛΩΠΨΣΘΞ\u{001B}ÆæßÉ !\"#¤%&'()*+,-./0123456789:;<=>?¡ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÑÜ§¿abcdefghijklmnopqrstuvwxyzäöñüà".unicodeScalars)
        let extensionTable: [UInt8: String] = [0x0A: "\u{000C}", 0x14: "^", 0x28: "{", 0x29: "}", 0x2F: "\\", 0x3C: "[", 0x3D: "~", 0x3E: "]", 0x40: "|", 0x65: "€"]
        guard startBit + count * 7 <= bytes.count * 8 else { return nil }
        var result = ""
        var escaped = false
        for position in 0..<count {
            let bit = startBit + position * 7
            let index = bit / 8
            let shift = bit % 8
            var value = UInt16(bytes[index]) >> shift
            if shift > 1 { value |= UInt16(bytes[index + 1]) << (8 - shift) }
            let code = UInt8(value & 0x7F)
            if escaped {
                guard let character = extensionTable[code] else { return nil }
                result += character
                escaped = false
            } else if code == 0x1B {
                escaped = true
            } else {
                result.unicodeScalars.append(alphabet[Int(code)])
            }
        }
        return escaped ? nil : result
    }
}

@MainActor
final class SerialModel: ObservableObject {
    @Published var ports: [String] = []
    @Published var portIdentities: [String: SerialPortIdentity] = [:]

    func portLabel(_ path: String) -> String {
        let info = portIdentities[path]
        let prefix = info?.likelyForwarder == true ? "推荐 · 可能是短信宝（ESP32）" : (info?.name ?? "其他串口")
        return prefix + " — " + path
    }
    @Published var selectedPort = ""
    @Published var baudRate = 115200
    @Published var connected = false
    @Published var receiveText = ""
    @Published var inputText = ""
    @Published var sendAsHex = false
    @Published var appendCRLF = true
    @Published var status = "请连接设备后开始监听"
    @Published var receivedBytes = 0

    @Published var messages: [SMSRecord] = []
    private var pendingLine = Data()
    private var logRenderer = SerialLogRenderer()
    private var awaitingPDU = false
    private var deviceAddress = "未获取"
    private var activeSMS: UUID?
    private var activeTime = Date.distantPast

    private func inspect(_ data: Data) {
        pendingLine.append(data)
        while let end = pendingLine.firstIndex(of: 10) {
            let line = String(decoding: pendingLine[..<end], as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
            pendingLine.removeSubrange(...end)
            if let range = line.range(of: "当前IP地址:") {
                let candidate = line[range.upperBound...].trimmingCharacters(in: .whitespaces).split(separator: ",").first.map(String.init) ?? ""
                let parts = candidate.split(separator: ".", omittingEmptySubsequences: false)
                if parts.count == 4 && parts.allSatisfy({ UInt8($0) != nil }) { deviceAddress = candidate }
            }
            if line.contains("+CMT:") { awaitingPDU = true; activeSMS = nil; continue }
            if awaitingPDU {
                let hex = line.replacingOccurrences(of: "Debug>", with: "").trimmingCharacters(in: .whitespaces)
                if !hex.isEmpty && hex.allSatisfy({ $0.isHexDigit }) {
                    var record = SMSDecoder.decode(hex) ?? SMSRecord(sender: "未解析", time: "未知", body: "短信数据解析失败，请查看原始日志")
                    record.address = deviceAddress
                    messages.insert(record, at: 0)
                    if messages.count > 100 { messages.removeLast() }
                    activeSMS = record.id; activeTime = Date(); awaitingPDU = false
                    continue
                }
            }
            if line.contains("来电号码") { activeSMS = nil }
            if let id = activeSMS, Date().timeIntervalSince(activeTime) < 60,
               let index = messages.firstIndex(where: { $0.id == id }),
               line.contains("推送成功") || line.contains("推送失败") || line.contains("开始发送到通道") || line.contains("HTTP响应码") {
                if messages[index].result == "等待推送日志" { messages[index].result = line }
                else { messages[index].result += "\n" + line }
            }
        }
        if pendingLine.count > 65536 { pendingLine.removeAll(); awaitingPDU = false }
    }

    private var fd: Int32 = -1
    private var readSource: DispatchSourceRead?
    private let queue = DispatchQueue(label: "com.local.wififorwarder.serial", qos: .userInitiated)
    private var logURL: URL?
    private var logHandle: FileHandle?
    private let maxLogFileSize: UInt64 = 100 * 1024 * 1024

    init() { refreshPorts() }

    func refreshPorts() {
        portIdentities = SerialPortIdentity.discover()
        let entries = (try? FileManager.default.contentsOfDirectory(atPath: "/dev")) ?? []
        ports = entries.filter { $0.hasPrefix("cu.") && !$0.contains("Bluetooth") }
            .map { "/dev/\($0)" }.sorted {
                let a = portIdentities[$0]?.likelyForwarder == true
                let b = portIdentities[$1]?.likelyForwarder == true
                return a != b ? a : $0 < $1
            }
        if !ports.contains(selectedPort) { selectedPort = "" }
        status = ports.isEmpty ? "未发现串口。连接设备或 USB 转串口线后刷新。" : "发现 \(ports.count) 个串口"
    }

    func toggleConnection() {
        connected ? disconnect() : connect()
    }

    private func connect() {
        guard !selectedPort.isEmpty else { status = "请先选择串口"; return }
        let descriptor = Darwin.open(selectedPort, O_RDWR | O_NOCTTY | O_NONBLOCK)
        guard descriptor >= 0 else { status = "打开失败：\(String(cString: strerror(errno)))"; return }
        var options = termios()
        guard tcgetattr(descriptor, &options) == 0 else {
            status = "读取串口设置失败：\(String(cString: strerror(errno)))"
            Darwin.close(descriptor); return
        }
        cfmakeraw(&options)
        options.c_cflag |= tcflag_t(CLOCAL | CREAD)
        options.c_cflag &= ~tcflag_t(CSIZE | PARENB | CSTOPB)
        options.c_cflag &= ~tcflag_t(CCTS_OFLOW | CRTS_IFLOW | CDTR_IFLOW | CDSR_OFLOW)
        options.c_cflag |= tcflag_t(CS8)
        options.c_cc.0 = 0
        options.c_cc.1 = 0
        let speed = speedConstant(baudRate)
        guard cfsetispeed(&options, speed) == 0, cfsetospeed(&options, speed) == 0,
              tcsetattr(descriptor, TCSANOW, &options) == 0 else {
            status = "设置波特率失败：\(String(cString: strerror(errno)))"
            Darwin.close(descriptor); return
        }
        _ = fcntl(descriptor, F_SETFL, 0)
        fd = descriptor
        connected = true
        status = "已连接 \(selectedPort) · \(baudRate) baud · 8-N-1"
        startReading(descriptor)
    }

    private func startReading(_ descriptor: Int32) {
        let source = DispatchSource.makeReadSource(fileDescriptor: descriptor, queue: queue)
        source.setEventHandler { [weak self] in
            var bytes = [UInt8](repeating: 0, count: 4096)
            let count = Darwin.read(descriptor, &bytes, bytes.count)
            guard count > 0 else { return }
            let chunk = Data(bytes.prefix(count))
            Task { @MainActor [weak self] in self?.appendReceived(chunk) }
        }
        source.setCancelHandler { }
        readSource = source
        source.resume()
    }

    private func appendReceived(_ data: Data) {
        inspect(data)
        receivedBytes += data.count
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        appendRendered(logRenderer.append(data, timestamp: timestamp))
    }

    private func appendRendered(_ rendered: String) {
        guard !rendered.isEmpty else { return }
        receiveText += rendered
        if receiveText.count > 500_000 { receiveText = String(receiveText.suffix(350_000)) }
        if let logHandle, let bytes = rendered.data(using: .utf8) {
            do {
                let currentSize = try logHandle.offset()
                guard currentSize + UInt64(bytes.count) <= maxLogFileSize else {
                    try logHandle.close()
                    self.logHandle = nil
                    self.logURL = nil
                    status = "日志文件达到 100 MiB，已停止保存；后续内容仍显示在窗口中。"
                    return
                }
                try logHandle.write(contentsOf: bytes)
            } catch {
                try? logHandle.close()
                self.logHandle = nil
                self.logURL = nil
                status = "日志文件写入失败，已停止保存：\(error.localizedDescription)"
            }
        }
    }

    func disconnect() {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        appendRendered(logRenderer.append(Data(), timestamp: timestamp, finish: true))
        if !receiveText.isEmpty && !receiveText.hasSuffix("\n") { appendRendered("\n") }
        logRenderer = SerialLogRenderer()
        readSource?.cancel()
        readSource = nil
        if fd >= 0 { Darwin.close(fd) }
        fd = -1
        connected = false
        pendingLine.removeAll(); awaitingPDU = false; activeSMS = nil; deviceAddress = "未获取"
        status = "已断开"
    }

    func send() {
        guard connected, fd >= 0 else { status = "请先连接串口"; return }
        var data: Data
        if sendAsHex {
            let tokens = inputText.split(whereSeparator: { $0.isWhitespace || $0 == "," })
            var bytes = [UInt8]()
            for token in tokens {
                guard let byte = UInt8(token, radix: 16) else { status = "HEX 格式错误：请用空格分隔两位十六进制数"; return }
                bytes.append(byte)
            }
            data = Data(bytes)
        } else {
            data = Data(inputText.utf8)
            if appendCRLF { data.append(contentsOf: [0x0D, 0x0A]) }
        }
        guard !data.isEmpty else { return }
        let written = data.withUnsafeBytes { raw in Darwin.write(fd, raw.baseAddress, raw.count) }
        if written < 0 { status = "发送失败：\(String(cString: strerror(errno)))" }
        else { status = "已发送 \(written) 字节" }
    }

    func clearLog() { receiveText = ""; receivedBytes = 0 }

    func chooseLogFile() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "wifi-forwarder-serial-\(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none).replacingOccurrences(of: "/", with: "-" )).log"
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            do {
                if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
                FileManager.default.createFile(atPath: url.path, contents: Data())
                let handle = try FileHandle(forWritingTo: url)
                try handle.write(contentsOf: Data((self?.receiveText ?? "").utf8))
                try handle.seekToEnd()
                Task { @MainActor in
                    self?.logHandle?.closeFile()
                    self?.logURL = url
                    self?.logHandle = handle
                    self?.status = "正在保存日志到 \(url.lastPathComponent)"
                }
            } catch {
                Task { @MainActor in self?.status = "创建日志文件失败：\(error.localizedDescription)" }
            }
        }
    }

    private func speedConstant(_ value: Int) -> speed_t {
        switch value {
        case 9600: return speed_t(B9600)
        case 19200: return speed_t(B19200)
        case 38400: return speed_t(B38400)
        case 57600: return speed_t(B57600)
        case 230400: return speed_t(B230400)
        default: return speed_t(B115200)
        }
    }
}

struct ContentView: View {
    @StateObject private var model = SerialModel()
    @State private var followLatest = true
    @State private var logFontSize: Double = 15
    @State private var smsFontSize: Double = 15
    @State private var followLatestSMS = true
    @State private var smsScrollRequest = 0
    @State private var scrollRequest = 0
    private let baudRates = [9600, 19200, 38400, 57600, 115200, 230400]

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            connectionBar
            Text("优先选择标有‘可能是短信宝’的 USB 设备；多块 ESP32 同时连接时，请拔插对照端口。")
                .font(.caption).foregroundStyle(.secondary).padding(.bottom, 8)
            Divider()
            VSplitView {
                smsPanel
                logPanel
            }
            Divider()
            sendPanel
            footer
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onDisappear { model.disconnect() }
    }

    private var smsPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("短信记录 · 最近 100 条").font(.headline)
                Spacer()
                Text("短信字号").foregroundStyle(.secondary)
                Slider(value: $smsFontSize, in: 13...24, step: 1)
                    .frame(width: 100).accessibilityLabel("短信字号")
                Text("\(Int(smsFontSize))").monospacedDigit()
            }
            Text("推送状态根据随后 60 秒内的日志判断；密集事件请核对详情。拖动下方分隔线可调整区域大小。")
                .font(.caption).foregroundStyle(.secondary)
            HStack {
                Toggle("自动跟随最新短信", isOn: $followLatestSMS).toggleStyle(.checkbox)
                Button("回到最新") { smsScrollRequest += 1 }
                    .disabled(model.messages.isEmpty)
            }
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        Color.clear.frame(height: 1).id("smsTop")
                        if model.messages.isEmpty {
                            Text("等待新短信。接收后显示号码、短信发送时间、正文与推送结果。")
                                .foregroundStyle(.secondary).padding(.vertical, 12)
                        }
                        ForEach(model.messages) { sms in
                            SMSCard(sms: sms, fontSize: smsFontSize)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                .onChange(of: model.messages.first?.id) { _ in
                    if followLatestSMS { proxy.scrollTo("smsTop", anchor: .top) }
                }
                .onChange(of: followLatestSMS) { enabled in
                    if enabled { proxy.scrollTo("smsTop", anchor: .top) }
                }
                .onChange(of: smsScrollRequest) { _ in
                    proxy.scrollTo("smsTop", anchor: .top)
                }
            }
        }.padding(18).frame(minHeight: 150, idealHeight: 260, maxHeight: .infinity)
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "antenna.radiowaves.left.and.right.circle.fill")
                .font(.system(size: 32)).foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 3) {
                Text("WIFI 转发宝 · 串口助手").font(.title2.weight(.semibold))
                Text("适用于 ML307A / ML307C 配套设备的串口日志与调试")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Label(model.connected ? "已连接" : "未连接", systemImage: model.connected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(model.connected ? .green : .secondary)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(.quaternary, in: Capsule())
        }
        .padding(20)
    }

    private var connectionBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("设备串口").font(.caption).foregroundStyle(.secondary)
                    Picker("设备串口", selection: $model.selectedPort) {
                        Text(model.ports.isEmpty ? "未发现串口" : "请选择串口").tag("")
                        ForEach(model.ports, id: \.self) { Text(model.portLabel($0)).tag($0) }
                    }.labelsHidden().frame(maxWidth: .infinity).disabled(model.connected)
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text("波特率").font(.caption).foregroundStyle(.secondary)
                    Picker("波特率", selection: $model.baudRate) {
                        ForEach(baudRates, id: \.self) { Text(String($0)).tag($0) }
                    }.labelsHidden().frame(width: 110).disabled(model.connected)
                }
                Button { model.refreshPorts() } label: { Label("刷新", systemImage: "arrow.clockwise") }
                    .disabled(model.connected)
                Button { model.toggleConnection() } label: {
                    Label(model.connected ? "断开" : "连接并监听", systemImage: model.connected ? "stop.circle" : "play.circle.fill")
                        .frame(minWidth: 100)
                }.buttonStyle(.borderedProminent)
            }
            Text(model.selectedPort.isEmpty ? "请选择设备串口" : model.portLabel(model.selectedPort))
                .font(.caption).textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
            Text("8 数据位 · 无校验 · 1 停止位　默认波特率 115200；按设备说明选择")
                .font(.caption).foregroundStyle(.secondary)
        }.padding(.horizontal, 20).padding(.vertical, 12)
    }

    private var logPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("接收日志", systemImage: "text.alignleft").font(.headline)
                Text("· \(model.receivedBytes) 字节").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button { model.chooseLogFile() } label: { Label("保存日志…", systemImage: "square.and.arrow.down") }
                Button { model.clearLog() } label: { Label("清空", systemImage: "trash") }
                    .disabled(model.receiveText.isEmpty)
            }
            HStack {
                Toggle("自动跟随最新日志", isOn: $followLatest).toggleStyle(.checkbox)
                Button("到底部") { scrollRequest += 1 }
                Spacer()
                Text("字号").foregroundStyle(.secondary)
                Slider(value: $logFontSize, in: 12...22, step: 1).frame(width: 100)
                Text("\(Int(logFontSize))").monospacedDigit()
            }
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(model.receiveText.isEmpty ? "连接设备后，日志将在这里实时显示。" : model.receiveText)
                            .font(.system(size: logFontSize, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                        Color.clear.frame(height: 1).id("logBottom")
                    }
                }
                .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                .onChange(of: model.receiveText) { _ in
                    if followLatest { proxy.scrollTo("logBottom", anchor: .bottom) }
                }
                .onChange(of: followLatest) { enabled in
                    if enabled { proxy.scrollTo("logBottom", anchor: .bottom) }
                }
                .onChange(of: scrollRequest) { _ in proxy.scrollTo("logBottom", anchor: .bottom) }
            }

        }
        .padding(18).frame(minHeight: 220, maxHeight: .infinity)
    }

    private var sendPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("手动发送", systemImage: "paperplane").font(.headline)
                Spacer()
                Toggle("HEX", isOn: $model.sendAsHex).toggleStyle(.switch)
                if !model.sendAsHex {
                    Toggle("发送时追加 CRLF", isOn: $model.appendCRLF).toggleStyle(.checkbox)
                }
            }
            HStack(alignment: .bottom, spacing: 12) {
                TextField(model.sendAsHex ? "例如：41 54 0D 0A" : "输入要发送的内容（不会自动发送）", text: $model.inputText, axis: .vertical)
                    .lineLimit(1...3).textFieldStyle(.roundedBorder)
                    .font(.system(size: 13, design: .monospaced))
                    .onSubmit { model.send() }
                Button { model.send() } label: { Label("发送", systemImage: "arrow.up.circle.fill").frame(width: 92) }
                    .buttonStyle(.borderedProminent).disabled(!model.connected || model.inputText.isEmpty)
            }
            Text("串口发送会直接作用于设备；本工具不会自动发送任何 AT 命令或预设指令。")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 18).padding(.vertical, 14)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Circle().fill(model.connected ? Color.green : Color.gray).frame(width: 7, height: 7)
            Text(model.status).lineLimit(1)
            Spacer()
            Text("串口同一时间只能被一个程序占用").foregroundStyle(.tertiary)
        }
        .font(.caption).padding(.horizontal, 18).padding(.vertical, 9)
    }
}

private struct SMSCard: View {
    let sms: SMSRecord
    let fontSize: Double
    @State private var expanded = false

    // Multiple channels can produce both outcomes; do not hide a failed channel.
    private var outcome: (String, String, Color) {
        let success = sms.result.contains("推送成功")
        let failure = sms.result.contains("推送失败")
        if success && failure { return ("部分推送失败", "exclamationmark.triangle.fill", .orange) }
        if failure { return ("推送失败", "xmark.circle.fill", .red) }
        if success { return ("推送成功", "checkmark.circle.fill", .green) }
        return ("等待结果", "clock", .secondary)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text("发送号码：" + sms.sender).bold()
                Spacer()
                Label(outcome.0, systemImage: outcome.1).foregroundStyle(outcome.2)
            }
            Text("短信内容：" + sms.body)
                .font(.system(size: fontSize + 2, weight: .medium))
                .fixedSize(horizontal: false, vertical: true)
            Text("短信发送时间：" + sms.time)
            Text("设备网络地址：" + sms.address).foregroundStyle(.secondary)
            DisclosureGroup("推送日志详情", isExpanded: $expanded) {
                Text(sms.result).frame(maxWidth: .infinity, alignment: .leading).padding(.top, 4)
            }.foregroundStyle(.secondary)
        }
        .font(.system(size: fontSize)).textSelection(.enabled).padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
    }
}

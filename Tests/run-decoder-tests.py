#!/usr/bin/env python3
"""Compile the production decoder with synthetic, non-personal regression fixtures."""
from pathlib import Path
import subprocess
import tempfile
root = Path(__file__).resolve().parents[1]
source = (root / 'Sources/SerialAssistantApp.swift').read_text()
decoder = source[source.index('struct SMSRecord:'):source.index('@MainActor\nfinal class SerialModel')]
tests = r'''
func pdu(_ payload: [UInt8], length: Int, dcs: UInt8 = 0, udhi: Bool = false) -> String {
    let bytes: [UInt8] = [0, udhi ? 0x40 : 0, 4, 0x81, 0x21, 0x43, 0, dcs, 0x62, 0x90, 0x82, 0x11, 0x12, 0x82, 0, UInt8(length)] + payload
    return bytes.map { String(format: "%02X", $0) }.joined()
}
func pack(_ codes: [UInt8], header: [UInt8] = []) -> (bytes: [UInt8], count: Int) {
    let skip = (header.count * 8 + 6) / 7
    var bytes = [UInt8](repeating: 0, count: ((skip + codes.count) * 7 + 7) / 8)
    for (i, byte) in header.enumerated() { bytes[i] = byte }
    for (i, code) in codes.enumerated() {
        for bit in 0..<7 where code & (1 << bit) != 0 {
            let offset = (skip + i) * 7 + bit
            bytes[offset / 8] |= 1 << (offset % 8)
        }
    }
    return (bytes, skip + codes.count)
}
var passed = 0
func check(_ actual: String?, _ expected: String?, _ name: String) {
    guard actual == expected else { fatalError("Failed: \(name)") }
    passed += 1
}
// Independent known packed vector: hellohello.
check(SMSDecoder.decode(pdu([0xE8,0x32,0x9B,0xFD,0x46,0x97,0xD9,0xEC,0x37], length: 10))?.body, "hellohello", "known GSM-7 vector")
let english = "SMS-FWD-B5-EN-0928-02"
// Captured test body only; sender, service center and timestamp were discarded.
check(SMSDecoder.decode(pdu([0xD3,0xE6,0xB4,0x65,0xBC,0x12,0x5B,0xC2,0x5A,0xAB,0xE8,0x6C,0xC1,0x72,0x32,0x5C,0x0B,0x26,0x03], length: 21))?.body, english, "actual device test body")
let packed = pack(Array(english.utf8))
check(SMSDecoder.decode(pdu(packed.bytes, length: packed.count))?.body, english, "reported English message")
let extensions: [UInt8] = [0x1B,0x14,0x1B,0x28,0x1B,0x29,0x1B,0x2F,0x1B,0x3C,0x1B,0x3D,0x1B,0x3E,0x1B,0x40,0x1B,0x65,0x1B,0x0A]
let extended = pack(extensions)
check(SMSDecoder.decode(pdu(extended.bytes, length: extended.count))?.body, "^{}\\[~]|€\u{000C}", "extension alphabet")
for count in 0...160 {
    let text = String(repeating: "A", count: count)
    let data = pack(Array(text.utf8))
    check(SMSDecoder.decode(pdu(data.bytes, length: data.count))?.body, text, "septet boundary \(count)")
}
for header in [[UInt8](arrayLiteral:5,0,3,1,2,1), [6,8,4,0,1,2,1]] {
    let data = pack(Array("Hello".utf8), header: header)
    check(SMSDecoder.decode(pdu(data.bytes, length: data.count, udhi: true))?.body, "[分段短信，当前片段] Hello", "UDH alignment")
}
let chinese = "短信助手测试二零二六年九月二十八日"
let chineseBytes = Array(chinese.data(using: .utf16BigEndian)!)
check(SMSDecoder.decode(pdu(chineseBytes, length: chineseBytes.count, dcs: 8))?.body, chinese, "UCS-2 regression")
// Exercise each requested language in UCS-2, including multipart headers.
for text in ["中文短信测试", "English SMS test", "日本語の短信テスト", "한국어 문자 테스트", "中文 English 日本語 한국어"] {
    let bytes = Array(text.data(using: .utf16BigEndian)!)
    check(SMSDecoder.decode(pdu(bytes, length: bytes.count, dcs: 8))?.body, text, "multilingual UCS-2")
    let header: [UInt8] = [5,0,3,1,2,1]
    check(SMSDecoder.decode(pdu(header + bytes, length: header.count + bytes.count, dcs: 8, udhi: true))?.body, "[分段短信，当前片段] " + text, "multilingual multipart UCS-2")
}
// Fixed byte vectors independently verify big-endian interpretation.
check(SMSDecoder.decode(pdu([0x65,0xE5,0x67,0x2C,0x8A,0x9E], length: 6, dcs: 8))?.body, "日本語", "Japanese fixed vector")
check(SMSDecoder.decode(pdu([0xD5,0x5C,0xAD,0x6D,0xC5,0xB4], length: 6, dcs: 8))?.body, "한국어", "Korean fixed vector")
check(SMSDecoder.decode(pdu([0x1B], length: 1))?.body, nil, "trailing escape")
check(SMSDecoder.decode(pdu([], length: 1))?.body, nil, "truncated user data")
check(SMSDecoder.decode(pdu([5,0], length: 2, udhi: true))?.body, nil, "truncated UDH")
let shift = pack([65], header: [3,0x24,1,1])
check(SMSDecoder.decode(pdu(shift.bytes, length: shift.count, udhi: true))?.body, "此短信语言移位表暂不支持，请查看原始日志", "national language shift explicit")
print("Decoder regression checks passed: \(passed)")
'''
with tempfile.TemporaryDirectory(prefix='sms-decoder-') as directory:
    folder = Path(directory)
    (folder / 'main.swift').write_text('import Foundation\n' + decoder + tests)
    subprocess.run(['xcrun', 'swiftc', str(folder / 'main.swift'), '-o', str(folder / 'tests')], check=True)
    subprocess.run([str(folder / 'tests')], check=True)

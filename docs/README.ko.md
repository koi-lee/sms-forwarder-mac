# SMS Forwarder Mac

[简体中文](../README.md) · [English](README.en.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Español](README.es.md)

SMS 전달 장치를 위한 macOS 네이티브 시리얼 모니터입니다. USB로 연결해 지원되는 SMS 기록, 장치 로그, 알림 전송 결과를 확인할 수 있습니다. Windows 가상 머신을 설치할 필요가 없습니다.

[설치 및 첫 SMS 확인（중국어）](快速上手.md) · [DMG / macOS](下载安装.md)

## 배포 상태와 언어

0.1.0 (Build 5)은 미리보기 버전입니다. [GitHub Releases](https://github.com/koi-lee/sms-forwarder-mac/releases/tag/v0.1.0-preview.5)에서 Developer ID 서명 및 Apple 공증을 완료한 DMG를 다운로드할 수 있습니다. 코드는 [MIT License](../LICENSE)를 사용합니다. 소개 문서는 6개 언어이며 앱과 상세 안내는 중국어입니다.

## Windows 사용자 안내

[기기 설명서](https://my.feishu.cn/docx/QgfudtgpPobjvsxliVlcDkR9nod)의 “4.1 硬件准备” 섹션에서 “串口工具” 행의 `my_uart_V2.1.rar` 첨부 파일을 확인하세요.

Windows 도구는 기기 제공업체가 제공하고 관리합니다. 이 프로젝트는 링크만 안내하며 설치 파일을 호스팅하거나 동작 및 호환성을 검증하지 않았습니다. Feishu 로그인이나 접근 권한이 필요할 수 있습니다. 열리지 않으면 기기 판매자에게 문의하세요.

## 주요 기능

- 시리얼 포트를 검색하고 USB 정보를 기반으로 ESP32일 가능성이 있는 장치를 표시합니다. 이 표시는 호환성을 보장하지 않습니다.
- 실시간 로그 보기, 최신 로그 자동 따라가기, 글자 크기 조절, 선택적인 파일 저장.
- 지원되는 최근 SMS 100건 표시: 발신 번호, 본문, 발신 시각, 장치 IP 주소, 관련 알림 로그. 최신 SMS 자동 따라가기와 최신 항목으로 이동을 지원합니다.
- 텍스트 또는 HEX 바이트 수동 전송과 선택적인 CRLF 추가. AT 명령을 자동으로 보내지 않습니다.

## 요구 사항과 제한

macOS 13 이상, 데이터 전송이 가능한 USB 케이블, macOS에서 인식되는 시리얼 포트가 필요합니다. 통신 설정은 8-N-1이며 지원 속도는 9600, 19200, 38400, 57600, 115200, 230400 baud입니다.

실제 장치 확인은 이번에 사용한 ML307 계열 WIFI 전달 장치를 대상으로 했습니다. 모든 ML307A / ML307C 펌웨어를 확인한 것은 아닙니다. 구조화된 SMS 분석은 숫자 발신 번호와 UCS-2 인코딩을 사용하는 SMS-DELIVER PDU를 지원합니다. 긴 SMS의 분할 메시지는 합치지 않습니다. 전화 수신은 원시 로그에서 확인하며 별도의 부재중 전화 카드는 없습니다.

알림 결과는 이후 60초 이내의 로그와 연결됩니다. 메시지나 채널이 동시에 처리되면 원시 로그를 확인해야 합니다. 성공 표시는 휴대전화 수신을 보장하지 않습니다. Bark는 현재 장치로 수신을 확인했으며 다른 채널 안내는 참고 자료입니다. 알림 전달은 장치 펌웨어가 독립적으로 수행합니다.

SMS 카드는 앱 실행 중 메모리에만 보관됩니다. 필요한 로그는 직접 저장해야 합니다. 앱에는 현재 네트워크 업로드나 원격 사용 정보 수집 기능이 구현되어 있지 않습니다. 다만 시리얼 로그와 PDU에는 개인정보가 포함될 수 있습니다.

## 시작하기

1. 사용 권한이 있는 장치를 USB 데이터 케이블로 Mac에 연결하고 같은 포트를 사용하는 다른 프로그램을 닫습니다.
2. 목록을 새로 고친 뒤 포트를 확인합니다. 여러 장치가 연결되어 있다면 연결 전후의 목록을 비교합니다.
3. 장치 안내에 맞는 통신 속도를 선택하고 연결합니다. 확인한 장치는 115200을 사용합니다.
4. 장치 SIM으로 테스트 SMS를 보냅니다. SMS 카드와 알림 로그를 확인하고 휴대전화에서도 수신 여부를 확인합니다.
5. 필요한 로그를 저장하고 사용을 마치면 연결을 해제합니다. 평소 전달에는 전원과 네트워크만 필요하며 Mac에 계속 연결할 필요는 없습니다.

## 빌드 및 문서

Xcode와 macOS SDK를 설치한 뒤 저장소 루트에서 실행하세요. 기본 빌드는 ad-hoc 서명을 사용합니다. Developer ID 서명과 Apple 공증은 별도 단계이며 배포되는 Build 5은 공증을 완료했습니다.

```sh
./build-app.sh
open dist/WIFI转发宝串口助手.app
```

[상세 안내(중국어)](使用与排查.md) · [Bark / Telegram / Feishu](tutorial/推送渠道教程.md)

## 문의

- [service@starshoreai.com](mailto:service@starshoreai.com)
- [GitHub: koi-lee](https://github.com/koi-lee)
- [Starshore AI](https://www.starshoreai.com)

사용 권한이 있는 장치만 연결하세요. 로그를 공유하기 전에 전화번호, 메시지 내용, 비밀번호, 알림 키를 가려 주세요. 이 프로젝트는 하드웨어 판매자, 통신사 또는 Bark와 제휴 관계가 없습니다.

## 커피 한 잔으로 응원하기

이 작은 도구가 시간을 아끼는 데 도움이 됐다면, 커피 한 잔으로 다음 업데이트를 응원해 주세요. 금액은 자유입니다.

부담 갖지 않으셔도 됩니다. Star, 개선 제안, 필요한 분께 소개해 주시는 것도 큰 힘이 됩니다. 감사합니다!

<table>
  <tr><th>Alipay</th><th>WeChat Pay</th></tr>
  <tr>
    <td><img src="assets/support/alipay.jpg" alt="Alipay" width="220"></td>
    <td><img src="assets/support/wechat-pay.jpg" alt="WeChat Pay" width="220"></td>
  </tr>
</table>

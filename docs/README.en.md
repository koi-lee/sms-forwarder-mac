# SMS Forwarder Mac

A native macOS serial assistant for inspecting SMS forwarding devices over USB. Requires macOS 13 or later. The repository is private during review; no public download is available yet.

Features: serial port discovery, baud rate selection, live logs, opt-in log file recording, manual text/HEX transmission, and supported SMS records with sender, message, timestamp and related push logs.

Compatibility is firmware-specific. The structured decoder handles numeric senders in SMS-DELIVER PDU with UCS-2. Multipart messages remain separate. Delivery status uses a 60-second log association window and is not proof of receipt. Incoming calls remain in raw logs. Bark has been checked with the current physical device; other channel tutorials are references, not compatibility claims.

The Mac app currently has no network upload or telemetry implementation. Hardware firmware forwards notifications independently. Raw serial logs and PDU payloads may contain personal data and must not be shared unredacted.

Build locally with `./build-app.sh`. Distribution is planned through GitHub Releases. Signing and notarization are separate release gates. No open-source license has been selected yet.

Author: https://github.com/koi-lee · Contact: hello@starshoreai.com

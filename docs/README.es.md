# SMS Forwarder Mac

[简体中文](../README.md) · [English](README.en.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Español](README.es.md)

Un monitor de puerto serie nativo para macOS, pensado para dispositivos de reenvío de SMS. Conecta el dispositivo por USB para consultar los SMS compatibles, los registros y los resultados de envío de notificaciones, sin instalar una máquina virtual de Windows.

[Instalación y primer SMS (en chino)](快速上手.md) · [DMG / macOS](下载安装.md)

## Disponibilidad e idiomas

La versión 0.1.0 (Build 6) es preliminar. El DMG firmado con Developer ID y notarizado por Apple se descarga desde [GitHub Releases](https://github.com/koi-lee/sms-forwarder-mac/releases/tag/v0.1.0-preview.6). El código usa [MIT](../LICENSE). Las presentaciones están en seis idiomas; la aplicación y las guías detalladas están en chino.

## Para usuarios de Windows

Abre el [manual del dispositivo](https://my.feishu.cn/docx/QgfudtgpPobjvsxliVlcDkR9nod) y busca el archivo adjunto `my_uart_V2.1.rar` en la fila «串口工具» de la sección «4.1 硬件准备».

El proveedor del dispositivo ofrece y mantiene esta herramienta para Windows. Este proyecto solo incluye el enlace; no aloja el archivo ni ha verificado su funcionamiento o compatibilidad. Feishu puede requerir iniciar sesión o tener permiso de acceso. Si no puedes abrirlo, contacta con el vendedor del dispositivo.

## Funciones

- Detección de puertos serie e indicación de posibles dispositivos ESP32 a partir de la información USB. Esta indicación no garantiza la compatibilidad.
- Registros en tiempo real, seguimiento de las últimas entradas, tamaño de letra ajustable y guardado opcional en un archivo.
- Visualización de los últimos 100 SMS compatibles: número del remitente, contenido, fecha y hora de envío, IP del dispositivo y registros de notificación relacionados. Seguimiento automático y acceso al SMS más reciente.
- Envío manual de texto o bytes HEX con CRLF opcional. No se envían comandos AT automáticamente.

## Requisitos y limitaciones

Se necesita macOS 13 o posterior, un cable USB de datos y un puerto serie reconocido por macOS. Configuración 8-N-1; velocidades disponibles: 9600, 19200, 38400, 57600, 115200 y 230400 baudios.

La comprobación con hardware se limita al dispositivo WIFI de la serie ML307 utilizado aquí; no abarca todos los firmwares ML307A / ML307C. El análisis estructurado admite PDU SMS-DELIVER con remitentes numéricos y codificación GSM 7-bit (DCS=0) o UCS-2 (DCS=8). Los segmentos de SMS largos no se unen. Las llamadas aparecen en los registros sin procesar, sin tarjetas específicas de llamadas perdidas.

El estado de la notificación se relaciona con los registros de los 60 segundos siguientes. Si coinciden varios mensajes o canales, puede ser necesario revisar los registros manualmente. Un estado de éxito no demuestra la recepción en el teléfono. Bark se ha comprobado con el dispositivo actual; los tutoriales de otros canales son material de referencia. El firmware reenvía las notificaciones de forma independiente de esta aplicación.

Las tarjetas de SMS solo se conservan en memoria durante la sesión. Guarda los registros si los necesitas. Actualmente la aplicación no implementa cargas de datos por red ni telemetría. Aun así, los registros serie y los PDU pueden contener datos personales.

## Primeros pasos

1. Conecta al Mac un dispositivo que tengas autorización para utilizar, mediante un cable USB de datos. Cierra otros programas que usen su puerto serie.
2. Actualiza la lista y comprueba el puerto. Si hay varios dispositivos, compara la lista antes y después de reconectarlo.
3. Selecciona la velocidad indicada para el dispositivo y conéctalo. El dispositivo comprobado utiliza 115200 baudios.
4. Envía un SMS de prueba a la SIM del dispositivo. Revisa la tarjeta del mensaje y los registros de notificación, y confirma la recepción en el teléfono.
5. Guarda los registros necesarios y desconecta al terminar. El reenvío habitual solo requiere alimentación y conexión de red, no una conexión permanente al Mac.

## Compilación y documentación

Ejecuta los comandos desde la raíz del repositorio con Xcode y el SDK de macOS instalados. La compilación predeterminada usa firma ad hoc. La firma Developer ID y la notarización de Apple son pasos distintos; el paquete Build 6 publicado está notarizado.

```sh
./build-app.sh
open dist/WIFI转发宝串口助手.app
```

[Guías detalladas (en chino)](使用与排查.md) · [Bark / Telegram / Feishu](tutorial/推送渠道教程.md)

## Contacto

- [service@starshoreai.com](mailto:service@starshoreai.com)
- [GitHub: koi-lee](https://github.com/koi-lee)
- [Starshore AI](https://www.starshoreai.com)

Utiliza solo dispositivos a los que tengas autorización para acceder. Oculta números de teléfono, mensajes, contraseñas y claves de notificación antes de compartir registros. Este proyecto no está afiliado a vendedores de hardware, operadores ni a Bark.

## Invítame a un café

Si esta pequeña herramienta te ha ahorrado tiempo, puedes invitarme a un café para apoyar las próximas actualizaciones. El importe lo eliges tú.

Sin compromiso: una estrella, una sugerencia o compartirla con alguien que la necesite también ayuda. ¡Gracias!

<table>
  <tr><th>Alipay</th><th>WeChat Pay</th></tr>
  <tr>
    <td><img src="assets/support/alipay.jpg" alt="Alipay" width="220"></td>
    <td><img src="assets/support/wechat-pay.jpg" alt="WeChat Pay" width="220"></td>
  </tr>
</table>

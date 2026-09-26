# SMS Forwarder Mac

[简体中文](../README.md) · [English](README.en.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Español](README.es.md)

Un moniteur de port série natif pour macOS, destiné aux appareils de transfert de SMS. Connectez l’appareil en USB pour consulter les SMS pris en charge, les journaux et les résultats d’envoi des notifications, sans machine virtuelle Windows.

[Installation et premier SMS (en chinois)](快速上手.md) · [DMG / macOS](下载安装.md)

## Disponibilité et langues

La version 0.1.0 est un aperçu privé. Aucun téléchargement public n’est encore proposé ; la distribution est prévue via GitHub Releases. Le code est sous [licence MIT](../LICENSE) ; la publication attend la validation finale. Les six langues concernent la présentation du dépôt. L’interface de l’application et les tutoriels détaillés sont actuellement en chinois.

## Pour Windows

Consultez le [manuel de l’appareil](https://my.feishu.cn/docx/QgfudtgpPobjvsxliVlcDkR9nod) : le fichier `my_uart_V2.1.rar` se trouve dans la ligne « 串口工具 » de la section « 4.1 硬件准备 ».

Cet outil Windows est fourni et maintenu par le fournisseur de l’appareil. Ce projet propose uniquement le lien, sans héberger le fichier ni vérifier son fonctionnement ou sa compatibilité. Feishu peut exiger une connexion ou une autorisation d’accès. En cas de difficulté, contactez le vendeur de votre appareil.

## Fonctionnalités

- Détection des ports série et indication des appareils potentiellement équipés d’un ESP32 à partir des informations USB. Cette indication ne garantit pas la compatibilité.
- Journaux en direct, suivi des dernières entrées, taille du texte réglable et enregistrement facultatif dans un fichier.
- Affichage des 100 derniers SMS pris en charge : numéro de l’expéditeur, contenu, date d’envoi, adresse IP de l’appareil et journaux de notification associés. Suivi automatique et retour au SMS le plus récent.
- Envoi manuel de texte ou d’octets HEX, avec ajout facultatif de CRLF. Aucune commande AT n’est envoyée automatiquement.

## Configuration requise et limites

macOS 13 ou ultérieur, un câble USB permettant le transfert de données et un port série reconnu par macOS sont nécessaires. Configuration 8-N-1 ; débits disponibles : 9600, 19200, 38400, 57600, 115200 et 230400 bauds.

Les vérifications matérielles portent sur l’appareil WIFI de la série ML307 utilisé ici, pas sur tous les firmwares ML307A / ML307C. Le décodage structuré prend en charge les PDU SMS-DELIVER avec expéditeur numérique et encodage UCS-2. Les segments des SMS longs ne sont pas assemblés. Les appels restent visibles dans les journaux bruts, sans fiche dédiée aux appels manqués.

Le résultat d’une notification est associé aux journaux des 60 secondes suivantes. Des messages ou canaux simultanés peuvent nécessiter une vérification manuelle. Un statut de réussite ne prouve pas la réception sur le téléphone. Bark a été vérifié avec l’appareil actuel ; les tutoriels des autres canaux sont des références. Le firmware transmet les notifications indépendamment de l’application.

Les fiches SMS restent uniquement en mémoire pendant la session. Enregistrez les journaux si nécessaire. L’application ne comporte actuellement aucun mécanisme de téléversement réseau ni de télémétrie. Les journaux série et les PDU peuvent toutefois contenir des données personnelles.

## Prise en main

1. Connectez au Mac un appareil que vous êtes autorisé à utiliser, avec un câble USB de données. Fermez les autres logiciels utilisant son port série.
2. Actualisez la liste et vérifiez le port. Si plusieurs appareils sont branchés, comparez la liste avant et après reconnexion.
3. Choisissez le débit indiqué par le fabricant, puis connectez-vous. L’appareil vérifié utilise 115200 bauds.
4. Envoyez un SMS de test à la SIM de l’appareil. Consultez la fiche SMS et les journaux, puis confirmez la réception sur le téléphone.
5. Enregistrez les journaux utiles et déconnectez-vous après utilisation. Le transfert quotidien nécessite une alimentation et un accès réseau, sans connexion permanente au Mac.

## Compilation et documentation

Exécutez les commandes à la racine du dépôt après avoir installé Xcode et le SDK macOS. La compilation par défaut utilise une signature ad hoc. La signature Developer ID et la notarisation Apple sont deux étapes distinctes ; la notarisation n’a pas encore été effectuée.

```sh
./build-app.sh
open dist/WIFI转发宝串口助手.app
```

[Guides détaillés (en chinois)](使用与排查.md) · [Bark / Telegram / Feishu](tutorial/推送渠道教程.md)

## Contact

- [service@starshoreai.com](mailto:service@starshoreai.com)
- [GitHub: koi-lee](https://github.com/koi-lee)
- [Starshore AI](https://www.starshoreai.com)

Utilisez uniquement des appareils auxquels vous êtes autorisé à accéder. Masquez les numéros, le contenu des messages, les mots de passe et les clés de notification avant de partager des journaux. Ce projet n’est affilié ni aux vendeurs de matériel, ni aux opérateurs, ni à Bark.

## Offrez-moi un café

Si ce petit outil vous a fait gagner du temps, vous pouvez m’offrir un café pour soutenir les prochaines mises à jour. Le montant est libre.

Sans obligation : une étoile, une suggestion ou un partage avec une personne qui en a besoin aide aussi. Merci !

<table>
  <tr><th>Alipay</th><th>WeChat Pay</th></tr>
  <tr>
    <td><img src="assets/support/alipay.jpg" alt="Alipay" width="220"></td>
    <td><img src="assets/support/wechat-pay.jpg" alt="WeChat Pay" width="220"></td>
  </tr>
</table>

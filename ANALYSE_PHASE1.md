# Phase 1 — Analyse technique : Family Remote

Téléviseur cible : **Sony Bravia (Android TV / Google TV)**
Date : 9 novembre 2026

---

## 1. Verdict de compatibilité

Les Sony Bravia vendus depuis 2015 tournent sous Android TV, et ceux depuis 2021 sous Google TV. Ils embarquent le service **« Android TV Remote Service »**, celui qu'utilise l'application officielle Google TV. C'est ce service qu'on va piloter.

**Le protocole visé est donc Android TV Remote v2** (Remote Service version 5 ou plus, en place depuis 2021). Il ne demande ni ADB ni mode développeur sur la télé.

À vérifier sur le téléviseur réel (premier test de la phase 3) :
- Le service est actif : **les ports 6466 et 6467 doivent répondre**.
- Le service mDNS `_androidtvremote2._tcp` est annoncé sur le réseau.
- Si la télé est très ancienne (2015-2017, Android 5 à 7) et que le service v2 manque : mettre à jour l'appli « Android TV Remote Service » depuis le Play Store de la télé.

**Plan B propre à Sony** : l'API REST Bravia (IRCC sur HTTP, avec une clé pré-partagée à activer dans *Réseau > Configuration du contrôle IP*). Moins riche, elle sert de solution de secours. L'abstraction `TvProtocol` (section 4) permettra de l'ajouter sans toucher à l'interface.

---

## 2. Le protocole Android TV Remote v2 (détail)

### 2.1 Découverte
- mDNS / DNS-SD, type de service : **`_androidtvremote2._tcp`**
- Le service donne le nom de la télé, son IP et le port 6466.

### 2.2 Association (port 6467, TLS)
1. Le téléphone génère **une fois** un certificat client RSA 2048 auto-signé, stocké de façon sécurisée.
2. Connexion TLS au port 6467 avec ce certificat client. Le certificat de la télé est auto-signé : on l'accepte, puis on l'utilise dans le calcul du secret.
3. Échange de messages protobuf, chacun **préfixé par sa longueur en varint** :

| Téléphone → TV | TV → Téléphone |
|---|---|
| `pairing_request` (service_name = "atvremote", client_name = nom du téléphone) | `pairing_request_ack` |
| `options` (encodage HEXADECIMAL, longueur 6, rôle INPUT) | `options` |
| `configuration` (HEXADECIMAL / 6 / INPUT) | `configuration_ack` → **la télé affiche un code à 6 caractères hexa** |
| `secret` (hash calculé) | `secret_ack` → **association réussie** |

4. **Calcul du secret** : SHA-256 de
   `modulus_client ‖ exposant_client ‖ modulus_serveur ‖ exposant_serveur ‖ octets(code[2..6])`.
   Contrôle local : le premier octet du hash doit valoir `code[0..2]`. Sinon, le code est faux et on ne l'envoie pas.

Chaque message porte `protocol_version = 2` et `status = 200`. Tout autre statut (400, 401 ou 402 pour un mauvais secret) signale une erreur, qu'on affiche à l'utilisateur.

### 2.3 Session de télécommande (port 6466, TLS avec le même certificat client)
- La télé envoie `remote_configure` (avec un champ `code1` = bitmask des fonctions supportées). On répond avec notre bitmask et nos infos d'appareil.
- La télé envoie `remote_set_active`. On répond avec notre bitmask.
- **Ping** : la télé envoie `remote_ping_request` environ toutes les 5 s, on répond `remote_ping_response` avec la même valeur. Sans échange pendant 16 s, la connexion est coupée, et c'est ce qui déclenche la reconnexion auto.
- **Touches** : `remote_key_inject { key_code, direction }`, avec la direction `SHORT` (appui court) ou `START_LONG` puis `END_LONG` (appui maintenu).
- **Texte** : `remote_ime_batch_edit`. Il faut réutiliser les compteurs IME que la télé envoie quand un champ texte s'ouvre.
- **Lancer une appli** : `remote_app_link_launch_request { app_link }`, par exemple `https://www.youtube.com` ou `https://www.netflix.com/title`.
- **Volume** : la télé envoie `remote_set_volume_level` (niveau, max, muet), ce qui permet d'afficher le volume réel.

Bitmask des fonctions : PING=1, KEY=2, IME=4, VOICE=8, POWER=32, VOLUME=64, APP_LINK=512.

### 2.4 Codes touches utiles (Module 3)

| Bouton | Code |
|---|---|
| Haut / Bas / Gauche / Droite | 19 / 20 / 21 / 22 |
| OK | 23 (DPAD_CENTER) |
| Retour / Accueil / Menu | 4 / 3 / 82 |
| Volume + / − / Muet | 24 / 25 / 164 |
| Power | 26 |
| Lecture-Pause / Lecture / Pause | 85 / 126 / 127 |
| Avance rapide / Retour rapide | 90 / 89 |
| Suivant / Précédent | 87 / 88 |
| Chaîne + / − | 166 / 167 |
| Effacer / Entrée (clavier) | 67 / 66 |
| Paramètres / Info / Guide | 176 / 165 / 172 |

---

## 3. Bibliothèques Flutter retenues

| Besoin | Choix | Justification |
|---|---|---|
| Gestion d'état | `flutter_riverpod` | Imposé par le cahier des charges |
| Navigation | `go_router` | Imposé |
| Découverte mDNS | `nsd` | Utilise les API natives (NsdManager sur Android, Bonjour sur iOS), plus fiable que `multicast_dns` en pur Dart sur iOS |
| TLS + certificat client | `dart:io` `SecureSocket` + `SecurityContext` | Natif, fonctionne sur Android et iOS : **pas de code Kotlin/Swift nécessaire** |
| Génération RSA / X.509 | `basic_utils` (sur `pointycastle`) | Génère la paire de clés et le certificat auto-signé, et extrait modulus et exposant |
| SHA-256 | `crypto` | Package officiel Dart |
| Stockage sécurisé (clé privée, certificat) | `flutter_secure_storage` | Keystore Android / Keychain iOS |
| Préférences (télés, nom du téléphone) | `shared_preferences` | Suffisant, pas besoin de SQLite |
| Protobuf | **Encodeur/décodeur écrit à la main** (environ 300 lignes) | Évite d'installer `protoc` ; le protocole n'utilise qu'une vingtaine de messages simples. Couvert par des tests unitaires |
| État du Wi-Fi | `connectivity_plus` + `network_info_plus` | Pour les écrans d'erreur (Wi-Fi coupé, autre réseau) |
| Retour haptique | `HapticFeedback` (Flutter) | Intégré |

**Packages existants écartés** : `androidtvremote` (0.0.x) et `android_remote_pro` (0.0.1) sont trop jeunes, peu maintenus, et le premier ne gère qu'iOS. Implémenter nous-mêmes un protocole bien documenté est plus sûr et plus formateur.

---

## 4. Architecture

```
lib/
├── main.dart
├── app/            (app.dart, router.dart, theme/)
├── core/
│   ├── protocol/   ← cœur réseau, SANS Flutter UI
│   │   ├── tv_protocol.dart          (interface abstraite TvProtocol)
│   │   ├── atv/                      (implémentation Android TV Remote v2)
│   │   │   ├── proto_codec.dart      (encodage protobuf + framing varint)
│   │   │   ├── pairing_client.dart   (port 6467)
│   │   │   ├── remote_client.dart    (port 6466, ping, reconnexion)
│   │   │   ├── key_codes.dart
│   │   │   └── certificate_manager.dart
│   │   └── (plus tard : sony_ircc/ en plan B)
│   ├── network/    (vérification Wi-Fi, erreurs réseau)
│   ├── storage/    (secure storage + préférences)
│   └── errors/
├── features/
│   ├── discovery/  (data / domain / presentation)
│   ├── pairing/
│   ├── remote/     (télécommande, pavé tactile, clavier)
│   ├── devices/
│   └── settings/
└── shared/         (widgets, models)
```

Principe : `core/protocol` est du **Dart pur, testable sans téléphone**. L'interface ne connaît que `TvProtocol` (`connect()`, `sendKey()`, `sendText()`, `launchApp()`, plus un flux d'état). Ajouter Sony IRCC ou une autre marque ne touchera pas l'interface.

---

## 5. Possibilités et limites d'Android TV (à annoncer honnêtement dans l'appli)

| Fonction | Statut |
|---|---|
| Navigation, OK, Retour, Accueil, volume, multimédia | ✅ Supporté |
| Saisie de texte | ✅ Seulement quand un champ texte est ouvert sur la télé |
| Lancer YouTube, Netflix… | ✅ Par lien d'application, si l'appli est installée sur la télé |
| Afficher le volume actuel | ✅ Via `remote_set_volume_level` |
| **Éteindre** la télé | ✅ |
| **Allumer** la télé | ⚠️ Seulement si « Démarrage à distance » / veille réseau est activé sur la Sony. Si la télé est en veille profonde, le service ne répond pas. Wake-on-LAN possible en option |
| **Pavé tactile = vrai curseur souris** | ❌ Le protocole n'a pas de curseur. Le pavé tactile convertira les **glissements en flèches directionnelles** (balayage = Haut/Bas/Gauche/Droite, tap = OK). Ce sera indiqué clairement |
| Plusieurs téléphones associés | ✅ Chaque téléphone a son propre certificat. Sessions simultanées : à **tester** sur la Sony |
| Liste des applis installées sur la télé | ❌ Pas exposée par le protocole : les raccourcis seront une liste configurable |
| Afficher l'appli en cours | ⚠️ Partiel (nom de package via les messages IME) |

---

## 6. Contraintes iOS

- **⚠️ Bloquant pour toi : compiler pour iPhone exige un Mac avec Xcode.** Depuis ce PC Windows on écrira le code iOS (le même code Dart) et la configuration, mais la compilation et l'installation sur iPhone se feront plus tard sur un Mac (ou avec un service CI macOS comme Codemagic).
- Sans compte Apple Developer payant, une appli installée sur iPhone **expire au bout de 7 jours** et doit être réinstallée.
- `Info.plist` doit déclarer :
  - `NSLocalNetworkUsageDescription` (texte expliquant pourquoi l'appli accède au réseau local)
  - `NSBonjourServices` = `_androidtvremote2._tcp`
- iOS affiche une demande d'autorisation « réseau local » au premier lancement. Si l'utilisateur refuse, la découverte échoue : on prévoit un écran explicatif.

## 7. Contraintes Android

- Permissions : `INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`, `CHANGE_WIFI_MULTICAST_STATE` (multicast mDNS).
- Installation par APK (sources inconnues à autoriser sur chaque téléphone de la famille).

## 8. État de ton environnement de développement

| Élément | État | Action |
|---|---|---|
| Flutter 3.47.6 | ✅ | — |
| Android SDK 36 + adb | ✅ | — |
| Android cmdline-tools | ❌ Manquant | Installer via Android Studio > SDK Manager > SDK Tools |
| Licences Android | ❌ Non acceptées | `flutter doctor --android-licenses` |
| `dart` dans le PATH | ⚠️ Pointe vers un Dart séparé (WinGet) | Mettre `C:\flutter\bin` avant dans le PATH, ou désinstaller le Dart WinGet |
| Téléphone Android physique | ❓ | Activer le débogage USB et le brancher |
| Mac pour iOS | ❓ | Voir section 6 |

---

## 9. Tests nécessaires

**Tests unitaires (sur PC, sans télé)**
- Encodage/décodage protobuf et framing varint (reproduire des octets connus)
- Calcul du secret d'association (vecteurs de test)
- Génération et relecture du certificat client
- Logique de reconnexion (avec un faux serveur)

**Tests sur le vrai matériel (téléphone Android + Sony)**
1. Les ports 6466/6467 de la Sony répondent (test faisable dès maintenant depuis ce PC)
2. Découverte mDNS du téléviseur
3. Association avec le code affiché
4. Envoi de chaque touche, une par une
5. Saisie de texte dans la recherche YouTube
6. Coupure du Wi-Fi puis reconnexion automatique
7. Deux téléphones associés, utilisés en même temps
8. Fonctionnement avec la box Internet débranchée du WAN (Wi-Fi local seul)

---

## 10. Planning détaillé

| Phase | Contenu | Durée | Validation |
|---|---|---|---|
| 1 | Analyse (ce document) | ✅ | Ta validation |
| 2 | Projet Flutter, configuration Android/iOS, architecture, thème sombre, écrans vides | 1-2 j | L'appli démarre sur ton téléphone |
| 3a | Codec protobuf + certificat + tests unitaires | 1-2 j | Tests verts |
| 3b | Découverte mDNS + saisie IP manuelle | 1 j | La Sony apparaît dans la liste |
| 3c | Association + session + **une touche réelle** | 2 j | ⭐ **Jalon critique : la Sony réagit** |
| 4 | Télécommande complète, pavé tactile, clavier, raccourcis applis | 3-4 j | Chaque bouton testé |
| 5 | Gestion familiale, multi-téléviseurs, reconnexion auto, écrans d'erreur | 2 j | Test à plusieurs téléphones |
| 6 | Finitions UI, APK de test, docs (README, installation, limites) | 2 j | APK installé chez tes frères |
| 6b | Compilation iOS | quand un Mac est disponible | Test sur iPhone |

**Total estimé : environ 12 à 15 jours de travail effectif**, moins que les 24 jours prévus initialement, parce qu'aucun module natif Kotlin/Swift n'est nécessaire.

---

## Sources

- androidtvremote2 (implémentation de référence Python) : https://github.com/tronikos/androidtvremote2
- Documentation du protocole v2 : https://github.com/Aymkdn/assistant-freebox-cloud/wiki/Google-TV-(aka-Android-TV)-Remote-Control-(v2)
- androidtv-remote (Node.js) : https://github.com/kud/androidtv-remote
- Package Flutter `androidtvremote` (écarté) : https://pub.dev/documentation/androidtvremote/0.0.1

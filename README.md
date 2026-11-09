# Family Remote

Télécommande familiale pour téléviseur **Sony Bravia (Android TV)** sur le Wi-Fi local.
Android + iOS, Flutter. Pas d'Internet, pas de serveur, pas de publication sur les stores.

- Cahier des charges : [CAHIER_DES_CHARGES.md](CAHIER_DES_CHARGES.md)
- Analyse technique (phase 1) : [ANALYSE_PHASE1.md](ANALYSE_PHASE1.md)

## Avancement

| Phase | État |
|---|---|
| 1. Analyse | ✅ Compatibilité de la Sony confirmée (ports 6466/6467, mDNS `_androidtvremote2._tcp`) |
| 2. Initialisation | ✅ |
| 3. Communication réseau | ✅ Codé et testé (20 tests). ⏳ Association réelle à valider sur la Sony |
| 4. Télécommande, pavé tactile, clavier, raccourcis applis | ✅ Codé, ⏳ à valider sur la TV |
| 5. Gestion familiale (télés enregistrées, reconnexion auto) | ✅ Codé, ⏳ à valider |
| 6. Finalisation | ⏳ |

## Fonctionnalités
- **Détection automatique** des télés compatibles sur le Wi-Fi (mDNS), ou saisie manuelle de l'adresse IP.
- **Association sécurisée** : la télé affiche un code à 6 caractères, saisi dans l'appli. Un code mal tapé est détecté avant l'envoi.
- **Télécommande** : flèches, OK, retour, accueil, menu, power, volume (avec niveau affiché), muet, multimédia. Appui maintenu = répétition.
- **Pavé tactile** : les glissements deviennent des flèches, un tap vaut OK. Pas de curseur souris : le protocole n'en propose pas.
- **Clavier** : envoie du texte dans le champ ouvert sur la télé (recherche YouTube, etc.).
- **Raccourcis** YouTube, Netflix et Prime Video.
- **Mes appareils** : télés enregistrées, oublier une télé, reconnexion automatique au démarrage et après une coupure.
- Chaque téléphone a son propre certificat, stocké dans le Keystore (Android) ou le Keychain (iOS), et s'associe séparément.

## Installation
- **Android** : `build/app/outputs/flutter-apk/app-release.apk`, à copier sur le téléphone puis installer.
- **iPhone** : GitHub → Actions → « Build iOS IPA » → Run workflow, puis télécharger l'artifact `FamilyRemote-ipa` et l'installer avec Sideloadly.
- Au premier lancement sur iPhone, **accepter l'accès au réseau local**.

## Outil de test (PC)
```bash
dart run tool/atv_cli.dart pair 192.168.100.3        # association depuis le PC
dart run tool/atv_cli.dart key 192.168.100.3 home ok # envoi de touches
```

## Lancer le projet

```bash
flutter pub get
flutter run            # téléphone Android branché en USB (débogage USB activé)
flutter test           # tests
flutter build apk      # APK à installer sur les téléphones de la famille
```

## Architecture

```
lib/
├── app/                 router, thème
├── core/protocol/       interface TvProtocol (+ Android TV Remote v2 en phase 3)
├── features/
│   ├── home/            splash + accueil
│   ├── discovery/       recherche des téléviseurs
│   ├── pairing/         association par code
│   ├── remote/          télécommande, pavé tactile, clavier (+ RemoteController)
│   ├── devices/         téléviseurs enregistrés
│   └── settings/        paramètres
└── shared/              modèles et widgets communs
```

L'interface ne dépend que de `TvProtocol` : on peut changer ou ajouter un protocole sans toucher aux écrans.

## Limites connues
- Pas de curseur souris : le pavé tactile envoie des flèches directionnelles.
- Le clavier ne fonctionne que si un champ texte est ouvert sur la télé.
- L'allumage à distance demande que « Démarrage à distance » soit activé sur la Sony.
- iOS : la compilation demande un Mac.

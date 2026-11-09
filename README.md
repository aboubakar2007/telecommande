# Family Remote

Télécommande familiale pour téléviseur **Sony Bravia (Android TV)** sur le Wi-Fi local.
Android + iOS, Flutter. Pas d'Internet, pas de serveur, pas de publication sur les stores.

- Cahier des charges : [CAHIER_DES_CHARGES.md](CAHIER_DES_CHARGES.md)
- Analyse technique (phase 1) : [ANALYSE_PHASE1.md](ANALYSE_PHASE1.md)

## Avancement

| Phase | État |
|---|---|
| 1. Analyse | ✅ Validée. Compatibilité de la Sony confirmée sur le réseau (ports 6466/6467, mDNS `_androidtvremote2._tcp`) |
| 2. Initialisation (projet, architecture, thème, écrans) | ✅ |
| 3. Communication réseau (découverte, association, connexion) | ⏳ À faire |
| 4. Télécommande complète | ⏳ |
| 5. Gestion familiale | ⏳ |
| 6. Finalisation | ⏳ |

## Ce qui fonctionne réellement aujourd'hui
- Navigation entre tous les écrans (splash, accueil, recherche, association, télécommande, pavé tactile, clavier, appareils, paramètres).
- Paramètres enregistrés sur le téléphone (nom du téléphone, sensibilité du pavé, vibrations).
- **Aucune commande n'est encore envoyée à la télé.** Chaque bouton affiche « Aucun téléviseur connecté. » tant que la phase 3 n'est pas terminée.

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

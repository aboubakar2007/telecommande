# Cahier des charges technique — Application de télécommande Android TV

(Projet local) (Android + iOS) (Wi-Fi uniquement)

L'objectif est de créer une application mobile qui transforme les téléphones de ta famille en télécommandes intelligentes pour contrôler un téléviseur Android TV ou Google TV.

L'application sera utilisée uniquement dans ton environnement familial, sans publication sur le Play Store ou l'App Store pour le moment, et sans serveur distant.

Je te recommande de partir sur **Flutter + Dart**, avec une communication réseau local entre le téléphone et le téléviseur.

image_group{"query":["modern Android TV remote control smartphone app interface dark mode","Google TV remote control app touchpad directional navigation interface","smartphone television remote control app volume navigation keyboard UI"],"aspect_ratio":"5:4","layout":"bento"}

## 1\. Présentation générale

**Nom provisoire : Family Remote**

L'application doit permettre à plusieurs membres d'une famille de contrôler un même téléviseur depuis leurs téléphones.

### Objectifs principaux

- Transformer un smartphone Android ou iPhone en télécommande.
- Détecter les téléviseurs compatibles présents sur le même réseau Wi-Fi.
- Connecter facilement un téléphone à un téléviseur.
- Contrôler les principales fonctions du téléviseur.
- Permettre à plusieurs membres de la famille d'utiliser l'application.
- Fonctionner sans connexion Internet, tant que le réseau Wi-Fi local fonctionne.

### Architecture générale

**Téléphone Android / iPhone**

Interface de télécommande Flutter

(Wi-Fi local)

Communication réseau sécurisée

**Android TV / Google TV**

Réception et exécution des commandes

Attention : le téléviseur doit être compatible avec le protocole de contrôle choisi. Tous les téléviseurs qui possèdent une connexion Wi-Fi ne sont pas nécessairement des Android TV compatibles.

## 2\. Fonctionnalités attendues

### A. Détection et connexion
image_group{"query":["Google TV remote app pair device TV code pairing screen smartphone"],"aspect_ratio":"16:9","layout":"carousel","num_per_query":1}

- Détection automatique des téléviseurs sur le réseau local.
- Affichage du nom et de l'adresse IP des téléviseurs détectés.
- Possibilité de sélectionner un téléviseur.
- Association avec un code affiché sur le téléviseur lorsque le protocole l'exige.
- Mémorisation des téléviseurs déjà associés.
- Reconnexion automatique.
- Gestion des erreurs de connexion.

### B. Télécommande principale
image_group{"query":["minimalist dark smartphone TV remote control application D pad home back volume buttons interface"],"aspect_ratio":"4:5","layout":"carousel","num_per_query":1}

Les commandes indispensables \:

| Commande | Action |
|--------|--------|
| Power | Allumer/éteindre si supporté |
| Haut / Bas | Navigation |
| Gauche / Droite | Navigation |
| OK | Valider |
| Back | Retour |
| Home | Accueil Android TV |
| Menu | Menu/options si supporté |
| Volume + / - | Contrôle du son |
| Mute | Couper le son |
| Play / Pause | Contrôle multimédia |
| Avance / Retour | Navigation multimédia |

### C. Pavé tactile

Ajouter un mode tactile permettant de déplacer un curseur ou de naviguer dans l'interface du téléviseur avec des gestes.

- Glisser pour naviguer.
- Appuyer pour valider.
- Double-taper si pertinent.
- Appui prolongé pour certaines actions.

Il faudra distinguer la navigation directionnelle Android TV du véritable contrôle d'un curseur : les deux ne sont pas équivalents.

### D. Clavier virtuel

- Saisie de texte depuis le smartphone.
- Recherche YouTube.
- Recherche dans les applications compatibles.
- Saisie de mots de passe.
- Effacement et validation.

La saisie doit être effectuée par une méthode compatible avec le protocole du téléviseur, et non en simulant arbitrairement un clavier Bluetooth.

### E. Gestion familiale

- Plusieurs téléphones peuvent être associés au même téléviseur.
- Chaque membre peut donner un nom à son téléphone.
- Afficher les téléphones associés.
- Possibilité de supprimer un appareil associé.
- Afficher l'état de connexion.

### F. Applications et multimédia

Pour une deuxième phase \:

- Lancer certaines applications installées sur Android TV.
- Contrôler la lecture multimédia.
- Afficher l'application actuellement active si disponible.
- Ajouter des raccourcis YouTube, Netflix et autres applications.

Ces fonctionnalités dépendront des autorisations et des possibilités exposées par Android TV.

## 3\. Technologies recommandées

| Élément | Technologie |
|--------|--------|
| Application mobile | Flutter / Dart |
| Interface | Material 3 + design personnalisé |
| Gestion d'état | Riverpod |
| Navigation | GoRouter |
| Découverte réseau | mDNS / DNS-SD |
| Communication | TCP/TLS selon protocole TV |
| Stockage local | SharedPreferences / SQLite |
| Gestion des appareils | Service local Flutter |
| Tests | Flutter Test + appareils réels |

### Le point technique le plus important : la communication avec Android TV

Je recommande de privilégier le protocole **Android TV Remote**, notamment le service Android TV Remote Service lorsqu'il est disponible sur le téléviseur.

Le fonctionnement envisagé \:

1. Le téléphone recherche les appareils compatibles sur le réseau Wi-Fi.
2. Il détecte le service de télécommande du téléviseur.
3. L'utilisateur sélectionne son téléviseur.
4. Le téléviseur demande une association et affiche un code.
5. L'utilisateur saisit ou valide le code sur son téléphone.
6. Une connexion sécurisée est établie.
7. Les commandes sont transmises au téléviseur.

Il ne faut pas confondre cette communication avec une simple connexion HTTP à l'adresse IP du téléviseur.

**Important pour iOS \:** Flutter permet de partager l'interface et une grande partie de la logique entre Android et iOS, mais certaines fonctions réseau, notamment Bonjour/mDNS, les autorisations de réseau local et la gestion du protocole, peuvent nécessiter du code natif Swift ou des plugins compatibles.

Il faudra également vérifier que le service Android TV Remote est disponible sur le modèle exact du téléviseur. La compatibilité ne doit pas être supposée.

## 4\. Organisation de l'application

Je recommande les écrans suivants \:

image_group{"query":["dark mobile app splash screen minimalist TV remote logo"],"aspect_ratio":"3:4","layout":"carousel","num_per_query":1}

**Écran 1 — Splash Screen**

Logo, nom de l'application et vérification de l'état initial.

---

image_group{"query":["smartphone app device discovery scan nearby television pairing interface dark UI"],"aspect_ratio":"3:4","layout":"carousel","num_per_query":1}

**Écran 2 — Détection des téléviseurs**

Recherche des téléviseurs disponibles, état de détection et sélection.

---

image_group{"query":["smartphone TV remote pairing pin code interface dark theme"],"aspect_ratio":"3:4","layout":"carousel","num_per_query":1}

**Écran 3 — Association**

Saisie du code de jumelage et validation de la connexion.

---

image_group{"query":["premium dark TV remote app directional navigation control smartphone screen"],"aspect_ratio":"3:4","layout":"carousel","num_per_query":1}

**Écran 4 — Télécommande**

Pavé directionnel, volume, retour, accueil, clavier et multimédia.

---

image_group{"query":["dark mobile settings connected devices management app UI"],"aspect_ratio":"3:4","layout":"carousel","num_per_query":1}

**Écran 5 — Paramètres**

Téléviseurs enregistrés, téléphones associés et préférences.

## 5\. Architecture logicielle

Je recommande une architecture modulaire pour éviter de mélanger l'interface graphique et la communication réseau.

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   └── utils/
├── features/
│   ├── discovery/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── pairing/
│   ├── remote/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── devices/
│   └── settings/
├── services/
│   ├── tv_remote_service.dart
│   ├── discovery_service.dart
│   └── connection_service.dart
└── shared/
    ├── widgets/
    └── models/
```

Le service de télécommande doit être indépendant de Flutter UI. Cela permettra de modifier le protocole réseau sans devoir reconstruire toute l'interface.

## 6\. Sécurité et fonctionnement local

Même si l'application reste familiale, elle doit respecter quelques règles \:

- Aucune transmission des commandes vers un serveur Internet.
- Aucun compte utilisateur obligatoire.
- Association sécurisée avec le téléviseur.
- Conservation locale des informations d'association.
- Possibilité de révoquer une association.
- Ne jamais stocker les codes secrets en clair dans les logs.
- Limiter les connexions aux appareils autorisés.
- Demander les permissions réseau nécessaires sur Android et iOS.

Le fonctionnement doit être possible sans Internet, mais le Wi-Fi doit rester actif et les appareils doivent pouvoir communiquer entre eux. Certains routeurs isolent les appareils connectés : il faudra vérifier ce paramètre.

## 7\. Planning de développement proposé

| Phase | Travail | Durée indicative |
|--------|--------|--------|
| 1 | Analyse technique et validation du protocole | 2 jours |
| 2 | Initialisation Flutter et interface | 3 jours |
| 3 | Détection des téléviseurs | 3 jours |
| 4 | Association et connexion sécurisée | 3 jours |
| 5 | Commandes de télécommande | 4 jours |
| 6 | Clavier et pavé tactile | 3 jours |
| 7 | Gestion familiale et appareils | 2 jours |
| 8 | Tests Android et iOS, corrections | 4 jours |

Estimation : environ 24 jours de travail, à ajuster selon la compatibilité des téléviseurs et les difficultés du protocole iOS.

## 8\. Critères de validation du projet

L'application sera considérée comme fonctionnelle lorsque \:

- [ ] Un téléphone Android détecte un téléviseur compatible.
- [ ] Un iPhone détecte le même téléviseur.
- [ ] L'association sécurisée fonctionne.
- [ ] Les boutons directionnels fonctionnent.
- [ ] Le volume et la navigation fonctionnent.
- [ ] La saisie de texte fonctionne sur les champs compatibles.
- [ ] Plusieurs téléphones peuvent être associés et testés.
- [ ] Une déconnexion entraîne une reconnexion propre.
- [ ] Les commandes fonctionnent sans accès Internet.
- [ ] L'application fonctionne sur de vrais téléphones Android et iOS.

---

# 9\. Prompt professionnel à donner à ton agent IA

Voici le prompt principal. Il est conçu pour que ton agent IA se comporte comme un développeur senior Flutter, un architecte logiciel et un ingénieur réseau.

Tu peux le copier directement dans ton agent.

:::writing{variant="document" id="73519"}
# PROJET : FAMILY REMOTE — APPLICATION DE TÉLÉCOMMANDE ANDROID TV

## 1. TON RÔLE

Tu es un ingénieur logiciel senior spécialisé en :
- Flutter et Dart.
- Développement Android et iOS.
- Protocoles réseau locaux.
- Communication TCP/TLS.
- Découverte d'appareils sur réseau local (mDNS/DNS-SD).
- Intégration avec Android TV et Google TV.
- UI/UX mobile moderne.

Ta mission est de concevoir et développer une application mobile complète appelée provisoirement **Family Remote**.

Tu dois travailler comme un véritable ingénieur logiciel : analyser, planifier, développer, tester, corriger et documenter.

Ne te contente pas de générer une maquette visuelle. Je veux une application réellement fonctionnelle.

## 2. CONTEXTE DU PROJET

Je souhaite créer une application de télécommande permettant de contrôler un téléviseur Android TV ou Google TV depuis plusieurs smartphones.

L'application sera utilisée uniquement dans mon environnement familial avec mes frères.

IMPORTANT :
- Le projet n'est pas destiné à être commercialisé pour le moment.
- Il ne sera pas publié sur le Play Store ou l'App Store.
- Il doit fonctionner sur un réseau Wi-Fi local.
- Il ne doit nécessiter aucun serveur distant.
- Il ne doit pas dépendre d'une connexion Internet pour les opérations de télécommande.
- Plusieurs membres de la famille doivent pouvoir utiliser leur propre téléphone pour contrôler le même téléviseur.

## 3. TECHNOLOGIES IMPOSÉES

Utilise :

- Flutter comme framework principal.
- Dart comme langage.
- Riverpod pour la gestion d'état.
- GoRouter pour la navigation.
- Material 3 pour les composants d'interface.
- Une architecture modulaire et évolutive.
- SharedPreferences ou SQLite pour les données locales.
- mDNS/DNS-SD pour la découverte des téléviseurs compatibles.
- TCP/TLS ou les mécanismes requis par le protocole Android TV Remote pour la communication.

L'application doit être compatible avec :
- Android.
- iOS.

Évite les technologies backend inutiles.

Aucun Firebase, Supabase, Laravel, PHP, Node.js distant ou base de données cloud n'est nécessaire pour ce MVP.

Tu peux utiliser des dépendances Flutter ou des modules natifs Kotlin/Swift si cela est techniquement nécessaire.

## 4. FONCTIONNALITÉS PRINCIPALES

### MODULE 1 : DÉTECTION DES TÉLÉVISEURS

Développer un système capable de :

1. Rechercher automatiquement les téléviseurs compatibles sur le réseau Wi-Fi local.
2. Détecter les services Android TV Remote disponibles.
3. Afficher les appareils détectés.
4. Afficher le nom du téléviseur et son adresse IP.
5. Permettre une recherche manuelle si la découverte automatique échoue.
6. Afficher les appareils indisponibles.
7. Gérer les erreurs réseau.
8. Actualiser la liste des appareils.

Ne considère pas qu'un appareil est compatible simplement parce qu'il répond à un ping.

### MODULE 2 : ASSOCIATION DU TÉLÉVISEUR

Créer un système d'association sécurisé.

Fonctionnement souhaité :

1. L'utilisateur sélectionne un téléviseur.
2. L'application démarre la procédure d'association.
3. Le téléviseur affiche un code ou une demande de validation selon son protocole.
4. L'utilisateur valide l'association.
5. L'application établit une connexion sécurisée.
6. Les informations d'association sont enregistrées localement.
7. L'application peut se reconnecter automatiquement.

Les identifiants et certificats doivent être protégés.

Ne simule jamais une association réussie si le protocole réel n'a pas fonctionné.

### MODULE 3 : TÉLÉCOMMANDE PRINCIPALE

Créer une interface de télécommande comprenant :

- Power, si supporté.
- Haut.
- Bas.
- Gauche.
- Droite.
- OK.
- Retour.
- Accueil.
- Menu, si supporté.
- Volume +.
- Volume -.
- Mute.
- Lecture.
- Pause.
- Avance.
- Retour multimédia.

Les boutons doivent transmettre de véritables commandes au téléviseur.

Prévoir :
- Retour visuel lors d'une pression.
- Gestion des pressions prolongées.
- Gestion des répétitions de commandes.
- Protection contre les doubles commandes involontaires.

### MODULE 4 : PAVÉ TACTILE

Créer un mode Touchpad permettant de naviguer plus facilement.

Fonctionnalités :
- Déplacement par glissement.
- Clic pour valider.
- Appui prolongé.
- Sensibilité configurable.

Distinguer clairement le pavé tactile de la navigation directionnelle.

Ne promets pas le contrôle d'un curseur si le téléviseur ne le prend pas en charge.

### MODULE 5 : CLAVIER VIRTUEL

Permettre d'utiliser le clavier du téléphone pour saisir du texte sur le téléviseur.

Fonctionnalités :
- Saisie de texte.
- Effacement.
- Validation.
- Recherche.
- Saisie de mots de passe.

Utiliser les mécanismes réellement disponibles dans le protocole du téléviseur.

### MODULE 6 : GESTION DES APPAREILS

Créer une section permettant de :

- Voir les téléviseurs enregistrés.
- Ajouter un téléviseur.
- Supprimer un téléviseur.
- Changer de téléviseur.
- Voir l'état de connexion.
- Se reconnecter automatiquement.
- Afficher le nom de l'appareil.

Plusieurs téléphones doivent pouvoir être associés au même téléviseur lorsque le service TV le permet.

Ne suppose pas que plusieurs sessions simultanées sont toujours acceptées : teste cette possibilité.

### MODULE 7 : RACCOURCIS MULTIMÉDIAS

Préparer une architecture permettant d'ajouter :

- YouTube.
- Netflix.
- Prime Video.
- Autres applications Android TV.

Ces fonctionnalités sont secondaires et ne doivent pas retarder la réalisation de la télécommande principale.

Ne garantis pas le lancement d'une application si le système TV ne l'autorise pas.

## 5. DESIGN ET EXPÉRIENCE UTILISATEUR

Je veux une interface premium, moderne, minimaliste et intuitive.

Direction artistique :
- Dark Mode par défaut.
- Fond sombre élégant.
- Boutons arrondis.
- Icônes modernes.
- Animations discrètes.
- Bonne hiérarchie visuelle.
- Interface responsive.
- Navigation fluide.

L'application doit avoir les écrans suivants :

1. Splash Screen.
2. Écran d'accueil.
3. Recherche des téléviseurs.
4. Liste des téléviseurs détectés.
5. Association.
6. Télécommande principale.
7. Pavé tactile.
8. Clavier.
9. Gestion des appareils.
10. Paramètres.

Sur l'écran principal, afficher :
- Le nom du téléviseur connecté.
- Son état de connexion.
- Un accès rapide à la télécommande.
- Les commandes principales.
- Un bouton pour changer de téléviseur.

Évite les interfaces surchargées.

## 6. ARCHITECTURE DU CODE

Organise le projet selon une architecture modulaire.

Structure proposée :

lib/
  main.dart
  app/
    app.dart
    router.dart
    theme/
  core/
    constants/
    errors/
    network/
    utils/
  features/
    discovery/
      data/
      domain/
      presentation/
    pairing/
      data/
      domain/
      presentation/
    remote/
      data/
      domain/
      presentation/
    devices/
      data/
      domain/
      presentation/
    settings/
      data/
      domain/
      presentation/
  services/
    discovery_service.dart
    connection_service.dart
    tv_remote_service.dart
  shared/
    models/
    widgets/

Tu peux adapter cette structure si une meilleure organisation est justifiée.

Sépare impérativement :
- L'interface.
- La logique métier.
- La découverte réseau.
- Le protocole de communication.
- La gestion des connexions.
- Le stockage local.

Prévois une interface abstraite pour le protocole TV afin de pouvoir ajouter ultérieurement d'autres marques et protocoles.

## 7. PROTOCOLE DE COMMUNICATION : EXIGENCE CRITIQUE

La réussite du projet dépend principalement de cette partie.

Tu dois étudier et implémenter le protocole Android TV Remote réellement compatible avec le téléviseur.

Priorités :

1. Identifier le service Android TV Remote disponible.
2. Comprendre sa procédure de découverte.
3. Comprendre sa procédure d'association.
4. Comprendre son mécanisme de chiffrement.
5. Comprendre le format des commandes.
6. Implémenter la communication.
7. Tester chaque commande sur un vrai téléviseur.

Ne crée pas un protocole fictif.

Ne remplace pas une communication réseau réelle par des données simulées dans la version finale.

Si une bibliothèque existante est utilisée :
- Vérifie sa maintenance.
- Vérifie sa compatibilité Flutter.
- Vérifie sa compatibilité Android et iOS.
- Vérifie ses dépendances.
- Vérifie ses conditions de licence.

Si aucun plugin Flutter ne permet de réaliser correctement une fonction, développe un module natif Kotlin ou Swift et expose-le à Flutter via Platform Channels.

Pour iOS, prends en charge les autorisations réseau local et les contraintes Bonjour/multicast.

Si une fonction n'est pas supportée par le téléviseur, indique-le clairement.

## 8. FONCTIONNEMENT HORS INTERNET

L'application doit pouvoir fonctionner sans Internet.

Le réseau Wi-Fi local doit suffire pour :
- Détecter le téléviseur.
- Associer le téléphone.
- Envoyer les commandes.
- Recevoir les informations de connexion.
- Reconnecter les appareils.

Aucun appel vers un serveur cloud ne doit être nécessaire.

Prévoir un écran explicatif lorsque :
- Le Wi-Fi est désactivé.
- Le téléphone et la TV ne sont pas sur le même réseau.
- Le routeur bloque la communication entre appareils.
- Le téléviseur est éteint ou inaccessible.
- Le protocole TV n'est pas disponible.

Attention : certaines fonctions d'allumage et de réveil peuvent dépendre des réglages du téléviseur et du support réseau.

## 9. SÉCURITÉ

Même si l'application est familiale :

- Protéger les informations d'association.
- Ne pas enregistrer les codes secrets dans les logs.
- Ne pas ouvrir de serveur public.
- Limiter les communications au réseau local.
- Respecter les autorisations Android et iOS.
- Permettre de révoquer les appareils associés.
- Gérer proprement les erreurs et les déconnexions.

## 10. TESTS ET VALIDATION

Créer des tests pour :

- La découverte réseau.
- L'association.
- La connexion.
- La déconnexion.
- Les commandes directionnelles.
- Le volume.
- Le clavier.
- La reconnexion.
- La gestion de plusieurs téléphones.

Effectuer des tests sur :
- Un téléphone Android physique.
- Un iPhone physique.
- Un vrai téléviseur Android TV ou Google TV.

Les émulateurs seuls ne suffisent pas pour valider le fonctionnement réseau et l'association.

## 11. MÉTHODE DE TRAVAIL OBLIGATOIRE

Ne développe pas tout en une seule fois.

Travaille par phases.

### PHASE 1 : ANALYSE

- Examiner l'environnement de développement.
- Vérifier Flutter et Dart.
- Analyser les dépendances disponibles.
- Étudier le protocole Android TV Remote.
- Identifier les contraintes Android et iOS.
- Vérifier les possibilités de test.

Avant de développer, présenter les choix techniques et les éventuelles difficultés.

### PHASE 2 : INITIALISATION

- Créer le projet Flutter.
- Configurer Android et iOS.
- Installer les dépendances.
- Mettre en place l'architecture.
- Créer le thème.
- Créer les premiers écrans.

### PHASE 3 : COMMUNICATION RÉSEAU

- Développer la découverte.
- Développer l'association.
- Établir la connexion sécurisée.
- Tester avec un vrai téléviseur.

Cette phase doit être validée avant de poursuivre les fonctionnalités avancées.

### PHASE 4 : TÉLÉCOMMANDE

- Développer les commandes.
- Tester chaque bouton.
- Ajouter le pavé tactile.
- Ajouter le clavier.

### PHASE 5 : GESTION FAMILIALE

- Ajouter les appareils.
- Gérer plusieurs téléphones.
- Ajouter la reconnexion.
- Ajouter la gestion des téléviseurs enregistrés.

### PHASE 6 : FINALISATION

- Corriger les bugs.
- Optimiser l'interface.
- Tester Android.
- Tester iOS.
- Générer les APK de test et préparer la compilation iOS.

## 12. LIVRABLES ATTENDUS

À la fin du projet, je veux :

1. Le code source Flutter complet.
2. Une application Android installable au format APK.
3. Un projet iOS compilable.
4. Une architecture propre et documentée.
5. Un fichier README.md.
6. Une documentation d'installation.
7. Une documentation de connexion au téléviseur.
8. Une liste des fonctionnalités réellement opérationnelles.
9. Une liste des limitations éventuelles.
10. Des tests documentés.

## 13. RÈGLES IMPORTANTES

- Ne développe pas de fausses fonctionnalités.
- Ne simule pas une connexion réussie.
- Ne génère pas de code inutile.
- Ne surcharge pas le projet de dépendances.
- Ne modifie pas les fichiers système sans nécessité.
- Ne supprime pas des fonctionnalités existantes sans justification.
- Teste régulièrement le code.
- Corrige les erreurs avant de passer à la phase suivante.
- Explique les décisions techniques importantes.
- Maintiens une documentation à jour.
- Ne passe pas à la phase suivante si la précédente n'est pas validée.

Si une information manque, pose une question précise au lieu d'inventer une solution.

## 14. PREMIÈRE MISSION

Commence uniquement par la PHASE 1 : ANALYSE.

Je veux que tu me présentes :

1. L'architecture technique recommandée.
2. Les bibliothèques Flutter pertinentes.
3. Le protocole exact à utiliser.
4. Les possibilités et limitations d'Android TV.
5. Les contraintes spécifiques à iOS.
6. Les tests nécessaires pour confirmer la compatibilité.
7. Un planning détaillé de réalisation.

Ne commence pas à générer tout le code avant d'avoir terminé cette analyse.

L'objectif prioritaire est de construire une véritable télécommande familiale fonctionnelle, fiable et entièrement utilisable sur notre réseau Wi-Fi local.
:::

---

## 10\. Mes recommandations avant de lancer ton agent

Il y a trois choses que je te conseille particulièrement.

**1\. Commence par tester un seul téléviseur.**

Ne demande pas à ton agent de rendre l'application compatible avec toutes les marques immédiatement. Il faut d'abord réussir la connexion avec un modèle réel.

**2\. Ne commence pas par le design.**

La priorité doit être la découverte, l'association et l'envoi d'une commande réelle. Une belle télécommande qui ne communique pas avec la télévision ne sert à rien.

**3\. Développe Android et iOS, mais valide d'abord Android.**

Cela permettra de vérifier plus rapidement le protocole avant de traiter les contraintes supplémentaires d'iOS.

## Une dernière information importante

**Quel est le modèle ou la marque de ton téléviseur ?**

Par exemple : TCL, Xiaomi, Hisense, Sony, Philips, Samsung, etc.

C'est une information déterminante : Samsung et certains téléviseurs Hisense, par exemple, n'utilisent pas nécessairement le même protocole que les Android TV compatibles avec Android TV Remote.

Avec la marque et si possible le modèle exact, on pourra adapter le cahier des charges pour éviter que ton agent IA développe une application incompatible avec ton téléviseur.

---

If you want, I can:

- Développer la logique de détection réseau Wi-Fi
- Écrire le module d'association sécurisé
- Concevoir l'écran principal de télécommande
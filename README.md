# Fraya Mobile — documentation de passation

Ce dépôt contient les éléments du projet Fraya Taxi. Cette documentation décrit la version de référence destinée à la passation : la branche `newFeatures`.

## Contenu du dépôt

| Dossier | Rôle |
| --- | --- |
| `fraya_mobile/` | Application mobile Flutter à maintenir : application passager et application chauffeur. |
| `fraya_is/` | Prototype web React/Vite historique. Il est séparé de l’application mobile et ne constitue pas son code de production. |

La maintenance applicative concerne donc en priorité `fraya_mobile/`.

## Application mobile

Fraya Mobile est une application VTC pour Abidjan. Elle regroupe deux expériences dans un même projet Flutter :

- **Passager** : authentification, recherche d’adresse, sélection de catégorie, demande et suivi de course, historique, profil, favoris et assistance.
- **Chauffeur** : authentification et onboarding, statut de disponibilité, courses proposées ou actives, navigation, portefeuille, revenus, documents et profil.

Le code Dart est organisé par responsabilités :

```text
fraya_mobile/lib/
├── core/       # configuration, bootstrap, API, temps réel et services transverses
├── data/       # sources de données et implémentations de dépôts
├── domain/     # modèles métier, contrats et cas d’utilisation
├── features/   # interfaces et états propres aux parcours passager et chauffeur
└── shared/     # providers et widgets partagés
```

L’application s’appuie notamment sur Flutter, Riverpod pour l’état, GoRouter pour la navigation, Dio pour les requêtes HTTP et le stockage local sécurisé pour les données de session.

## Variantes de l’application

| Variante | Point d’entrée Dart | Nom affiché | Usage |
| --- | --- | --- | --- |
| Passager | `lib/main_passenger.dart` | Fraya Taxi | Application des clients. |
| Chauffeur | `lib/main_driver.dart` | Fraya Chauffeur | Application des chauffeurs. |
| Développement | `lib/main_dev.dart` | Fraya Dev | Configuration de développement avec journalisation active. |

Android définit deux flavors de distribution : `passenger` et `driver`. Le flavor `dev` est un choix de configuration Flutter ; il ne correspond pas à un flavor Android distinct.

## Services et dépendances externes

La continuité du projet dépend des accès suivants :

| Service | Utilisation dans l’application | À transmettre / vérifier |
| --- | --- | --- |
| API Fraya | Authentification, profils, courses, chauffeurs, portefeuille et autres données métier. | Hébergement, accès d’administration, documentation des endpoints et comptes techniques. |
| Socket.IO | Événements temps réel liés aux courses et aux statuts. | URL du service, disponibilité du serveur et droits d’accès. |
| Google Maps et Places | Carte, géolocalisation, recherche de lieux, géocodage et itinéraires. | Projet Google Cloud, facturation activée et restrictions des clés Android/iOS. |
| OneSignal | Notifications push, avec un identifiant distinct pour chaque application. | Compte OneSignal, applications passager/chauffeur et droits de gestion des notifications. |
| Firebase / Crashlytics | Initialisation Firebase et remontée des erreurs applicatives. | Projet Firebase, accès console et configuration Android/iOS. |

Les fichiers Firebase Android sont présents dans les répertoires de flavors. Ils doivent rester cohérents avec le projet Firebase détenu par l’entreprise.

## Configuration privée

Le fichier `fraya_mobile/.env` est chargé comme asset Flutter et ne doit jamais être versionné ni transmis dans un dépôt public. Créer ce fichier à partir de `fraya_mobile/.env.example` et renseigner :

```text
GOOGLE_MAPS_API_KEY_ANDROID=
GOOGLE_MAPS_API_KEY_IOS=
GOOGLE_PLACES_API_KEY=
SERVER_URL=
ONESIGNAL_APP_ID_PASSENGER=
ONESIGNAL_APP_ID_DRIVER=
WHATSAPP_SUPPORT_NUMBER=
```

Ajouter un numéro whatsapp pour que cette fonction doit être active.

Les URLs de l’API principale et des ressources de profil sont aujourd’hui définies dans `lib/core/config/app_config.dart`. Toute évolution d’environnement doit donc être contrôlée dans cette configuration, et non déduite uniquement de `SERVER_URL`.

## État d'avancement et suivi

Les tâches restantes sont suivies sur Trello (accès déjà partagé avec vous). Aucun bug non résolu connu à ce jour — l'application est en phase de test chez le client, les retours seront traités au fur et à mesure de leur remontée.

## Signature et publication Android

La version Android est définie par une seule source : la clé `version` de `fraya_mobile/pubspec.yaml`. Il faut l’incrémenter avant chaque diffusion ; elle alimente le nom et le code de version Android.

La signature release dépend de deux fichiers locaux, hors dépôt :

- la keystore de release (`.jks`) ;
- `fraya_mobile/android/key.properties`, créé à partir de `android/key.properties.example`.

La keystore, son chemin, son alias et ses mots de passe doivent être remis par un canal sécurisé aux personnes responsables des publications. Sans elle, le build release utilise une clé de debug : il peut servir à un contrôle technique mais ne doit jamais être distribué aux utilisateurs. La perte de la keystore empêcherait de publier une mise à jour compatible avec les APK déjà installés.

Le script de build associe automatiquement chaque flavor Android au bon point d’entrée Dart :

```powershell
# Depuis fraya_mobile/
.\scripts\build_release.ps1 -Flavor passenger
.\scripts\build_release.ps1 -Flavor driver
.\scripts\build_release.ps1 -Flavor all
```

Il produit des APK séparés par architecture et affiche une empreinte SHA-256. Pour la diffusion courante, utiliser l’APK `arm64-v8a` correspondant au flavor, conserver son empreinte SHA-256 avec le fichier transmis et confirmer que la signature release est utilisée.

La minification est désactivée par défaut. Si elle est activée, valider impérativement les notifications OneSignal, la carte Google Maps et Crashlytics avant diffusion.



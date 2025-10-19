# Pixoo

**Pixoo** est une app iOS qui analyse votre photothèque pour détecter les doublons, photos similaires et photos inutiles (floues, fond quasi-uni, noir/blanc, doigt probable, rafales), afin de libérer de l'espace de stockage.

## 🎯 Modèle économique

- **Achat unique à vie** : 12,99 € (pas d'abonnement, pas de publicités, pas de compte)
- **Gratuit** : scan et aperçu illimités, visualisation des groupes et du gain estimé en Go
- **Paywall** : affiché uniquement au moment de la suppression
- **Suppression sécurisée** : tous les éléments supprimés vont dans "Supprimés récemment" (restaurable pendant 30 jours)
- **Aucune exclusion automatique** : les photos favorites, récentes ou éditées sont incluses dans l'analyse (l'utilisateur décoche ce qu'il veut garder)

## 🏗️ Architecture

### PixooCore (Swift Package)

Package Swift indépendant contenant :

- **Algorithmes de détection** :
  - pHash 64-bit (perceptual hash)
  - Variance du Laplacien (détection de netteté)
  - Entropie (8–16 bins, détection de fond quasi-uni)
  - Clustering par seuils (Hamming distance, Vision distance)

- **Modèle de données** :
  - Core Data / SQLite pour Asset, Feature, Group, Heuristic, ScanProgress
  - Persistance du curseur pour reprendre le scan après arrêt

- **API publique** :
  - `Sweeper.scan(nextBatch:)` – streaming par lots, idempotent
  - `Sweeper.classify(asset:) -> [HeuristicLabel]` – BLUR/FLAT/BLACK/WHITE/FINGER/BURST
  - `Sweeper.groupDuplicatesAndSimilars() -> [Group]`
  - `Sweeper.estimatedSavings(for selection) -> ByteCount`
  - `Sweeper.Config` – seuils configurables

### PixooApp (iOS App)

App iOS 17+ en SwiftUI :

- **Onboarding** : 2 écrans (promesse + autorisation Photos avec message rassurant)
- **Scan** : bouton "Analyser ma photothèque", progression (%, compteurs), continue en arrière-plan
- **Résultats** : 2 onglets
  - *Doublons & Similaires* : groupes de vignettes, pré-sélection modifiable
  - *Photos inutiles* : listes par catégorie (Flou, Fond quasi-uni, Noir, Blanc, Doigt, Rafales) avec raisons affichées
- **Bandeau gain** : "Vous pouvez libérer X,XX Go"
- **CTA footer** : "Supprimer N éléments (Y,YY Go)" → Paywall StoreKit local
- **Suppression** : `PHPhotoLibrary.performChanges` en lot → "Supprimés récemment", écran succès + bouton "Ouvrir 'Supprimés récemment'"
- **Arrière-plan** :
  - `beginBackgroundTask` pour finir le lot courant
  - `BGProcessingTask` pour reprendre le scan hors app
  - Notification locale à la fin du scan

### Script Python prototype

`/Scripts/proto/python/proto_sweeper.py` :

- Parcourt un dossier d'images
- Calcule pHash, Laplacien, entropie
- Groupe doublons/similaires (Hamming ≤8=duplicata, 9–18=similaire)
- Détecte photos inutiles (flou, fond quasi-uni, noir/blanc, doigt probable, rafales)
- Exporte CSV avec recommandations
- **But** : valider les seuils sur Windows avant compilation iOS

## 🚀 Démarrage

### Prototype Python (Windows)

1. Installer Python 3.8+ et dépendances :
   ```bash
   pip install opencv-python pillow numpy imagehash
   ```

2. Lancer le script :
   ```bash
   python Scripts/proto/python/proto_sweeper.py --input "C:\Users\...\Photos" --output results.csv
   ```

3. Ouvrir `results.csv` pour voir les groupes de doublons, similaires et photos inutiles détectées.

### Build sur Mac (Xcode)

**Prérequis** :
- macOS 14+ (Sonoma)
- Xcode 15+
- Apple ID gratuit ("Personal Team" suffit pour tests sur iPhone)

**Étapes** :

1. Ouvrir `PixooApp/PixooApp.xcodeproj` dans Xcode

2. Configurer l'Apple ID :
   - Xcode → Settings → Accounts → Ajouter Apple ID
   - Sélectionner le projet → Signing & Capabilities → Team → Choisir "Personal Team"

3. Build le Swift Package d'abord :
   ```bash
   cd PixooCore
   swift build
   swift test
   ```

4. Connecter un iPhone (iOS 17+) et sélectionner comme destination

5. Build & Run (⌘R)

6. **Autoriser l'app sur l'iPhone** :
   - Réglages → Général → Gestion des appareils → [Votre Apple ID] → Faire confiance

7. **StoreKit Testing** :
   - Xcode utilise automatiquement `PixooApp/StoreKit/Pixoo.storekit`
   - L'achat est simulé localement (pas de vraie transaction)
   - Pour tester : lancer le scan → cliquer "Supprimer" → paywall → acheter (gratuit en test)

## 📋 Règles de détection (v1)

### Doublons
- Vision feature print distance ≤ `d₁` (ex. 0.05)
- OU pHash Hamming distance ≤ 8

### Similaires
- Vision feature print distance ≤ `d₂` (ex. 0.15)
- OU pHash Hamming distance 9–18

### Photos inutiles

| Catégorie | Critère |
|-----------|---------|
| **Flou** | Variance du Laplacien < `T_blur` (~60 pour images 512–1024 px) |
| **Fond quasi-uni** | Entropie < `T_entropy` (~3.0 sur 8 bins) OU >95% pixels ≈ même luminance/couleur |
| **Noir** | Luminance ~0% + variance faible |
| **Blanc** | Luminance ~100% + variance faible |
| **Doigt probable** | >40% zone "peau" (HSV) ET faible texture locale |
| **Rafales** | `burstIdentifier` identique OU timestamps ±2s + similarité forte → garder 1, marquer le reste |

### Auto-sélection dans les groupes
- **Garder 1** (priorité) : résolution > netteté > récence > poids
- **Pré-cocher le reste** (modifiable par l'utilisateur)

## ⚙️ CI/CD

`.github/workflows/macos-swift.yml` :
- Build & tests du package `PixooCore` sur `macos-latest`
- **But** : éviter les régressions de compilation même sans Mac local
- **Note** : l'app iOS n'est pas buildée en CI (nécessite certificat/profil)

## 🛠️ Configuration StoreKit

- Fichier : `PixooApp/StoreKit/Pixoo.storekit`
- Produit : "Pixoo Pro" (non-consumable, 12,99 €)
- **Family Sharing désactivé** : décision business pour achat à vie individuel
- **Receipt validation** : stub local commenté (à implémenter pour production avec serveur)

## 🚧 Limites iOS

- **Background tasks** : relancées par le système (non temps réel), peuvent prendre plusieurs heures
- **Suppression** : va dans "Supprimés récemment" (30 jours), puis suppression définitive par iOS
- **Photos verrouillées/masquées** : non accessibles via PhotoKit (limitation iOS)

## ✅ Check-list QA manuelle

### Core
- [ ] PixooCore compile sans erreur
- [ ] Tests unitaires passent (`swift test`)
- [ ] pHash génère hash 64-bit cohérent pour images identiques
- [ ] Laplacien détecte images floues
- [ ] Entropie détecte fonds quasi-unis
- [ ] Clustering groupe doublons (Hamming ≤8) et similaires (9–18)

### App iOS
- [ ] Onboarding s'affiche au premier lancement
- [ ] Autorisation Photos fonctionne (texte rassurant visible)
- [ ] Scan démarre et affiche progression (%, compteurs)
- [ ] Scan continue en background si app en arrière-plan
- [ ] Notification locale affichée à la fin du scan
- [ ] Onglet "Doublons & Similaires" affiche groupes avec vignettes
- [ ] Pré-sélection : 1 gardé, reste coché (modifiable)
- [ ] Onglet "Photos inutiles" affiche listes par catégorie avec raisons
- [ ] Bandeau gain affiche "Vous pouvez libérer X,XX Go"
- [ ] Clic "Supprimer N éléments" → Paywall StoreKit
- [ ] Achat simulé fonctionne (StoreKit local)
- [ ] Suppression effectuée après achat
- [ ] Écran succès + bouton "Ouvrir 'Supprimés récemment'" (ouvre app Photos)
- [ ] Photos supprimées visibles dans "Supprimés récemment" de l'app Photos

### Prototype Python
- [ ] Script exécutable sur Windows
- [ ] Parcourt dossier d'images
- [ ] Export CSV avec colonnes : id, groupe, raisons, taille, recommandation
- [ ] Détecte doublons (Hamming ≤8) et similaires (9–18)
- [ ] Détecte flou, fond quasi-uni, noir/blanc, doigt, rafales

## 📄 Licence

MIT License - voir [LICENSE](LICENSE)

## 🤝 Contribution

Ce projet est un MVP. Les contributions sont les bienvenues pour :
- Améliorer la précision des détections
- Optimiser les performances (traitement parallèle, Metal)
- Ajouter des tests UI (XCTest)
- Internationalisation (actuellement français uniquement)

---

**Version** : 1.0.0-MVP
**Dernière mise à jour** : 2025-01-19

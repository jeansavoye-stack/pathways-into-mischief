<img src="assets/AppIcon.png" width="128" alt="Pathways Into Mischief icon">

# Pathways Into Mischief

[English](#english) · [Français](#français)

## English

A native macOS save editor for **Pathways Into Darkness**, inspired by Alain Roy’s classic **Pathways Into Cheating**.

Developed by ChatGPT (OpenAI), using Codex, from an idea by Jean Savoye, who directed the project and tested the application in the game.

**Experimental beta — 0.7.0-beta.1.** Developed against the Mac App Store port, version 2.2. Keep an independent copy of any save you care about. Some deliberately unusual combinations can trigger errors in the game.

### Download and install

Download the macOS application ZIP from this repository’s **Releases** section. Unzip it and move **Pathways Into Mischief.app** into Applications, or another folder of your choice.

The supplied beta is locally ad-hoc signed. It is **not Developer ID signed or Apple notarized**. macOS may block the first launch. Follow [Apple’s guidance for opening apps from an unidentified developer](https://support.apple.com/en-us/102445) only if you trust the download. Do not disable Gatekeeper system-wide.

Requirements: macOS 11.5 or later. The application is a Universal binary for Apple Silicon and Intel. The game must be installed separately. Testing so far covers the modern port on Apple Silicon; automated backend tests also pass under Rosetta. Native Intel GUI testing is still welcome.

### What it does

- Edit current and maximum health, including a 1,000-health preset.
- Inspect nested bags, boxes, weapons and magazines.
- Select items by category, tick a checkbox for one copy, or choose/type a total quantity.
- Add all six crystal colours, weapons with large ammunition reserves, or potion bundles.
- Remove a container while preserving its contents.
- Change seven weapon proficiencies, or set all to Expert.
- Set the game clock, reset it, or rewind by one or 24 hours.
- Choose a floor and click a tile to prepare a teleport destination.
- Remember the last file and preserve original and intermediate backups.

### Open the real save

Quit the game before saving or restoring edits. In the editor’s Open dialog, press **Command–Shift–G** and paste:

```text
~/Library/Containers/com.manuptimestudios.pathwaysintodarkness/Data/Library/Application Support/Pathways Into Darkness/
```

Choose **Saved Games.pathways**. If macOS requests folder access when saving, select the containing **Pathways Into Darkness** folder and click **Allow this folder**.

The renamed English app uses separate preferences from the French prototypes. When upgrading, select your save again and keep earlier backup files; the new app records its own original-backup baseline.

Select a saved-game slot, make changes, click **Apply** in the relevant panel, then **Save** in the main window. Launch the game and load that slot to try the changes. The editor never edits the game executable.

#### Quantities and ammunition

An item quantity is the **total number of copies wanted**, not the number to add. The inventory format has 256 slots in total. Magazines occupy slots too. A magazine’s ammunition is edited separately, up to 32,767 rounds in the editor; acceptance of extreme values by the game is not guaranteed.

The six-crystal button fills in missing colours without reducing existing stocks. Newly created containers are empty. The arsenal bundle fills matching magazines and loads empty weapons. The Colt remains experimental: using it with supplied ammunition has triggered a historical error message. A functional M16 is not fabricated from the broken M16 object.

Equipped items must be unequipped in the game before removal. Removing the inventory root is not supported yet.

#### Saving and restoring

**Save edits the file you opened**, even if that file is a Desktop copy rather than the game’s live file. Before replacement, its previous version is renamed alongside it. The editor checks whether another application changed the file since it was opened and refuses to overwrite that newer state.

**Restore original** restores the version preserved before this editor’s first save for that file path. The version being replaced during restoration is preserved too. **Export** writes an edited copy under another name. Backups and file-location bookmarks are stored locally; do not delete a backup that you may need later.

#### Clock and teleport limits

Rewinding the clock does not reschedule every independent game timer or scripted event. Teleporting does not complete prerequisites or solve quests. The map is a sector overview, not a full depiction of dynamic objects. Ordinary floor and save-rune tiles are selectable; walls, pillars, doors and level transitions are not.

The 25 maps are read at runtime from the separately installed game. None are included in this download.

### Build and test

Install Apple’s Xcode Command Line Tools, then run:

```sh
./build.sh
./build/Pathways\ Into\ Mischief.app/Contents/MacOS/PathwaysIntoMischief --self-test
```

The tests generate synthetic records; no personal saves or game files are required. They cover inventory links, all item categories, 200 duplicate crystals, exact quantities, capacity rejection, container removal, bundles, proficiency bounds, clock conversion, teleport coordinates, backup/restore, and external-change detection.

To inspect a local save without modifying it:

```sh
./build/Pathways\ Into\ Mischief.app/Contents/MacOS/PathwaysIntoMischief --inspect "/path/to/Saved Games.pathways"
```

The build script produces a Universal application and release ZIP. A Developer ID identity can optionally be supplied through `PIM_SIGN_IDENTITY`; notarization is a separate publisher step.

### Credits and licence

In tribute to **Alain Roy’s Pathways Into Cheating**. This is an independently implemented modern companion, not an official update of that program.

See [CREDITS.md](CREDITS.md) for historical format references. Code, documentation and the original icon are distributed under the [MIT licence](LICENSE). No original game code, maps, resources, or personal saves are bundled. Game names and other third-party material remain associated with their respective owners.

The code, save-format analysis, English translation, documentation and automated tests were produced by ChatGPT via Codex. The icon was generated using OpenAI image generation. Not affiliated with or endorsed by Bungie or the developers of the macOS port.

---

## Français

Un éditeur de sauvegardes natif pour **Pathways Into Darkness** sur macOS, inspiré du classique **Pathways Into Cheating** d’Alain Roy.

Développé par ChatGPT (OpenAI), via Codex, sur une idée de Jean Savoye, qui a dirigé le projet et testé l’application dans le jeu.

**Bêta expérimentale — 0.7.0-beta.1.** Développée pour le portage Mac App Store, version 2.2. Conservez une copie indépendante des sauvegardes auxquelles vous tenez. Certaines combinaisons inhabituelles peuvent provoquer des erreurs dans le jeu. L’interface de cette version de l’application est en anglais.

### Téléchargement et installation

Téléchargez l’archive ZIP de l’application macOS dans la rubrique **Releases** de ce dépôt. Décompressez-la, puis placez **Pathways Into Mischief.app** dans Applications ou dans le dossier de votre choix.

Cette bêta possède une signature locale ad hoc. Elle **n’est ni signée avec un certificat Developer ID ni notariée par Apple**. macOS peut bloquer son premier lancement. Suivez les [instructions d’Apple pour ouvrir une application provenant d’un développeur non identifié](https://support.apple.com/fr-fr/102445) si vous faites confiance au téléchargement. Ne désactivez pas Gatekeeper pour l’ensemble du système.

Configuration requise : macOS 11.5 ou ultérieur. L’application est universelle, compatible Apple Silicon et Intel. Le jeu doit être installé séparément. Les essais dans le jeu ont été réalisés avec le portage moderne sur Apple Silicon ; les tests automatisés passent aussi sous Rosetta. Les retours sur l’interface sur un Mac Intel sont les bienvenus.

### Fonctionnalités

- Modifier la santé actuelle et maximale, avec un préréglage à 1 000.
- Examiner le contenu des sacs, boîtes, armes et chargeurs.
- Choisir les objets par catégorie, cocher une case pour un exemplaire ou sélectionner/saisir une quantité totale.
- Ajouter les six couleurs de cristaux, un arsenal avec beaucoup de munitions ou des lots de potions.
- Supprimer un contenant en conservant son contenu.
- Modifier sept compétences d’armes ou les passer toutes au niveau Expert.
- Régler l’horloge du jeu, la réinitialiser ou reculer d’une heure ou de 24 heures.
- Choisir un étage et cliquer sur une case pour préparer une téléportation.
- Mémoriser le dernier fichier et conserver des sauvegardes originales et intermédiaires.

### Ouvrir la véritable sauvegarde

Quittez le jeu avant d’enregistrer ou de restaurer des modifications. Dans la fenêtre d’ouverture de l’éditeur, appuyez sur **Commande–Maj–G**, puis collez :

```text
~/Library/Containers/com.manuptimestudios.pathwaysintodarkness/Data/Library/Application Support/Pathways Into Darkness/
```

Choisissez **Saved Games.pathways**. Si macOS demande l’accès au dossier lors de l’enregistrement, sélectionnez le dossier **Pathways Into Darkness** qui contient ce fichier, puis cliquez sur **Allow this folder**.

L’application renommée en anglais utilise des préférences distinctes de celles des prototypes français. Lors de la migration, sélectionnez à nouveau votre fichier et conservez vos anciennes copies de secours ; la nouvelle application établit sa propre sauvegarde originale de référence.

Sélectionnez une partie, effectuez vos modifications, cliquez sur **Apply** dans le panneau concerné, puis sur **Save** dans la fenêtre principale. Lancez ensuite le jeu et chargez cette partie. L’éditeur ne modifie jamais l’exécutable du jeu.

#### Quantités et munitions

La quantité d’un objet est le **nombre total d’exemplaires souhaité**, et non le nombre à ajouter. L’inventaire dispose de 256 emplacements au total. Les chargeurs occupent eux aussi des emplacements. Leur nombre de cartouches se règle séparément, jusqu’à 32 767 dans l’éditeur ; le jeu n’accepte pas nécessairement les valeurs extrêmes.

Le bouton des six cristaux ajoute les couleurs manquantes sans réduire les stocks existants. Les nouveaux contenants sont vides. Le lot d’armes remplit les chargeurs correspondants et charge les armes vides. Le Colt reste expérimental : son utilisation avec des munitions ajoutées a déclenché un message d’erreur historique. L’éditeur ne transforme pas le M16 cassé en arme fonctionnelle.

Les objets équipés doivent être déséquipés dans le jeu avant leur suppression. La suppression de la racine de l’inventaire n’est pas prise en charge.

#### Enregistrement et restauration

**Save modifie le fichier que vous avez ouvert**, même s’il s’agit d’une copie sur le Bureau. Avant son remplacement, la version précédente est renommée et conservée dans le même dossier. Si une autre application a modifié le fichier depuis son ouverture, l’éditeur refuse d’écraser cette nouvelle version.

**Restore original** restaure la version conservée avant le premier enregistrement par cet éditeur pour ce chemin de fichier. La version remplacée lors de la restauration est également conservée. **Export** crée une copie modifiée sous un autre nom. Les copies de secours et les autorisations mémorisées d’accès aux fichiers restent sur votre Mac ; ne supprimez pas une copie dont vous pourriez avoir besoin.

#### Limites de l’horloge et de la téléportation

Reculer l’horloge ne recale pas tous les compteurs indépendants ni tous les événements du jeu. La téléportation ne remplit pas les conditions préalables et ne résout pas les quêtes. La carte représente les secteurs, sans détailler tous les objets dynamiques. Les cases de sol ordinaire et de rune de sauvegarde sont sélectionnables ; les murs, piliers, portes et passages entre étages ne le sont pas.

Les 25 cartes sont lues à la demande dans le jeu installé séparément. Aucune n’est incluse dans ce téléchargement.

### Compilation et tests

Installez les outils de ligne de commande Xcode d’Apple, puis exécutez :

```sh
./build.sh
./build/Pathways\ Into\ Mischief.app/Contents/MacOS/PathwaysIntoMischief --self-test
```

Les tests génèrent des données artificielles : aucune sauvegarde personnelle ni aucun fichier du jeu n’est nécessaire. Ils couvrent les liens de l’inventaire, les catégories d’objets, 200 cristaux identiques, les quantités exactes, le refus des dépassements de capacité, la suppression des contenants, les lots, les bornes des compétences, l’horloge, les coordonnées de téléportation, la sauvegarde/restauration et la détection des modifications externes.

Pour examiner une sauvegarde locale sans la modifier :

```sh
./build/Pathways\ Into\ Mischief.app/Contents/MacOS/PathwaysIntoMischief --inspect "/chemin/vers/Saved Games.pathways"
```

Le script produit une application universelle et son archive ZIP. Une identité Developer ID peut être fournie via `PIM_SIGN_IDENTITY` ; la notarisation reste une étape distincte à la charge de la personne qui publie l’application.

### Crédits et licence

En hommage à **Pathways Into Cheating d’Alain Roy**. Ce projet est un nouvel outil indépendant, et non une mise à jour officielle de ce programme.

Les références historiques sur les formats figurent dans [CREDITS.md](CREDITS.md). Le code, la documentation et l’icône originale sont distribués sous [licence MIT](LICENSE). Aucun code, carte ou ressource du jeu d’origine, ni aucune sauvegarde personnelle, n’est inclus. Les noms du jeu et les autres éléments appartenant à des tiers restent associés à leurs propriétaires respectifs.

Le code, l’analyse du format des sauvegardes, les traductions, la documentation et les tests automatisés ont été réalisés par ChatGPT via Codex. L’icône a été créée avec l’outil de génération d’images d’OpenAI. Ce projet n’est ni affilié à Bungie ou aux développeurs du portage macOS, ni approuvé par eux.

# VOWEL

Roguelike à vagues façon Brotato où **tu dessines tout** : ton perso, tes armes, tes balles, tes amulettes, et même les ennemis et les boss.
Godot 4.7, GDScript, pixel art 16 bits, 640×360 affiché en ×2.

## Lancer

1. Ouvre Godot 4.7, puis **Importer** et choisis `project.godot`.
2. Appuie sur **F5**.

Commandes : **ZQSD** / WASD / flèches / stick gauche pour bouger. Les armes attaquent toutes seules. **Échap** met en pause.
Pour dessiner : clic gauche pour peindre et clic droit pour gommer. Raccourcis B, E, L, R, O, F (outils), M (symétrie), G (dégradé), Ctrl+Z.

### Raccourcis clavier

| Écran | Touches |
|---|---|
| Partout | **Entrée** = valider / continuer, **Échap** = retour / fermer (rappelés dans l'infobulle des boutons) |
| En jeu | **Échap** ou **P** = pause · molette ou **+ / -** = zoom · dans la pause : **Entrée** reprendre, **O** options |
| Accueil | **Entrée** / **N** nouvelle partie, **A** atelier, **G** galerie, **B** bestiaire, **O** options |
| Difficulté, 1re arme, niveau | **1 à 5** (touches du haut, sans Maj, ou pavé numérique) |
| Boutique | **1 à 9** acheter l'œuvre n°, **R** nouvel accrochage, **A** ranger mes armes, **Entrée** salle suivante |
| Choix du dessin | **Entrée** utiliser, **M** modifier, **N** nouveau, **C** bord, **Échap** retour |
| Dessin | **B E L R O F** outils, **M** symétrie, **G** dégradé, **C** bord, **V** aperçu, **Ctrl+Z / Ctrl+Y**, **Entrée** valider |
| Pose / rangement | **R** tourner, **M** miroir, **Entrée** valider |
| Galerie | **Suppr** supprimer le dessin (avec confirmation, **Échap** = garder) |
| Conseils | **Entrée**, **Espace** ou **Échap** = compris |

Test automatique (simule dessins, 9 vagues avec boss, boutique, menus) :
`Godot --headless --path . res://tests/selftest.tscn`
Armes spéciales et nouvelles amulettes : `Godot --headless --path . res://tests/specials.tscn`

## Outil de dev (Ctrl+P en pleine vague)

Panneau de test (jeu en pause) : stats du perso (−/+), invincibilité, soin, or, niveaux, tuer tout, finir la vague ; faire apparaître **n'importe quel ennemi ou boss devant soi** (élite ou non) ; donner n'importe quelle **arme** (toute rareté) ou **amulette**. Les dessins manquants sont pris dans le Bestiaire, sinon remplacés par des formes provisoires.
**À retirer avant de publier le jeu** : `ENABLED := false` dans `scripts/dev/dev_panel.gd` (ou supprimer le dossier `scripts/dev/`).

## Publier une version (GitHub)

Dépôt : https://github.com/Vltbcq/VowelGame. Lien à donner aux joueurs : https://github.com/Vltbcq/VowelGame/releases/latest

La pipeline `.github/workflows/release.yml` exporte le jeu sur les serveurs de GitHub (Godot 4.7.2, Windows), vérifie que tous les scripts compilent, puis publie une Release avec `Vowel.exe` et `Vowel-windows.zip` :
- en poussant un tag de version : `git tag v0.2` puis `git push origin v0.2` ;
- ou à la main : onglet **Actions → Release → Run workflow**, en saisissant la version.

## Sauvegardes et reprise

- **3 sauvegardes** au lancement du jeu : chacune a sa progression (pigments, déblocages, records), sa galerie, son Bestiaire et sa partie en cours. Les options sont communes. Bouton **Supprimer** avec confirmation (il faut cliquer, Entrée ne suffit pas). Depuis le titre : « Sauvegarde N · changer » (touche **S**).
- La sauvegarde 1 utilise les fichiers d'origine (`user://vowel_save.json`, `gallery/`, `bestiary/`) ; les 2 et 3 sont dans `user://slot2/` et `user://slot3/`. Options : `user://settings.json`.
- **Reprise de partie** : la partie est enregistrée automatiquement au début de chaque vague, à la fin de chaque vague, après chaque niveau et à chaque action en boutique (`run_save.dat`). **Sauvegarder et quitter** est dans le menu pause et dans la boutique ; au titre, **Reprendre** (Entrée). Quitter en pleine vague (ou fermer le jeu) fait recommencer cette vague depuis son début, avec les PV du début de vague. Commencer une nouvelle partie remplace la partie en cours (après confirmation, sans compter de défaite).
- Test : `res://tests/savetest.tscn` (travaille dans un dossier temporaire, jamais dans les vraies sauvegardes).

## Déroulé d'une partie

1. Choix de la difficulté : Esquisse → Croquis → Aquarelle → Huile → Chef-d'œuvre (chacune se débloque en gagnant la précédente).
2. **Dessin du perso**, avec une encre limitée.
3. Choix de la première arme parmi 10 types (5 mêlée, 5 distance), puis dessin de l'arme (et de ses balles si c'est une arme à distance). Tu la **poses où tu veux** sur ton perso.
   - Chaque type d'arme et chaque amulette ne se dessine **qu'une fois par partie** : les exemplaires suivants réutilisent ce dessin.
   - Mêlée : Dague (rapide), Épée (arc), Lance (estoc long), Faux (tour complet), Marteau (onde de choc en zone).
   - Distance : Pistolet, Tromblon (éventail ×3), Arc (perforant), Baguette (tête chercheuse), Mortier (obus explosifs).
   - **Armes à ratio** (toutes raretés, en boutique seulement) : leurs dégâts suivent une stat. Plume solitaire (+60 % par emplacement d'arme libre), Rouleau à peinture (+15 % des PV max en dégâts), Chevalet-bouclier (+1,5 dégât par point d'armure), Aérographe (+1 % par % de vitesse), Cutter (critiques ×(2 + critique ÷ 35)), Compte-gouttes (+0,25 dégât par point de chance, plus d'effets élémentaires), Pinceau doré (+1 dégât par 12 or en poche), Règle graduée (+1,5 % par % de portée), Nuancier (+35 % par couleur sur ton perso), Silhouette (dégâts selon les pixels de ton perso, ×0,5 à ×3,5), Pipette (vol de vie ×3 sur ses coups, +5 % de base ; au-delà de 100 %, plusieurs PV par coup). La boutique affiche la valeur actuelle du ratio, et la taille de ton perso (pixels, couleurs) sous l'autoportrait.
   - **Armes spéciales** (jamais au choix de départ, seulement en boutique) :
     - Épiques ou plus : **Pinceau** (balaie et laisse une traînée d'encre qui brûle les ennemis), **Compas** (tourne sans arrêt autour de toi), **Tampon** (imprime ton dessin ×2 au sol : seuls les ennemis sous l'encre sont touchés, ×1,5 dégâts).
     - Épiques ou plus (suite) : **Ciseaux** (exécute sous 25 % des PV), **Agrafeuse** (épingle 1 s ; deux ennemis agrafés à la suite sont reliés et se partagent 50 % des dégâts), **Loupe** (rayon continu, ×1 → ×4 en restant sur la cible), **Brumisateur** (cône qui mouille : −30 % de vitesse, +25 % de dégâts Foudre/Glace), **Avion en papier** (aller-retour qui transperce deux fois), **Crayon HB** (+3 % par coup donné dans la vague, jusqu'à +150 %), **Éventail** (repousse très fort, choc contre les bords).
     - Légendaires (suite) : **Retouche** (15 % des ennemis tués sont redessinés dans ton camp 10 s), **Miroir déformant** (toutes les 2 s, renvoie les tirs ennemis proches), **Encre de Chine** (marque ; un marqué qui meurt éclabousse et marque ses voisins, en chaîne), **Grande Signature** (toutes les 8 s, une signature géante traverse l'écran ; plus forte avec les ennemis tués dans la partie), **Point final** (point noir qui aspire puis implose).
     - Légendaires uniquement : **Gomme sacrée** (un long trait de gomme : 30 % de chances d'effacer net un ennemi, 15 % pour un élite, sinon 25 % de ses PV ; les boss perdent 3 % ; efface aussi l'encre ennemie au sol), **Palette vivante** (un orbe chercheur par couleur du dessin, avec son effet élémentaire garanti ; pas de balles à dessiner), **Autoportrait** (envoie un clone de ton perso qui court vers l'ennemi et explose ; pas de balles à dessiner).
   - Chaque type et chaque amulette a sa propre quantité d'encre (et ses balles aussi).
4. **15 vagues**, un **boss toutes les 5 vagues** (vague 5 : Le Raturé, vague 10 : Le Critique *ou* La Muse, vague 15 : La Toile Blanche). La difficulté est calée pour que la vague 15 soit aussi dure que l'ancienne vague 20. Un nouvel ennemi apparaît régulièrement et tu dois le dessiner la première fois que tu le croises. Même chose pour ses projectiles.
   - Les boss sont costauds : PV revus à la hausse (Raturé 2400, Critique 7000, Muse 5000, Toile Blanche 26000, avant les multiplicateurs de difficulté et de dessin), +30 % de dégâts et +12 % de vitesse. Avec un build typique du moment, un combat dure environ 25 s (vague 5), 30-40 s (vague 10) et 1 min (vague 15). Mesure : `res://tests/bosstime.tscn`.
   - Vague 5 : mini-boss *Le Raturé*
   - Vague 10 : boss *Le Critique*
   - Vague 15 : mini-boss *La Muse*
   - Vague 20 : boss final *La Toile Blanche*
5. **Les PV ne remontent pas entre les vagues.** La boutique propose parfois une potion (Fiole d'encre 30%, Grand flacon 70%), mais pas à chaque fois.
6. Entre les vagues, la **boutique** propose des armes et des amulettes (à dessiner si c'est la première fois, puis à poser, avec rotation R et miroir M pour les amulettes), une relance et la vente d'armes. **Plus l'offre est rare, plus tu as d'encre pour la dessiner** (armes ×1 / ×1,2 / ×1,5 / ×2, soit au plus 10 / 12 / 15 / 20 % de la surface de la toile ; amulettes ×1 à ×2). Les ennemis lâchent de l'or avec parcimonie (l'XP, elle, ne baisse pas).
7. **Montée de niveau** : après la vague, pour chaque niveau gagné tu choisis 1 bonus parmi 3 (rareté tirée comme en boutique : plus tu avances et plus ton niveau est haut, plus le rare sort), puis tu dessines une petite **marque d'encre** (plus le bonus est rare, plus elle peut être grande : 10 à 34 d'encre) (tatouage, cicatrice...) que tu poses sur ton perso. Elle ne compte pas dans sa taille : il ne devient ni plus gros ni plus lent. Sa couleur donne un peu de résistance. Bouton « Passer » pour ne pas dessiner.
8. En fin de partie, tu gagnes des **pigments**. L'**Atelier** (mur de planches, établi et tableau en liège) :
   - **Établi (pigments)** : Encrier, Grande toile, Étal élargi, Relance offerte, Bourse.
   - **Succès (tableau en liège)** : chaque succès débloque une amélioration. Terminer la vague 3 → pack primaire ; vaincre le boss de la vague 5 → pack secondaire ; 500 ennemis effacés → gros pinceaux ; 15 dessins en galerie → ligne ; vague 8 → rectangle ; boss de la vague 10 → ellipse ; niveau 10 → symétrie ; une arme légendaire → dégradé ; une vague sans perdre de PV → encre pulsante ; gagner une partie → encre scintillante ; gagner en Aquarelle ou plus → encre arc-en-ciel. Un succès obtenu **pendant une partie** est marqué tout de suite (bandeau « débloqué à la fin de la partie », sablier ⌛ sur le tableau de l'Atelier), mais son amélioration n'arrive qu'**à la fin de la partie** : victoire, défaite, abandon, ou partie en cours remplacée par une nouvelle. Les récompenses en attente sont sauvegardées (rien n'est perdu si tu quittes le jeu). L'écran de fin fait le récapitulatif « Nouveautés débloquées ». Hors partie (ex. galerie remplie depuis le Bestiaire), c'est immédiat. Les anciennes sauvegardes gardent ce qui était déjà débloqué.

**Encre = traits seulement** : seuls les pixels de contour (au bord du dessin) coûtent de l'encre ; remplir ou colorier l'intérieur d'une forme est gratuit. Chaque dessin peut avoir ou non un **contour noir** en jeu (bouton « Bord » ou touche C, avec aperçu).

**Prix** : tout coûte plus cher au fil des vagues (×1 en vague 1, ×4,7 en vague 20). Chaque relance coûte plus cher que la précédente (remis à zéro à chaque boutique), et le prix de base des relances monte avec les vagues. En boutique, un objet déjà dessiné montre son dessin ; sinon un « ? ».

**Sens des armes** : dessine le manche (ou la crosse) à gauche et la pointe (ou le canon) à droite ; un repère est affiché sur la toile. En combat, c'est toujours le côté droit du dessin d'origine qui vise l'ennemi et d'où partent les tirs. R (tourner) et M (miroir) au rangement ne changent que la **pose au repos**, qui passe en miroir quand le perso se retourne.

**Rareté** (boutique et bonus de niveau) : épique à partir de la vague 6 (6 %, puis +2 % par vague), légendaire seulement sur les 5 dernières vagues (3 %, puis +2 % par vague). Couleurs : commun gris, rare **bleu**, épique violet, légendaire or. La chance avance ces paliers de 2 vagues au plus. Les chances actuelles sont affichées dans l'infobulle de « Nouvel accrochage ». Mesure : `res://tests/raritytable.tscn`.

Pendant le dessin d'une arme, de ses balles ou d'une amulette, l'aperçu **« sur le perso »** (touche V) montre l'objet à côté de ton perso, à la même échelle. Les **boss** ont de grandes toiles et doivent utiliser **au moins 95 % de leur encre**.

Le pot de peinture (Remplir, touche F) est disponible dès le départ. En jeu, la caméra zoome ×1,5 par défaut : molette ou + / - pour régler (sauvegardé).

Chaque dessin validé va dans la **Galerie** et se réutilise dans les parties suivantes.

**Pourboire** (stat) : or gagné automatiquement à chaque fin de vague (amulettes Pièce et Mécène, bonus de niveau).

## Effets (« juice »)

Fin de vague : toutes les gouttes restées au sol s'envolent vers le perso (les plus proches d'abord) et sont comptées en arrivant. Chaque goutte donne de l'XP et un peu d'or (environ 62 % de sa valeur).

Particules d'encre à chaque coup (couleur de l'ennemi, blanches en critique) et grosse éclaboussure à chaque mort ; ennemis qui s'écrasent quand on les frappe ; chiffres de dégâts qui sautent (critiques plus gros) ; traînée colorée derrière les coups de mêlée (et le Compas) ; éclat au canon des armes à distance ; voile rouge sur les bords de l'écran et arrêt sur image quand tu es touché ; arrêt sur image à la mort d'une élite ou d'un boss ; explosion de particules à la montée de niveau ; bannières de vague qui « popent ». Tout est dans `arena.gd` (`burst`, `hitstop`, `hit_fx`, classe `_Sparks`).

## Cartes

- **La Feuille** (carte de départ) : les ennemis et boss d'origine.
- **Le Tableau noir** : débloquée en gagnant une partie sur La Feuille (Esquisse ou plus dur) ; choix de la carte avant la difficulté. Sol de tableau noir, ennemis et boss **à elle**, et des **événements** en pleine vague (toutes les 11-15 s, hors boss) :
  - *Coup d'éponge* : une bande est annoncée, puis une éponge la balaie (blesse tout le monde, efface l'encre au sol).
  - *Pluie de craies* : des impacts annoncés tombent (dont deux près de toi) et laissent de la poussière qui ralentit.
- Ennemis du Tableau noir : **Punaise** (vise, fonce, reste plantée), **Craie** (projectiles suspendus qui partent ensemble), **Trombones** (par deux, reliés par un fil qui coupe), **Tampon encreur** (saute et s'écrase sur un carré annoncé), et trois **tanks** peu sensibles au recul, rares (jamais plus de 2 à la fois) : **Brouillon** (70 PV, se froisse deux fois : plus petit, plus rapide, crache des boulettes), **Gomme mie de pain** (90 PV, efface tes projectiles autour d'elle), **Équation** (110 PV, fait apparaître des punaises).
- Boss du Tableau noir : **Le Professeur** (vague 5 : interros surprises, une question de calcul s'affiche en haut et chaque colonne du tableau porte une réponse ; seule la colonne de la bonne réponse n'explose pas, 3,2 s pour y aller, 4 colonnes et multiplications en rage), **La Photocopieuse** (vague 10 : chaque salve a une copie tirée du côté opposé, scanner qui balaie l'écran, bourrage papier = vulnérable), **L'Encrier renversé** (vague 15 : inondations d'encre, spirales, charges ; en rage, la **nuit d'encre** ne laisse voir qu'autour de toi).
- **Difficultés par carte** : chaque carte a ses propres difficultés débloquées (gagner en Croquis sur La Feuille n'ouvre pas Aquarelle sur Le Tableau noir). Les anciennes sauvegardes gardent leur progression sur La Feuille.
- **Bestiaire** : tant qu'une carte n'est pas débloquée, ses ennemis et boss apparaissent en « ??? » (ni nom, ni dessin, ni description).
- Tests : `res://tests/map2test.tscn`.

## Ennemis (comportements pensés autour du dessin)

Plus tu mets d'encre dans un ennemi, plus il a de PV (×0,6 à ×1,4) et plus il lâche d'or (×0,5 à ×2). Sa couleur donne son élément. Les boss doivent utiliser au moins 95 % de leur encre.

| Ennemi | Comportement |
|---|---|
| Tache | Avance par **bonds**, chaque atterrissage laisse une flaque qui ralentit |
| Gribouille | Zigzague en laissant des **traits d'encre** qui font mal |
| Crachoir | Tire des pâtés **en cloche** là où tu es, puis s'enfonce et réapparaît ailleurs |
| Bélier | Trace une **ligne à la règle** puis fonce dessus jusqu'au bord de la page |
| Scinde | Se place **en miroir** de toi et renvoie des reflets ; se divise en deux (miroirs horizontal/vertical) |
| Éclaboussure | Trace des **cercles au compas** de plus en plus serrés autour de toi, tire en éventail |
| Colosse | **Gomme géante** qui rebondit sur les bords comme un logo de DVD |
| Pâté | **Taches piégées** posées en ligne : elles gonflent et explosent quand tu approches |

Boss : le Raturé rature le sol pendant ses charges ; le Critique lance des pâtés en cloche ; **la Toile Blanche gomme des morceaux de ton perso** (−12 % PV max par coup, jusqu'à la fin de la vague, puis tout revient).

**Élites** (Aquarelle et au-delà) : à partir de la vague 4, une fois par vague, tu redessines un ennemi en version élite (ton dessin + des ajouts). Aura, PV ×3, butin ×3.

Des **flèches** au bord de l'écran montrent les ennemis hors champ (rouge = boss, jaune = élite, orange = tireur, gris = proches).

## Carnet des ennemis (bestiaire permanent)

Quand un ennemi, un boss ou un élite apparaît pour la première fois dans une partie, le jeu ouvre ton **carnet** :
- s'il y est déjà : **Garder ce dessin** (par défaut) ou **Redessiner** en partant de l'ancien (+2 ◆ ennemi, +3 élite, +5 boss si tu le modifies) ;
- sinon : choisis d'abord un **dessin existant de ta galerie** (taille et encre compatibles, 95 % pour les boss), ou dessine-le.

Le carnet est conservé d'une partie à l'autre (`%APPDATA%/VowelGame/bestiary/`). Les **projectiles ennemis ne se dessinent plus** : ce sont des gouttes d'encre de la couleur de l'ennemi.

## Raretés d'armes : un dessin par rareté

Chaque **rareté** d'un type d'arme a **son propre dessin**, avec sa propre quantité d'encre (plus la rareté est haute, plus il y a d'encre). Les exemplaires des autres raretés **gardent leur dessin**.
- Acheter ou fusionner vers une rareté pas encore dessinée dans la partie ouvre un dessin :
  - si le Bestiaire a un dessin pour **cette rareté** : il est proposé (utiliser, modifier ou nouveau) ;
  - sinon : tu **retouches** le dessin d'une autre rareté avec l'encre de celle-ci. En fusion, pas de bouton retour : il faut valider un dessin.
- Le premier dessin fait pour une rareté devient son dessin par défaut dans le Bestiaire.
- Les balles sont communes à toutes les raretés du type.
- Avec **6 armes**, acheter une arme identique (même type, même rareté) à l'une des tiennes la **fusionne directement**.

## Sélection avant dessin et Bestiaire

Avant **chaque** dessin (perso, armes, balles, amulettes, marques, ennemis), un écran propose d'abord un dessin existant : le dernier utilisé pour cet objet dans le grand cadre, et ta galerie à droite. Cliquer un dessin de la galerie le **met dans le cadre** : « Utiliser ce dessin », « Modifier » (repart de lui) ou « Nouveau ». Bouton **« Bord : oui / non »** avec aperçu.

Le **Bestiaire** (menu principal) liste toutes les armes, amulettes et ennemis avec leurs stats, et permet de choisir leur **dessin par défaut** (pour les armes : un par rareté, plus les balles) (depuis la galerie, en le dessinant, ou le retirer). En partie, ce dessin est **le dessin par défaut** : il n'est proposé que la **première fois** que tu obtiens l'objet dans la partie (« Utiliser ce dessin », « Modifier » ou « Nouveau »), et ce que tu dessines en partie **ne remplace pas** le dessin du Bestiaire (un objet sans dessin par défaut prend le premier que tu fais).

## Synergies, fusion, pactes

- **Synergies de couleur** (3 armes d'un même élément dominant) : Feu = brûlure contagieuse, Glace = les gelés éclatent en éclats, Foudre = chaînes à 4 cibles, Poison = nuage toxique, Arcane = marque doublée, Lumière = les éclats soignent.
- **Fusion** : 2 exemplaires du même type et de même rareté → 1 de rareté supérieure, avec de l'encre en plus pour agrandir le dessin.
- **Bonus / malus** : les amulettes simples ont un défaut ; certains choix de niveau sont des **pactes** (bonus doublé mais un attribut baisse).
- **Amulettes légendaires uniques** : une seule de chaque par partie. Une fois achetée, elle ne revient plus en boutique, et la vitrine ne propose jamais deux fois la même.

## Amulettes (55)

- Communes, nouvelles : Taille-crayon, Buvard, Gouache, Fixatif, Chevalet.
- Rares, nouvelles : Calque (+1 perforation), Estompe (chaque coup ralentit), Mine de plomb (critiques plus forts), Sanguine (soin sur élimination), Craquelure (les critiques explosent), Mécène (pourboire : or à chaque fin de vague).
- Épiques, nouvelles : Cadre doré (dégâts selon l'or en poche), Collage (dégâts par type d'arme différent), Croquis rapide (+60 % de vitesse d'attaque les 10 premières secondes), Tache indélébile (+40 % de dégâts mais une tache noire sur le perso), Perspective (portée, plus de dégâts de loin, moins de près).
- Légendaires (uniques) : Chef-d'œuvre, Double trait, Arc-en-ciel, Encrier, Sablier brisé, et les nouvelles La Joconde (+12 % de dégâts par vague finie sans perdre de PV), Double exposition (25 % des attaques se relancent), Musée ambulant (7 emplacements d'arme), Trompe-l'œil (30 % des tirs ennemis déviés), Restauration (soigne 30 % en début de vague, -15 % d'or), Renaissance (revient une fois à 50 % des PV), Horloge (toutes les 12 s, le temps s'arrête 2 s : ennemis et tirs figés, tes armes ×2).

## Tutoriel

Des **conseils contextuels** apparaissent une seule fois, au moment où tu découvres chaque mécanique (premier dessin de perso, d'arme, de balles, d'ennemi, couleurs, carnet, pose, niveau, boutique, Atelier, fin de partie). À la vague 1, le jeu se met en pause pour expliquer les contrôles ; pendant les vagues, de petits bandeaux (flaques, boss, PV bas, élites). Désactivables et « Revoir les conseils » dans les Options. Textes : `scripts/ui/tips.gd`.

## Options

Volume, plein écran, vitesse du jeu (×0,75 à ×1,5), zoom par défaut. Depuis le titre ou le menu pause.

## Comment un dessin devient des stats

Tout est dans `scripts/core/stats.gd`. C'est le fichier à modifier pour équilibrer (ou casser) le jeu.

| Dessin | Ce qui compte | Effet |
|---|---|---|
| **Perso** | Nombre de pixels | + PV mais − vitesse, et une hitbox plus grosse |
| | Symétrie | Esquive |
| | Dessin plein / traits fins | Armure / critique |
| | Morceaux séparés | Chance |
| | Grand / large | Portée / armure |
| **Arme de mêlée** | Taille du dessin | Petite = coups rapides + critique (jusqu'à +25 %) ; grosse = gros coups, recul. **Dégâts/s presque identiques** |
| | Longueur | Allonge (et zone du marteau) |
| | Symétrie | Critique |
| **Arme à distance** | Taille de l'arme et des balles | Petites = rafales rapides + critique ; grosses = tirs lents et forts. **Dégâts/s presque identiques** |
| | Symétrie | Précision |
| **Balles** | Taille de chaque morceau | Grosse = lente mais forte |
| | Forme | Allongée = perforante |
| | **Chaque morceau séparé** | **Un projectile en plus** (tirés en formation) |
| **Ennemi** | Encre utilisée | + PV, mais + butin (risque / récompense) |
| | Couleur dominante | Élément de ses attaques, et il résiste à cet élément |
| **Projectile ennemi** | Taille | Gros = lent mais facile à toucher |
| **Amulette** | Taille / encre utilisée | Rien : l'effet est toujours celui indiqué |
| | Couleur | Résistance à l'élément |
| | Endroit où tu la poses | Bonus de zone : tête, cœur, mains, pieds ou aura |

### Couleurs = éléments

| Couleur | Sur le perso | Sur une arme |
|---|---|---|
| Rouge (Feu) | + dégâts | Brûlure |
| Bleu (Glace) | + armure | Ralentit, puis gèle |
| Jaune (Foudre) | + vit. d'attaque | Éclairs en chaîne |
| Vert (Poison) | + régénération | Poison cumulable |
| Violet (Arcane) | + vol de vie | Marque (+25% dégâts subis) |
| Blanc (Lumière) | + esquive | Explosion de lumière |

Chaque couleur donne aussi une résistance à son élément. La proportion de pixels de chaque couleur fixe la chance de déclencher l'effet.
Avec le **dégradé**, un mélange rouge → bleu donne du violet au milieu, donc de l'Arcane.

Encres animées (−15% d'encre) : **Pulse** (+vitesse d'attaque), **Scintille** (+critique et +esquive), **Arc-en-ciel** (un peu de chaque élément).

## Ce qui rend le jeu « cassable »

- 12 petits points comme balle = 12 projectiles, et chacun peut déclencher les effets élémentaires.
- **Miroir** (+1 rafale), **Prisme** (+15% de chaque élément), **Rune** (+chances d'effets) se cumulent.
- **Esquisse** : un perso minuscule (< 120 px) gagne +40% de dégâts.
- **Chef-d'œuvre** multiplie ×1.5 tout ce que donne ton dessin (légendaire, donc une seule fois par partie).
- **Palette vivante** + un perso/arme multicolore = une pluie d'orbes élémentaires garantis. **Tampon** + un gros dessin plein = une énorme zone.
- **La Joconde** : chaque vague parfaite ajoute +12 % de dégâts, pour toute la partie.
- **Palette** : +8% de dégâts par couleur sur ton perso.
- Dessiner des ennemis énormes rapporte plus d'or, mais ils sont plus durs à tuer. Les dessiner dans ta couleur de résistance réduit leurs dégâts, mais ils résistent à tes armes de cette couleur.
- **Double trait** : tes armes de mêlée lancent aussi leur propre dessin.

## Arborescence

```
scripts/
  main.gd              enchaînement des écrans (async/await)
  autoload/            UI (thème + police), Meta (sauvegarde), Run (partie), Sfx (sons générés)
  core/                pal (palette/éléments), analyzer (analyse des dessins), stats, draw_cfg, pixel_font
  data/                weapon_db, enemy_db, amulet_db, unlock_db   <- ajouter du contenu ici
  game/                arena, player, weapon_node, enemy (comportements + boss), projectile, pickup, hud, gfx
  ui/                  draw_screen (+canvas_view), shop, place_screen (armes + amulettes), title, atelier, gallery, choice_screens
shaders/sprite.gdshader  contour 1px, flash, teintes de statut, encres animées
```

Il n'y a aucun asset externe : la police pixel, les sons 8 bits et le décor papier sont générés en code.
Sauvegarde : `%APPDATA%/VowelGame/`.

## Idées pour la suite

- **Styles d'artiste** (comme les persos de Brotato), à débloquer : *Cubiste* (rectangles seulement, +armure), *Pointilliste* (pinceau 1 px, chaque morceau séparé donne de la chance), *Minimaliste* (−50% d'encre, ×2 dégâts).
- **Fusion d'armes** : deux armes identiques se collent côte à côte pour faire une arme plus grande (l'équivalent des tiers de Brotato).
- **Tache indélébile** (objet maudit à la Isaac) : +30% de dégâts, mais une grosse tache noire s'ajoute au hasard sur ton perso, qui devient plus lourd et plus lent.
- **Boss vaincus = alliés** : un boss que tu as dessiné et battu peut revenir comme invocation dans une prochaine partie.
- **Sets de couleur** : 3 armes de la même couleur débloquent un bonus (feu qui se propage, glace qui fait éclater les ennemis gelés).
- **Contraintes d'atelier** : défis optionnels (« dessine ton arme avec 40 pixels max ») qui rapportent des pigments bonus.
- **Défi du jour** : même graine et palette imposée pour tout le monde.
- **Musique chiptune** (pas encore de musique, seulement des bruitages).

# Carte 3 : « L'Écran » — fiche de conception

> Statut : **conception validée le 2026-10-10, rien n'est codé.** À développer plus tard.
> Les chiffres sont des points de départ (calqués sur Le Tableau noir), à régler en jouant.

## L'idée

Après la feuille de papier (La Feuille) et la salle de classe (Le Tableau noir), on dessine sur
ordinateur : un logiciel de dessin, un vieux bureau avec ses fenêtres et ses icônes.

Ce qui la différencie des deux autres cartes : **le jeu se retourne contre le joueur à travers
l'écran lui-même** (bugs, fenêtres, plantages), et **la souris devient un outil de jeu** pendant
certains combats.

- **Déblocage** : gagner une partie sur Le Tableau noir (Esquisse ou plus dur).
- **Décor** : damier gris et blanc (le « fond transparent » des logiciels de dessin), grille de
  pixels ; les bords de l'arène ressemblent à une fenêtre avec sa barre de titre.
- **Pas de marque réelle** : ni nom de système, ni nom de logiciel, ni logo existant.

## La règle de la carte : les bugs

De temps en temps pendant une vague, un bug frappe quelques secondes. Sur la carte, les bugs sont
**légers** : surtout visuels, courts, jamais mortels à eux seuls. (Les gros bugs sont réservés au
boss « Le Bug ».)

| Bug | Effet | Durée |
|---|---|---|
| Image figée | l'image se fige (le jeu continue derrière) | 0,5 s |
| Couleurs inversées | tout l'écran en négatif | 4 s |
| Décalage | une bande de l'écran est décalée de quelques pixels | 4 s |
| Traînée | ton perso laisse une traînée de copies fantômes | 5 s |

- Un bug toutes les 15 à 25 s, annoncé par un petit grésillement 0,5 s avant.
- Jamais deux bugs en même temps sur la carte (c'est le boss qui les enchaîne).
- À décider en jouant : un bug qui aide le joueur de temps en temps (ex. « les ennemis se figent 1 s »).

## Les ennemis

| Ennemi | Vague | Comportement |
|---|---|---|
| **Curseur** | 1 | Flèche de souris rapide : fonce en ligne droite, s'arrête net, repart. Parfois il te « clique » : un coup à distance après un bref signal. |
| **Fichier corrompu** | 2 | Immobile et inoffensif. Au bout de ~6 s, il « s'ouvre » et libère un groupe de 3 à 5 ennemis. À détruire avant : une cible à prioriser. |
| **Corbeille** | 3 | Avale les pièces d'or au sol. Tuée, elle recrache tout. |
| **Pot de peinture** | 4 | Remplit une zone d'une couleur d'un coup ; la zone fait des dégâts de cet élément pendant quelques secondes. |
| **Copier-coller** | 6 | Quand il touche un autre ennemi, il en fait une copie (pas les boss ni les gros). À tuer en priorité. |
| **Sablier** (gros) | 8 | Lent et costaud. Tout ralentit autour de lui, le joueur compris. |
| **Lasso** | 9 | Trace un contour autour du joueur ; s'il le referme, le joueur est coincé dedans 2 s. |
| **Barre de chargement** (gros) | 11 | Avance par à-coups, se charge en restant immobile, puis lâche une grosse attaque quand la barre est pleine. Elle se vide quand on la frappe. |

Points de départ pour les stats : reprendre l'échelle du Tableau noir (Punaise 6 PV → Équation
110 PV, dégâts 4,5 → 8), même rythme d'arrivée.

## Les boss

### Vague 5 : « Le Virus »

- Il fait apparaître des **fenêtres par-dessus le jeu** : fausses pubs, « Vous avez gagné ! »,
  fausse mise à jour.
- **Clavier-souris** : on ferme une fenêtre en cliquant sur sa croix. Variantes : croix minuscule,
  croix qui fuit la souris, **faux captcha** (« clique sur toutes les taches », « je ne suis pas un
  gribouillis »).
- **Manette** : un **QTE de 3 touches** affiché sur la fenêtre, à presser dans l'ordre ; une erreur
  et on recommence la suite. (Le jeu détecte le dernier périphérique utilisé.)
- Pendant ce temps le perso continue de se battre : il faut gérer les deux à la fois.
- Trop de fenêtres ouvertes : on ne voit plus rien. Plafond à fixer (ex. 8) pour rester jouable.

#### Les fenêtres du Virus (textes validés le 2026-10-10)

Le ton : des parodies des pubs louches d'Internet, où tout tourne autour du dessin.

Pubs « chaudes » :
- « STOP ! Arrête de te dessiner : elle est FRAÎCHE et près de chez toi. Nouveau pot de peinture. »
- « Tu veux AGRANDIR la taille de ton pinceau ? »
- « Des toiles VIERGES dans ta région n'attendent que toi. »
- « Pinceaux célibataires à moins de 2 pixels de toi. »
- « Marre des traits trop courts ? Tiens 15 vagues sans recharger ton encre. »

Arnaques, pièges à clics, faux messages :
- « Un prince de la Feuille veut te léguer 4 000 000 de pigments. Il lui faut juste ton numéro de palette. »
- « Ce boss a une faiblesse cachée. La n°7 va te choquer. »
- « Mémoire pleine : supprimer 3 de tes amulettes ? [Accepter] » (aucun effet réel sur les amulettes)

Faux captchas :
- « Clique sur toutes les cases qui contiennent une TACHE. »
- « Recopie ce mot », avec un mot illisible écrit à la craie (à la manette : le QTE de 3 touches à la place).
- « Prouve que tu es un artiste : clique sur le rond. » (il n'y a que des carrés ; au bout de 2 secondes, un des carrés devient rond : c'est lui qu'il faut cliquer)

Mécaniques des fenêtres :
- **Boutons piégés** : sur certaines, le gros bouton « FERMER » ouvre deux fenêtres de plus ; la
  vraie croix est minuscule dans un coin.
- **Vraie récompense rare** : une pub sur vingt est honnête et donne quelques pièces d'or si on
  clique dessus, pour que le joueur hésite avant de tout fermer.
- **Clin d'œil à La Porte** : une fenêtre « Quelqu'un frappe à ta porte ? Ce n'est pas nous. »,
  seulement si le joueur a l'amulette.

### Vague 10 : un des deux, tiré au sort

**« Le Bug »** — les gros bugs, qu'il enchaîne :
- commandes inversées, écran à l'envers, téléportation du joueur quelques pas en arrière, barre de
  vie qui affiche n'importe quoi ;
- chaque bug est annoncé 1 s avant (dur mais juste) ;
- il se déplace en se téléportant, avec des images fantômes.

**« Le Tableur »** — l'arène devient une grille de cases :
- des lignes et des colonnes entières s'allument avant d'exploser ;
- il applique une **formule** aux stats du joueur pendant quelques secondes (« dégâts ÷ 2 »,
  « vitesse × 1,5 »), affichée dans une barre de formule en haut ;
- il fait la **somme** des ennemis d'une colonne pour les fusionner en un gros.

### Vague 15 : « Le Curseur »

Une main-curseur géante qui utilise les outils de dessin ; quand elle prend cher, le jeu plante.

- **Phase 1 (100 → 60 % PV), les outils** : la gomme efface une bande de l'arène (interdite
  quelques secondes) ; le lasso se referme autour du joueur ; le pot de peinture inonde une zone ;
  la pipette vole la couleur du joueur et donne sa résistance au boss.
- **Premier plantage (60 %)** : image figée, faux écran d'erreur bleu 1 s, « redémarrage » : arène
  plus petite, entourée d'une bordure de fenêtre.
- **Phase 2 (60 → 25 %), les outils du système** : Ctrl+Z (il récupère les PV de ses 3 dernières
  secondes, sauf si on l'interrompt en le frappant assez fort) ; copier-coller (il duplique l'ennemi
  le plus fort présent) ; glisser-déposer (il attrape le joueur et le lâche ailleurs).
- **Second plantage (25 %)** : écran bleu plus long, avec un faux pourcentage de récupération.
- **Phase finale** : il attrape le bord de la fenêtre et la referme petit à petit ; l'arène
  rétrécit en continu, il faut le finir avant d'être écrasé.

## Points à surveiller au développement

- **Cumuls avec des amulettes existantes (décidé)** : Tête à l'envers (écran retourné) et Le Stream
  (commandes inversées) font déjà ce que fait Le Bug. Si le joueur a déjà l'effet au moment où le
  boss veut le lancer, **ce bug est ignoré : le boss en choisit un autre**. Pas de double
  inversion, et le bonus de l'amulette n'est pas touché.
- **Souris pendant une vague** : c'est nouveau dans le jeu (aujourd'hui elle ne sert qu'aux menus).
  Vérifier le zoom à la molette et le clic du Sifflet.
- **Accessibilité** : les couleurs inversées et l'image figée peuvent gêner ; prévoir une option
  pour adoucir les bugs visuels.
- **Écran d'erreur bleu** : un faux, dans la fenêtre du jeu, sans imiter un vrai système.
- **Technique** : une 3e carte dans MapDB (`"floor": "screen"`), 8 ennemis et 4 boss dans EnemyDB
  (`"map": 3`), leurs dessins à faire par le joueur comme les autres, les déblocages (`map:3`), le
  Codex, les défis.
- **Écartés pendant la conception** : le Pixel mort (ennemi), les calques et l'historique Ctrl+Z
  (règles de carte), L'Antivirus et La Mise à jour (boss de la vague 10).

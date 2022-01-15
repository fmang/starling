Starling
========

Starling est un projet de bot SMS. Pas tout à fait un chatbot mais plutôt une
façon d’envoyer des commandes par SMS à une machine connectée à Internet qui
saura donner une réponse selon la commande envoyée.

Starling signifie étourneau, qui est un oiseau très cool. Il s’avère qu’il
rôdait en Essonne lorsque je me suis enfin décidé à lancer ce projet.

Matériel
--------

Pour faire tourner Starling, il faut :

1. une machine Linux,
2. un modem GSM compatible Gammu.

Chez moi, il s’agit d’un Raspberry Pi 2 avec un dongle Huawei E3131.

Pour que le dongle soit reconnu comme modem USB et non comme périphérique de
stockage, il m’a suffit d’installer usb_modeswitch.

Pour faire ensuite en sorte que le périphérique ait un nom constant et soit
accessible avec l’utilisateur Starling, faire une règle udev. La règle udev en
ce qui me concerne est la suivante :

```
SUBSYSTEM=="tty", ATTRS{idVendor}=="12d1", ATTRS{idProduct}=="1506", ENV{ID_USB_INTERFACE_NUM}=="03", GROUP="gsm", MODE="0660", SYMLINK+="ttyGSM"
```

Architecture
------------

La brique centrale de Starling est le répartiteur. Il est connecté d’une part à
un pilote pour interagir avec le réseau GSM, et d’autre part à un ensemble de
modules, chacun traitant une commande. Ainsi, si le pilote signale qu’un SMS
« hello world » arrive, le répartiteur le transférera au module *hello*, puis
retransmettra en sens inverse la sortie du module vers le pilote comme réponse.

Quoiqu’il n’est pas exactement conçu pour les bots, le daemon gammu-smsd fait
le travail en tant que pilote. Utilisons-le donc tant qu’il répond à peu près à
nos besoins. Pour l’intégrer à Starling, il suffit de configurer dans
gammu-smsdrc la directive RunOnReceive avec le chemin vers l’exécutable du
répartiteur, c’est-à-dire l’exécutable `starling`.

Les modules sont une collection de programmes, indépendants ou non, réagissant
aux SMS reçus. C’est eux qui implémentent toute la logique des commandes. Le
module sélectionné par le répartiteur dépend uniquement du premier mot du SMS.
Voir le protocole pour la définition plus concrète des modules.

Protocole des modules
---------------------

Un module est un fichier exécutable, ou un lien symbolique vers un fichier
exécutable, situé directement sous le dossier `modules/` de l’installation
Starling.

À la réception d’un SMS, le module est appelé. Le contenu du SMS est envoyé en
UTF-8 sur son entrée standard. Le numéro de l’expéditeur est renseigné dans la
variable d’environnement SENDER. Aucun argument en ligne de commande n’est
spécifié.

Le module doit écrire sa réponse en UTF-8 sur sa sortie standard. La sortie
d’erreur remontera quant à elle dans les journaux de Starling. Si le module
termine avec le code 0, Starling enverra le SMS. Autrement, le SMS en cours
d’écriture sur la sortie standard est jeté, et l’erreur remontée dans les
journaux.

Les réponses trop longues pour un SMS sont automatiquement segmentées par
Starling, et celles trop longues même avec la segmentation seront tronqués.

Installation de Starling
========================

Comme le projet est fait pour être tripoté en permanence, Starling n’a hélas
pas un paquetage standard. Cependant, il est conçu pour être fonctionnel à
peine cloné. Le gros de la configuration est tout autour.

Les instructions ci-dessous sont données à titre indicatif.

Organisation des fichiers
-------------------------

Créons un utilisateur *starling*, et un groupe *gsm*.

Son $HOME aura l’allure suivante :

```
/home/starling/
├── data/
│   └── users.yml
├── dev/
│   └── starling/
├── gammu/
│   ├── smsd.log
│   ├── smsd.pid
│   └── smsdrc
└── spool/
    ├── error/
    ├── inbox/
    ├── outbox/
    └── sent/
```

où `dev/starling` est le clone du projet.

Starling
--------

Pour l’instant la configuration de Starling même est quasi-inexistante, à
l’exception du fichier `data/users.yml`. Il doit contenir un dictionnaire dont
les clés sont des numéros au format international, par exemple `+336XXXXXXXX`.
La sous-clé `name` indique le nom de l’utilisateur.

Les messages provenant d’autres numéros seront supprimés.

En cas de soucis de configuration, consulter `gammu/smsd.log` dans lequel
remonte la sortie d’erreur de Starling.

udev
----

Linux numérote les /dev/tty* de façon non déterministe par défaut. Pour qu’on
puisse avoir une configuration qui marche à chaque démarrage, il est utile de
rendre fixe le nommage du modem qui nous intéresse. udev permet aussi
d’attribuer un groupe et des permissions particulières, ce qui nous permettra
de lancer Gammu sans root.

Par exemple, pour ma clé Huawei E3131, la règle udev donne ça :

```
# /etc/udev/rules.d/huawei-3g.rules
SUBSYSTEM=="tty", ATTRS{idVendor}=="12d1", ATTRS{idProduct}=="1506", ENV{ID_USB_INTERFACE_NUM}=="03", GROUP="gsm", MODE="0660", SYMLINK+="ttyGSM"
```

gammu-smsd
----------

```
# /home/starling/gammu/smsdrc

[gammu]
Device = /dev/ttyGSM

[smsd]
LogFile = /home/starling/gammu/smsd.log

# Les fréquences par défaut sont trop lentes.
CommTimeout = 5
ReceiveFrequency = 5

Service = files
InboxPath = /home/starling/spool/inbox/
OutboxPath = /home/starling/spool/outbox/
SentSMSPath = /home/starling/spool/sent/
ErrorSMSPath = /home/starling/spool/error/

RunOnReceive=/home/starling/dev/starling/bin/starling
```

systemd
-------

Pour que Gammu soit lancé au démarrage, il faut créer un service systemd.
systemd fonctionne maintenant bien en utilisateur, donc profitons-en.

Je me suis beaucoup inspiré du gammu-smsd.service distribué avec Gammu, en
changeant les chemins pour suivre l’arborescence de Starling.

```
# /home/starling/.config/systemd/user/gammu-smsd.service

[Unit]
Description=SMS daemon for Gammu
After=network-online.target dev-ttyGSM.device

[Service]
Environment=GAMMU_SMSD_CONFIG=/home/starling/gammu/smsdrc
WorkingDirectory=/home/starling/data
ExecStart=/usr/bin/gammu-smsd --pid=/home/starling/gammu/smsd.pid --daemon --config=/home/starling/gammu/smsdrc
ExecReload=/bin/kill -HUP $MAINPID
ExecStopPost=/bin/rm -f /home/starling/gammu/smsd.pid
Type=forking
PIDFile=/home/starling/gammu/smsd.pid

[Install]
WantedBy=default.target
```

Il faut ensuite activer systemd par défaut pour l’utilisateur *starling* :

```
# loginctl enable-linger username
```

Et finalement, activer le service :

```
$ systemctl --user enable gammu-smsd
```

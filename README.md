Nginx static
============

Ce tutoriel explique comment configurer un serveur Nginx de fichiers statiques.

Offrir de bonnes performances sur des configurations limitées
-------------------------------------------------------------

Le but de cette configuration est d’**offrir de bonnes performances sur des configurations limitées**.

Pour y arriver, les objectifs sont les suivants :

- limiter la consommation processeur
	- servir des ressources statiques,
	- servir des ressources pré-compressées,
	- ne pas compresser à la volée
- limiter la consommation de la RAM
	- utiliser Nginx sans module supplémentaire,
	- ne pas utiliser de système de cache
- limiter l’utilisation des ressources réseau
	- supporter HTTP/2,
	- gérer la négociation `Accept` (webp, apng…),
	- gérer la négociation `Accept-Encoding` (gzip, deflate, br…),
	- gérer la mise en cache par le navigateur,
	- utiliser un niveau de compression élevé (Zopfli, Brotli, WEBP…)
- supporter des protocoles récents
	- supporter HTTP/2,
	- supporter TLS 1.3

À cela vient s’ajouter la contrainte d’un bon niveau de sécurité :

- limiter le recours aux langages dynamiques (PHP, Python…),
- abandonner les protocoles obsolètes,
- limiter le nombre de dépendances,
- utiliser des paquets officiels (proscrire la compilation).

Le serveur
----------

### Installer Debian 10.3 (Buster)

Récupérer une [image ISO pour installer Debian](https://www.debian.org/distrib/netinst).

Lancer l’installation en mode texte.

À l’écran "Sélection des logiciels", sélectionnez uniquement "serveur SSH" et "utilitaires usuels du système":

	[ ] environnement de bureau Debian
	[ ] ... GNOME
	[ ] ... Xfce
	[ ] ... KDE Plasma
	[ ] ... Cinnamon
	[ ] ... MATE
	[ ] ... LXDE
	[ ] ... LXQt
	[ ] serveur web
	[ ] serveur d'impression
	[*] serveur SSH
	[*] utilitaires usuels du système

### Installer les paquets

Installer les paquets suivants en tant qu’utilisateur `root`:

- Paquets utiles pour les conversions et optimisation d’images :
	- **webp**, pour convertir des images en WEBP,
	- **libjpeg-progs**, pour convertir des images en JPEG,
	- **zopfli**, compresseur GZip plus performant que GZip ou 7Zip,
	- **brotli**, compresseur Brotli,
	- **jpegoptim**, optimisation de JPEG,
	- **optipng**, optimisaion de PNG,
	- **pngnq**, optimisaion de PNG,
	- **pngcrush**, optimisaion de PNG,
- Paquets utiles pour l’installation de Nginx :
	- **curl**, dialoguer avec un serveur web,
	- **gnupg2**, système de chiffrement et signature électronique,
	- **ca-certificates**, autorités de certification,
	- **lsb-release**, récupérer le numéro de sa branche Debian,
	- **ssl-cert**, fournit des certificats auto-signés,

Utilisez les commandes suivantes :

	apt install -y webp libjpeg-progs zopfli brotli jpegoptim optipng pngnq pngcrush
	apt install -y curl gnupg2 ca-certificates lsb-release ssl-cert

### Installer Nginx

Nous n’utiliserons pas les paquets officiels Debian mais directement ceux fournis par Nginx.org.

L’installation suit la [procédure indiquée sur leur site](http://nginx.org/en/linux_packages.html#Debian), qui se résume en ces 4 lignes :

	echo "deb http://nginx.org/packages/debian `lsb_release -cs` nginx" > /etc/apt/sources.list.d/nginx.list
	curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add -
	apt update
	apt install -y nginx

Hormis de profiter d’une version stable plus récente que celle fournie par Debian, la différence réside dans l’organisation des fichiers qui ne suit pas le principe `sites-available` / `sites-enabled` etc. La configuration de Nginx se trouve dans le répertoire `/etc/nginx/conf.d`.

Au moment d’écrire ces lignes, la version stable de Nginx est la 1.16.1.

### Configurer Nginx

Écraser le fichier `/etc/nginx/conf.d/default.conf` avec le [fichier default.conf](default.conf) que vous modifierez à votre convenance.

Une fois le fichier modifié, relancer Nginx :

	service nginx restart

Préparer les fichiers
---------------------

La configuration Nginx static ne compresse aucun fichier à la volée contrairement à ce que l’on peut observer dans d’autres configurations. C’est parfaitement volontaire afin d’allonger le plus possible le travail du serveur web.

Cela permet également de pousser le niveau de compression de chaque fichier, ce qui ne serait pas envisageable dans le cas d’une compression à la volée.

Pour que le serveur web puisse fournir des fichiers compressés, il faut les pré-compresser. Il en va de même pour les images au format WEBP.

Les fichiers doivent avoir une extension particulière pour être identifiés par la configuration Nginx static :

- `.html.gz`, `.css.gz`, `.js.gz`, `.svg.gz`, `.xml.gz` et `.json.gz` pour les version compressées en GZip,
- `.html.brz`, `.css.br`, `.js.br`, `.svg.br`, `.xml.br` et `.json.br` pour les version compressées en Brotli,
- `.jpeg.webp`, `.png.webp` pour les images converties en WEBP.

Vous pouvez [utiliser le script precompress.bash](precompress.bash) à cette fin pour initialiser un projet mais une répense pérenne et pratique doit être apportée à ce problème. Le script parcourt tous les répertoires et sous-répertoires à partir de l’endroit où il est appelé :

	cd /var/www/html
	bash precompress.bash

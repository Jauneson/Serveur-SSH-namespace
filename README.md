# Serveur-SSH-namespace


Jean-Sébastien AUGE, M2 SSIR

Le script est à éxécuter avec les privilèges root. Il se décompose de la manière suivante:



Téléchargement et installation du serveur SSH

	mise à jour des dépots
	installation de SSH
	écriture du fichier de config:
		Le fichier de configuration est ici générique, mais il est possible de rendre notre serveur SSH plus robuste
		(permitRootLogin no, interdiction du X11 forwarding authentification uniquement par clef...)

Le séparer du réseau:
	
	Création d'un nouveau namespace séparé du réseau, sur lequel on le fera tourner

Gestion des ressources:

	ajout du serveur ssh dans les cgroups memory et CPU. L'ajout a un Cgroup se fait de la manière suivante:

		récupération du PID du serveur SSH
		édition du fichier de config du cgroup correspondant à la limite recherchée
			(exemple: /sys/fs/cgroup/memory/serveurSSH/cgroup.procs pour la mémoire)



Pistes d'amélioration:

	Ici, on doit exécuter notre script avec des droits root, ce qui n'est pas une très bonne chose. Un moyen de contourner ce problème
	serait de le lancer avec RootAsRole
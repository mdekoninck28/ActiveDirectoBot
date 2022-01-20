# ActiveDirectoBot
**Script permettant d'automatiser la création d'Unités d'Organisation et d'utilisateurs dans Active Directory.**

Le modèle de fichier CSV à remplir est fourni (fichier "*AD_users.csv*"). Format : CSV UTF-8 avec le point-virgule comme séparateur. 

Toutes les colonnes n'ont pas besoin d'être remplies, il faut au minimum un nom, un prénom, une unité d'organisation (si elle n'existe pas elle sera automatiquement créée), et un mot de passe. Le script permet aussi de choisir si les utilisateurs créés doivent changer leur mot de passe lors de la première connexion.

Une fois le fichier CSV rempli, lancer le script "*Script.ps1*" et répondre aux questions posées :

   -Nom du domaine : indiquer le nom du domaine Active Directory concerné. Il doit comporter un préfixe et ne pas avoir de sous-domaine. Exemple valide : "*test.local*".
    
   -Unité d'organisation racine : indiquer l'unité d'organisation à la racine de l'annuaire du accueillera les unités d'organisation enfant.
    
   -Changement de mot de passe à la première ouverture de session : indiquer par *O* (oui) ou *N* (non) si les utilisateurs devront changer leur mot de passe lors de leur première connexion.
    
   -Chemin du fichier CSV : indiquer l'emplacement du fichier CSV contenant la liste des utilisateurs  à importer.

Le script doit être executé sur une machine du domaine avec un compte d'utilisateur **Administrateur du domaine**.

L'identifiant de connexion (login) généré correspond aux deux premières lettre du prénom + le nom. Exemple pour Jean Dupont : "jedupont".

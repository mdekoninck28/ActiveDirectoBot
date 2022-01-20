##########################
#### Modules externes ####
##########################

#Module Active Directory
Import-Module ActiveDirectory

############################
#### FONCTIONS DIVERSES ####
############################

#Supprimer les accents et les espaces
Function Remove-StringSpecialCharacters
{
   Param([string]$String)
   $String -replace 'é', 'e' `
           -replace 'è', 'e' `
           -replace 'ç', 'c' `
           -replace 'ë', 'e' `
           -replace 'à', 'a' `
           -replace 'ö', 'o' `
           -replace 'ô', 'o' `
           -replace 'ü', 'u' `
           -replace 'ï', 'i' `
           -replace 'î', 'i' `
           -replace 'â', 'a' `
           -replace 'ê', 'e' `
           -replace 'û', 'u' `
           -replace ' ', '' `
}

#########################
#### Début du script ####
#########################

Write-host -ForegroundColor Cyan "##############################"
Write-host -ForegroundColor Cyan "###### ActiveDirectoBot ######"
Write-host -ForegroundColor Cyan "#### by Maxence DE KONINCK ###"
Write-host -ForegroundColor Cyan "##############################"

#Passer la console en mode UTF-8
chcp 65001 | Out-Null

#Saisie du nom de domaine par l'utilisateur
Write-Host -ForegroundColor Yellow -NoNewline "Nom du domaine Active Directory (avec le prefixe) : "
$domaine = Read-Host

#On vérifie que la machine fasse partie du domaine
If ($domaine -eq $(Get-WMIObject Win32_ComputerSystem| Select-Object -ExpandProperty Domain)) {
    
    #Scission du domaine et de son suffixe sous forme de variables séparées
    $domaine = $domaine.split(".")
    $nomdomaine = $domaine[0]
    $prefixe = $domaine[1]
}

#Sinon on s'arrête
Else {
    Write-Host -ForegroundColor Red "ERREUR : Nom de domaine invalide"
    PAUSE
    Exit
}

#Saisie de l'UO racine des utilisateurs
Write-Host -ForegroundColor Yellow -NoNewline "Unité d'organisation racine des utilisateurs : "
$uoracine = Read-Host

#Demander si l'utilisateur doit changer de mot de passe à la première connexion
Write-Host -ForegroundColor Yellow -NoNewline "Les utilisateurs doivent-ils changer de mot de passe à la prochaine connexion ? (O/N)"
$chgmtmdp = Read-Host

#Vérifier que la valeur de $chgmtmdp soit O ou N sinon erreur
if ( ($chgmtmdp -ne "O") -and ($chgmtmdp -ne "N") ) {
    Write-Host -ForegroundColor Red "ERREUR : Vous n'avez pas répondu par O ou N (Oui ou Non)."
    PAUSE
    Exit
}

#Définir la variable $chgmtmdp en fonction de la répose fournie
if ($chgmtmdp -eq "O") {
    $chgmtmdp = $true
}
Else {
    $chgmtmdp = $false
}

#Saisie de l'emplacement du fichier CSV
Write-Host -ForegroundColor Yellow -NoNewline "Emplacement local de la liste d'utilisateurs (Fichier CSV UTF-8 à point-virgules) : "
$csv = Read-Host

#Suppression des guillemets du chemin s'il y en a
If ($csv -match '"') {
        $csv = $csv.Substring(1,$csv.Length-2)
}

#Résumé des informations saisies
Write-Host "Conteneur LDAP racine des utilisateurs : OU=$uoracine,DC=$nomdomaine,DC=$prefixe"
Write-Host "Liste d'utilisateurs à importer :" $csv

#Import des données de la liste
$liste = Import-CSV -Path $csv -Delimiter ";" -Encoding "UTF8"

#Pour chaque utilisateur...
Foreach ($user in $liste) {
    
    #Récupération de ses attributs dans la liste
    $nom = $($user.nom).ToUpper() #Nom de famille
    $prenom = $user.prenom #Prénom
    $email = $user.mail #Adresse mail
    $tel = $user.telephone #Téléphone
    $fonction = $user.fonction #Fonction
    $desc = $user.description #Description
    $login = Remove-StringSpecialCharacters -String "$($($prenom.substring(0,2)+$nom).toLower())" #Identifiant de connexion
    $mdp = $user.mdp #Mot de passe
    $upn = Remove-StringSpecialCharacters -String "$login@$nomdomaine.$prefixe" #UPN
    $uo = $user.uo #Unité d'organisation
    $societe = $user.societe #Société
    
    #Si l'utilisateur existe déja dans l'annuaire alors on le crée pas
    if (Get-ADUser -Filter {SamAccountName -eq $login}) {
        Write-Host "L'utilisateur $login existe déjà dans l'annuaire"
    }

    #Sinon
    else {
        #On vérifie si l'UO existe dans l'annuaire
        if (Get-ADOrganizationalUnit -Filter {ou -eq $uo}) {
            Write-Host "L'UO $uo existe déja dans l'annuaire" #annonce UO existante
        }

        #Sinon on la crée
        else {
            New-ADOrganizationalUnit -Name $uo -Path "OU=$uoracine,DC=$nomdomaine,DC=$prefixe" #création de l'UO
            Write-Host "Création de l'UO $uo" #annonce création de l'UO
        }

        #Et on crée l'utilisateur dans l'annuaire
        New-ADUser -Name "$prenom $nom" `
                    -DisplayName "$prenom $nom" `
                    -GivenName $prenom `
                    -Surname $nom `
                    -SamAccountName $login `
                    -UserPrincipalName $upn `
                    -EmailAddress $email `
                    -OfficePhone $tel `
                    -Title $fonction `
                    -Description $desc `
                    -Company $societe `
                    -Path "OU=$uo,OU=$uoracine,DC=$nomdomaine,DC=$prefixe" `
                    -AccountPassword (ConvertTo-SecureString -AsPlainText $mdp.Trim("") -Force) `
                    -ChangePasswordAtLogon $chgmtmdp `
                    -Enabled $true
        Write-Host "Création de l'utilisateur : $login ($prenom $nom)" #annonce création utilisateur
    }
}

#Message de fin d'opération et arrêt
Write-Host -Foregroundcolor DarkGreen "Opération terminée"
Read-Host -Prompt "Appuyer sur ENTREE pour terminer"
cd $PSScriptRoot
$ProgressPreference = "SilentlyContinue"
$CurrentDate = Get-Date -Format "dd MMMM yyyy HH-mm-ss"
$IISLogFile = "C:\Temp\DeployIISsitesLog "+$CurrentDate+".txt"
$ServicesLogFile = "C:\Temp\DeployServicesLog "+$CurrentDate+".txt"
$ConsolsLogFile = "C:\Temp\DeployConsolsLog "+$CurrentDate+".txt"


#Unpack IIS Sites Artifacts
if (Test-Path -Path "..\artifacts\IISsites\"){
    try{
        $IISartifacts = Get-ChildItem -Path "..\artifacts\IISsites\" -Recurse

        if (Test-Path -Path "C:\temp\Sites"){
            "TMP Artifact IIS sites folder (C:\temp\Sites) exist"+" - "+(Get-Date) | Out-File $IISLogFile -Append
            Remove-Item C:\temp\Sites\* -Recurse -Force
            "Clear TMP Artifact IIS sites folder (C:\temp\Sites) done"+" - "+(Get-Date)  | Out-File $IISLogFile -Append
        }
        else{                
            New-Item -ItemType Directory -Path C:\Temp\Sites
            "TMP Artifact IIS sites folder (C:\temp\Sites) not exist, create done"+" - "+(Get-Date) | Out-File $IISLogFile -Append
        }

        foreach($IISartifact in $IISartifacts){
            Expand-Archive $IISartifact.PSPath -DestinationPath C:\temp\Sites\
            "Expand "+$IISartifact.Name+" done, destinationPath C:\temp\Sites\"+($IISartifact.Name-replace ".zip", "")+" - "+(Get-Date) | Out-File $IISLogFile -Append
        }
    }
    catch{
        $err = $_.Exception
        $err.Message+" Error on unpack "+$IISartifact.PSPath+" - "+(Get-Date) | Out-File $IISLogFile -Append
        while($err.InnerException){
            $err = $err.InnerException
            $err.Message+" Error on unpack "+$IISartifact.PSPath+" - "+(Get-Date) | Out-File $IISLogFile -Append    
        }
        exit 1
    }
}

#Unpack services artifacts  
if (Test-Path -Path "..\artifacts\services\"){
    try{
        $ServiceArtifacts = Get-ChildItem -Path "..\artifacts\services\" -Recurse

        if (Test-Path -Path "C:\temp\Services"){
            "TMP Artifact services folder (C:\temp\Services) exist"+" - "+(Get-Date) | Out-File $ServicesLogFile -Append
            Remove-Item C:\temp\Services\* -Recurse -Force
            "Clear TMP Artifact services folder (C:\temp\Services) done"+" - "+(Get-Date)  | Out-File $ServicesLogFile -Append
            }
            else{
            New-Item -ItemType Directory -Path C:\Temp\Services
            "TMP Artifact services folder (C:\temp\Services) not exist, create done"+" - "+(Get-Date) | Out-File $ServicesLogFile -Append                 
            }

        foreach($ServiceArtifact in $ServiceArtifacts){
            Expand-Archive $ServiceArtifact.PSPath -DestinationPath C:\temp\Services\
            "Expand "+$ServiceArtifact.Name+" done, destinationPath C:\temp\Services\"+($ServiceArtifact.Name-replace ".zip", "")+" - "+(Get-Date) | Out-File $ServicesLogFile -Append
        }
    }
    catch{
        $err = $_.Exception
        $err.Message+" Error on unpack "+$ServiceArtifact.PSPath+" - "+(Get-Date) | Out-File $ServicesLogFile -Append
        while( $err.InnerException){
            $err = $err.InnerException
            $err.Message+" Error on unpack "+$ServiceArtifact.PSPath+" - "+(Get-Date)  | Out-File $ServicesLogFile -Append
        }
        exit 1
    }
}

#Unpack consols artifacts
if (Test-Path -Path "..\artifacts\consols\"){  
    try{
        $ConsolsArtifacts = Get-ChildItem -Path "..\artifacts\consols\" -Recurse

        if (Test-Path -Path "C:\temp\Consols"){
            "TMP Artifact consols folder (C:\temp\Consols) exist"+" - "+(Get-Date) | Out-File $ConsolsLogFile -Append
            Remove-Item C:\temp\Consols\* -Recurse -Force
            "Clear TMP Artifact services folder (C:\temp\Consols) done"+" - "+(Get-Date)  | Out-File $ConsolsLogFile -Append
            }
            else{
            New-Item -ItemType Directory -Path C:\Temp\Consols
            "TMP Artifact Consols folder (C:\temp\Consols) not exist, create done"+" - "+(Get-Date) | Out-File $ConsolsLogFile -Append                 
            }

        foreach($ConsoleArtifact in $ConsolsArtifacts){
            Expand-Archive $ConsoleArtifact.PSPath -DestinationPath C:\temp\Consols\
            "Expand "+$ConsoleArtifact.Name+" done, destinationPath C:\temp\Consols\"+($ConsoleArtifact.Name-replace ".zip", "")+" - "+(Get-Date) | Out-File $ConsolsLogFile -Append
        }
    }
    catch{
        $err = $_.Exception
        $err.Message+" Error on unpack "+$ConsoleArtifact.PSPath+" - "+(Get-Date) | Out-File $ConsolsLogFile -Append
        while( $err.InnerException){
            $err = $err.InnerException
            $err.Message+" Error on unpack "+$ConsoleArtifact.PSPath+" - "+(Get-Date)  | Out-File $ConsolsLogFile -Append
        }
        exit 1
    }
}

#Deploy services
if (Test-Path -Path "C:\Temp\Services\"){
    try{
    $NewServisesFolders = Get-ChildItem -Path "C:\Temp\Services\"
    $AllCurrentServises = Get-Service
    $CurrentDate = Get-Date -Format "dd MMMM yyyy HH-mm-ss"
    $ServicesLogFile = "C:\Temp\DeployServicesLog "+$CurrentDate+".txt"

    foreach ($CurrentService in $AllCurrentServises){
        foreach ($NewService in $NewServisesFolders){                
            if ($NewService.Name -eq $CurrentService.Name ){
                $CurrentServiceWMI = Get-WmiObject Win32_Service | Where-object {$_.Name -EQ $CurrentService.Name}
                $PathToCurrentServise = $($CurrentServiceWMI.pathname)
                $PathToCurrentDirServise = (Split-Path -Path $PathToCurrentServise)-replace '"', ""
                $ServiseName = $CurrentService.Name 
                    if(!($CurrentService.Status -eq "Stopped")){
                        Stop-Service $CurrentService.Name
                        Start-Sleep -s 5
                    }                    
                "Found service to deploy, "+$CurrentService.Name+", stop service successfully, start backup"+" - "+(Get-Date)  | Out-File $ServicesLogFile -Append
                if (Test-Path -Path "C:\Temp\Backups\Servises"){
                    "Backup services folder (C:\Temp\Backups\Servises) exist, start clear old backups"+" - "+(Get-Date)  | Out-File $ServicesLogFile -Append
                    $BackupServiseFolders = Get-ChildItem "C:\Temp\Backups\Servises"                
                    foreach ($BackupServiseFolder in $BackupServiseFolders){
                        if ($NewService.Name -eq $BackupServiseFolder.Name){                        
                            Remove-Item -Path $BackupServiseFolder.FullName -Recurse    
                        }
                    }
                }
                else{                
                    New-Item -ItemType Directory -Path C:\Temp\Backups\Servises\
                    "Backup services folder (C:\Temp\Backups\Servises) not exist, successfully create"+" - "+(Get-Date)  | Out-File $ServicesLogFile -Append
                    $BackupCurrentServiceFolder = New-Item -ItemType Directory -Path C:\Temp\Backups\Servises\$ServiseName
                    "Backup folder for "+$CurrentService.Name+" successfully create, path "+$BackupCurrentServiceFolder.FullName+" - "+(Get-Date)  | Out-File $ServicesLogFile -Append     
                    Get-ChildItem $PathToCurrentDirServise -Recurse | Copy-Item -Destination $BackupCurrentServiceFolder -Recurse
                    "Backup service "+$CurrentService.Name+ " successfully create, path "+$BackupCurrentServiceFolder.FullName+" - "+(Get-Date)  | Out-File $ServicesLogFile -Append
                }       
            }
        }
    }
    try{
        foreach ($CurrentService in $AllCurrentServises){
            foreach ($NewService in $NewServisesFolders){                
                if ($NewService.Name -eq $CurrentService.Name ){
                    $CurrentServiceWMI = Get-WmiObject Win32_Service | Where-object {$_.Name -EQ $CurrentService.Name}
                    $PathToCurrentServise = $($CurrentServiceWMI.pathname)
                    $PathToCurrentDirServise = (Split-Path -Path $PathToCurrentServise)-replace '"', ""
                   
                    Get-ChildItem $PathToCurrentDirServise | Remove-Item -Recurse
                    "Delete old service for path "+$PathToCurrentDirServise+" done"+" - "+(Get-Date)  | Out-File $ServicesLogFile -Append    
                    Get-ChildItem $NewService.FullName -Recurse | Copy-Item -Destination $PathToCurrentDirServise -Recurse
                    "Copy new service for path "+$PathToCurrentDirServise+" done"+" - "+(Get-Date)  | Out-File $ServicesLogFile -Append
                    Start-Service $CurrentService.Name
                    Start-Sleep -s 5  
                    "Deploy and start service "+$CurrentService.Name+ " done "+" - "+(Get-Date)  | Out-File $ServicesLogFile -Append
                }
            }
        }
    }
    catch{
            $err = $_.Exception
            $err.Message+" Error on deploy service, start rollback "+$CurrentService.Name+" - "+(Get-Date)  | Out-File $ServicesLogFile -Append
            while($err.InnerException){
            $err = $err.InnerException
            $err.Message+" Error on deploy service, start rollback "+$CurrentService.Name+" - "+(Get-Date)  | Out-File $ServicesLogFile -Append
            }
            $BackupFolders = Get-ChildItem -Path C:\Temp\Backups\Servises\
            foreach ($NewService in $NewServisesFolders){
            foreach ($BackupFolder in $BackupFolders){
                if($BackupFolder.Name -eq $NewService.Name){
                    $CurrentService = Get-Service | Where-Object {$_.Name -EQ $NewService.Name}  
                    $CurrentServiceWMI = Get-WmiObject Win32_Service | Where-object {$_.Name -EQ $NewService.Name}    
                    $PathToCurrentServise = $($CurrentServiceWMI.pathname)
                    $PathToCurrentDirServise = (Split-Path -Path $PathToCurrentServise)-replace '"', ""
                    if(!($CurrentService.Status -eq "Stopped")){
                        Stop-Service $CurrentService.Name
                        Start-Sleep -s 5
                    }
                    Get-ChildItem $PathToCurrentDirServise | Remove-Item -Recurse
                    "Delete service for path "+$PathToCurrentDirServise+" done"+" - "+(Get-Date)  | Out-File $ServicesLogFile -Append    
                    Get-ChildItem $BackupFolder.FullName -Recurse | Copy-Item -Destination $PathToCurrentDirServise -Recurse
                    "Rollback service for path "+$PathToCurrentDirServise+" done"+" - "+(Get-Date)  | Out-File $ServicesLogFile -Append
                    Start-Service $CurrentService.Name
                    Start-Sleep -s 5  
                    "Rollback and start service"+$CurrentService.Name+ " done "+" - "+(Get-Date)  | Out-File $ServicesLogFile -Append

                }
            }
        }
    }
}
catch{
    $err = $_.Exception
    $err.Message+" Error on deploy service "+$CurrentService.Name+" - "+(Get-Date)  | Out-File $ConsolsLogFile -Append
    while( $err.InnerException){
        $err = $err.InnerException
        $err.Message+" Error on deploy service "+$CurrentService.Name+" - "+(Get-Date)  | Out-File $ConsolsLogFile -Append
    }       
}
}

#Deploy IIS Sites
if (Test-Path -Path "C:\Temp\Sites\"){
    try{
    Import-Module WebAdministration
    sleep 2
    $AllIisSites = Get-Website | Where-Object -FilterScript {$_.Name -notmatch "Default"}
    $SitesToDeploy = Get-ChildItem -Path "C:\Temp\IISSites"
    $CurrentDate = Get-Date -Format "dd MMMM yyyy HH-mm-ss"
    $IISLogFile = "C:\Temp\DeployIISsitesLog "+$CurrentDate+".txt"

    foreach ($IisSite in $AllIisSites){
        foreach ($SiteToDeploy in $SitesToDeploy){
        $FilesIIsSite = (Get-ChildItem $IisSite.physicalPath | Where-Object -FilterScript {$_.Name -match ".txt"}) -replace ".txt", ""
        $IISSiteName = $SiteToDeploy.Name
            foreach ($FileIISSite in $FilesIIsSite){                   
                if($FileIISSite -eq $SiteToDeploy){
                    if(!($IisSite.Status -eq "Stopped")){
                        Stop-Website -Name $IisSite.Name 
                        Start-Sleep -s 3                                  
                    }                   
                "Found site to deploy, "+$IisSite.Name+", stop site successfully, start backup"+" - "+(Get-Date)  | Out-File $IISLogFile -Append
                if (Test-Path -Path "C:\Temp\Backups\IISSites"){
                    "Backup sites folder (C:\Temp\Backups\IISSites) exist, start clear old backups"+" - "+(Get-Date)  | Out-File $IISLogFile -Append
                    $BackupIISFolders = Get-ChildItem "C:\Temp\Backups\IISSites\"                
                    foreach ($BackupIISFolder in $BackupIISFolders){
                        if ($SiteToDeploy.Name -eq $BackupIISFolder.Name){                        
                            Remove-Item -Path $BackupIISFolder.FullName -Recurse    
                        }
                    }
                }
                else{                
                    New-Item -ItemType Directory -Path C:\Temp\Backups\IISSites\
                    "Backup services folder (C:\Temp\Backups\IISSites) not exist, successfully create"+" - "+(Get-Date)  | Out-File $IISLogFile -Append
                    }       
                
                $BackupCurrentIIsFolder = New-Item -ItemType Directory -Path C:\Temp\Backups\IISSites\$IISSiteName
                "Backup folder for IIS site "+$IISSiteName+" successfully create, path "+$BackupCurrentIIsFolder.FullName+" - "+(Get-Date)  | Out-File $IISLogFile -Append     
                Get-ChildItem $IisSite.physicalPath -Recurse | Copy-Item -Destination $BackupCurrentIIsFolder -Recurse
                "Backup IIS site "+$IISSiteName+ " successfully create, path "+$BackupCurrentIIsFolder.FullName+" - "+(Get-Date)  | Out-File $IISLogFile -Append
                }
            }
        }
    }
    try{
        foreach ($IisSite in $AllIisSites){
            foreach ($SiteToDeploy in $SitesToDeploy){
                $FilesIIsSite = (Get-ChildItem $IisSite.physicalPath | Where-Object -FilterScript {$_.Name -match ".txt"}) -replace ".txt", ""
                $IISSiteName = $SiteToDeploy.Name
                foreach ($FileIISSite in $FilesIIsSite){                   
                    if($FileIISSite -eq $SiteToDeploy){
                        if(!($IisSite.Status -eq "Stopped")){
                            Stop-Website -Name $IisSite.Name 
                            Start-Sleep -s 3                                  
                        } 
                    Get-ChildItem $IisSite.physicalPath | Remove-Item -Recurse
                    "Delete old site for path "+$IisSite.physicalPath+" done"+" - "+(Get-Date)  | Out-File $IISLogFile -Append    
                    Get-ChildItem $SiteToDeploy.FullName -Recurse | Copy-Item -Destination $IisSite.physicalPath -Recurse
                    "Copy new site for path "+$IisSite.physicalPath+" done"+" - "+(Get-Date)  | Out-File $IISLogFile -Append
                    Start-Website $IisSite.Name
                    Start-Sleep -s 5  
                    "Deploy and start site "+$IisSite.Name+ " done "+" - "+(Get-Date)  | Out-File $IISLogFile -Append
                    }
                }
            }
        }
    }
    catch{
        $err = $_.Exception
        $err.Message+" Error on deploy site " +$IisSite.Name+ ", start rollback all new sites - "+(Get-Date)  | Out-File $IISLogFile -Append
        while($err.InnerException){
            $err = $err.InnerException
            $err.Message+" Error on deploy site " +$IisSite.Name+ ", start rollback all new sites - "+(Get-Date)  | Out-File $IISLogFile -Append
        }
        $BackupFolders = Get-ChildItem -Path C:\Temp\Backups\IISSites\
        foreach ($SiteToDeploy in $SitesToDeploy){
            foreach ($BackupFolder in $BackupFolders){
                if($BackupFolder.Name -eq $SiteToDeploy.Name){
                    foreach ($IisSite in $AllIisSites){ 
                        $FilesIIsSite = (Get-ChildItem $IisSite.physicalPath | Where-Object -FilterScript {$_.Name -match ".txt"}) -replace ".txt", ""
                        foreach ($FileIISSite in $FilesIIsSite){                   
                            if($FileIISSite -eq $SiteToDeploy){
                                if(!($IisSite.Status -eq "Stopped")){
                                    Stop-Website -Name $IisSite.Name 
                                    Start-Sleep -s 3                                  
                                }
                            Get-ChildItem $IisSite.physicalPath | Remove-Item -Recurse
                            "Delete IIS site for path "+$IisSite.physicalPath+" done"+" - "+(Get-Date)  | Out-File $IISLogFile -Append    
                            Get-ChildItem $BackupFolder.FullName -Recurse | Copy-Item -Destination $IisSite.physicalPath -Recurse
                            "Rollback IIS site for path "+$IisSite.physicalPath+" done"+" - "+(Get-Date)  | Out-File $IISLogFile -Append
                            Start-Website $IisSite.Name
                            Start-Sleep -s 3  
                            "Rollback and start IIS site "+$IisSite.Name+ " done "+" - "+(Get-Date)  | Out-File $IISLogFile -Append
                            }
                        }
                    }
                }
            }
        }
    }
}
catch{
    $err = $_.Exception
    $err.Message+" Error on deploy service "+$CurrentService.Name+" - "+(Get-Date)  | Out-File $ConsolsLogFile -Append
    while( $err.InnerException){
        $err = $err.InnerException
        $err.Message+" Error on deploy service "+$CurrentService.Name+" - "+(Get-Date)  | Out-File $ConsolsLogFile -Append
    }       
}

}

#Deploy Consols
if (Test-Path -Path "C:\Temp\Consols\"){
    try{
    $ConsolsToDeploy = Get-ChildItem C:\Temp\Console
    $CurrentDate = Get-Date -Format "dd MMMM yyyy HH-mm-ss"
    $ConsolsLogFile = "C:\Temp\DeployConsolsLog "+$CurrentDate+".txt"
    $AllTasks = Get-ScheduledTask | Where-Object -FilterScript {$_.TaskPath -notmatch "microsoft" -and $_.TaskName -notmatch "Google"}
    $Actions=$AllTasks.Actions.Execute
    foreach($Action in $Actions) {
            $ConsoleName = (Split-Path $Action -leaf) -replace ".exe", ""
            if($ConsoleName -like '*"*'){
                $ConsoleName = $ConsoleName -replace '"'
            }
            foreach ($ConsoleToDeploy in $ConsolsToDeploy){
                if ($ConsoleToDeploy.Name -eq $ConsoleName){
                    Wait-Process -Name $ConsoleName -ErrorAction SilentlyContinue                 
                    "Found console to deploy, "+$ConsoleName+", stop console successfully, start backup"+" - "+(Get-Date)  | Out-File $ConsolsLogFile -Append
                    if (Test-Path -Path "C:\Temp\Backups\Consols"){
                        "Backup services folder (C:\Temp\Backups\Consols) exist, start clear old backup"+" - "+(Get-Date)  | Out-File $ConsolsLogFile -Append
                        $BackupConsolsFolders = Get-ChildItem "C:\Temp\Backups\Consols"
                            foreach ($BackupConsoleFolder in $BackupConsolsFolders){
                                if ($BackupConsoleFolder.Name -eq $ConsoleName){
                                Remove-Item $BackupConsoleFolder.FullName -Recurse
                                "Remove old backup"+$BackupConsoleFolder.FullName+"done"+" - "+(Get-Date)  | Out-File $ConsolsLogFile -Append
                                }            
                            }
                    }
                    else{                
                        New-Item -ItemType Directory -Path C:\Temp\Backups\Consols\
                        "Backup consols folder (C:\Temp\Backups\Consols) not exist, successfully create"+" - "+(Get-Date)  | Out-File $ConsolsLogFile -Append            
                    }       
                    $CurrentBackupConsoleFolder = New-Item -ItemType Directory -Path C:\Temp\Backups\Consols\$ConsoleName
                    "Backup folder for "+$ConsoleName+" successfully create, path "+$CurrentBackupConsoleFolder.FullName+" - "+(Get-Date)  | Out-File $ConsolsLogFile -Append
                    if ($Action -like '*"*'){
                        $Action = $Action -replace '"'
                    }
                    Get-ChildItem (Split-Path $Action) -Recurse | Copy-Item -Destination $CurrentBackupConsoleFolder -Recurse  
                    "Backup console "+$ConsoleName+ " successfully create, path "+$CurrentBackupConsoleFolder.FullName+" - "+(Get-Date)  | Out-File $ConsolsLogFile -Append                   
                }
           }
     }
     try{
        foreach($Action in $Actions) {
            $ConsoleName = (Split-Path $Action -leaf) -replace ".exe", ""
            if ($Action -like '*"*'){
                $Action = $Action -replace '"'
            }
            if($ConsoleName -like '*"*'){
                $ConsoleName = $ConsoleName -replace '"'
            }
            foreach ($ConsoleToDeploy in $ConsolsToDeploy){
                if ($ConsoleToDeploy.Name -eq $ConsoleName){
                    Wait-Process -Name $ConsoleName -ErrorAction SilentlyContinue                 
                    "Found console to deploy, "+$ConsoleName+", stop console successfully, start deploy"+" - "+(Get-Date)  | Out-File $ConsolsLogFile -Append
                    Get-ChildItem -Path (Split-Path $Action) | Remove-Item -Recurse
                    "Delete old console for path "+(Split-Path $Action)+" done"+" - "+(Get-Date)  | Out-File $ConsolsLogFile -Append
                    Get-ChildItem $ConsoleToDeploy.FullName -Recurse| Copy-Item -Destination (Split-Path $Action)
                    "Copy new console for path "+(Split-Path $Action)+" done"+" - "+(Get-Date)  | Out-File $ConsolsLogFile -Append
                    }
                }
            }
        }
    catch{
        $err = $_.Exception
        $err.Message+" Error on deploy console " +$ConsoleName+ ", start rollback all new consols - "+(Get-Date)  | Out-File $ConsolsLogFile -Append
        while($err.InnerException){
            $err = $err.InnerException
            $err.Message+" Error on deploy console " +$ConsoleName+ ", start rollback all new consols - "+(Get-Date)  | Out-File $ConsolsLogFile -Append
        }
        $BackupFolders = Get-ChildItem -Path C:\Temp\Backups\Consols\
        foreach ($BackupFolder in $BackupFolders){
            foreach ($ConsoleToDeploy in $ConsolsToDeploy){
                if ($BackupFolder.Name -eq $ConsoleToDeploy.Name){
                    foreach($Action in $Actions) {
                        if ($Action -like '*"*'){
                            $Action = $Action -replace '"'
                        }
                        $ConsoleName = (Split-Path $Action -leaf) -replace ".exe", ""
                        if($ConsoleName -like '*"*'){
                        $ConsoleName = $ConsoleName -replace '"'
                        }
                        if ($ConsoleName -eq $BackupFolder.Name){
                        Wait-Process -Name $ConsoleName -ErrorAction SilentlyContinue
                        "Found console to rollback, "+$ConsoleName+", stop console successfully, start rollback"+" - "+(Get-Date)  | Out-File $ConsolsLogFile -Append    
                        Get-ChildItem -Path (Split-Path $Action) | Remove-Item -Recurse
                        Get-ChildItem $BackupFolder.FullName -Recurse| Copy-Item -Destination (Split-Path $Action)
                        "Rollback new console for path "+(Split-Path $Action)+" done"+" - "+(Get-Date)  | Out-File $ConsolsLogFile -Append    
                        }
                    }    
                }
            }
        }
    } 
}       
catch{
 $err = $_.Exception
    $err.Message+" Error on deploy "+$ConsoleName+" - "+(Get-Date)  | Out-File $ConsolsLogFile -Append
    while( $err.InnerException){
        $err = $err.InnerException
       $err.Message+" Error on deploy "+$ConsoleName+" - "+(Get-Date)  | Out-File $ConsolsLogFile -Append
    } 

}
}

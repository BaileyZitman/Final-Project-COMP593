if (Get-InstalledModule -Name "PSSQLite"){ #installs the reqiured module if not already installed.
    Import-Module PSSQLite
} else {
    Install-Module -Name PSSQLite -Force -Scope CurrentUser 
    Write-Output "The modile PSSQLite is required to run this script and has been downloaded automatically" 
}
Function Connection_and_query{
    #the next few lines connects to the database and makes a query for TODAYS hash value. 
    $date = Get-Date -Format "yyyy/MM/dd"
    #$date = $date.Replace("/", "-") #originally needed to replace for formatting but not neccessary. just in case left in
    $data_base = New-SQLiteConnection -Datasource "PBMZ-db-FP.sqlite"
    #$date = "2021-04-15" #used to test other dates than current one
    $query = 'SELECT "SHA-256 Hash" FROM "Astronomy Image of The Day" WHERE "Date Image was Obtained" = "' + $date + '"'
    $connection_results = Invoke-SqliteQuery -SQLiteConnection $data_base -Query $query #makes query to database
    return $connection_results."SHA-256 Hash"
}

Function Change_background ([string]$image){
    remove-itemproperty -path "HKCU:Control Panel\Desktop" -name Wallpaper
    set-itemproperty -path "HKCU:Control Panel\Desktop" -name Wallpaper -value $image
    for ($i = 0 ; $i -le 20; $i++ ){
        RUNDLL32.EXE USER32.DLL,UpdatePerUserSystemParameters 1, True
    }
    $return_statement = "The background image of the computer was changed to: $image" 
    return $return_statement
}

Function FilePath_to_Background ([string]$State, [string]$OutputStatement){
    $statements = ("No file matching the hash was found. Will start the FinalProject.py Script to obtain the image because it has not already been downloaded.", "No entry for this day can be found in the database. Will commence obtaining the image and create a new entry", "The directory './PBMZ-db-FP.sqlite' does not exist yet so will commense creation now and obtain the image of the day.")
    Write-Host $statements[$OutputStatement]
    $Path = $(python .\FinalProject.py $State)
    $File_location = Get-ItemProperty FullName -Path $Path
    Write-Host The File $File_location.FullName "was retrieved from the python script and will be used to change the background image"
    $change_background = Change_background -image $File_location.FullName
    return $change_background
}

$directory_to_search = $Args[0]

if (-Not (Test-Path -Path "./Saved Images")){ #checks to see if ./Saved Images exists if not create
    $create_directory = New-Item -Path "./" -Name "Saved Images" -ItemType "directory" #assigned to variable so output is not produced.
} 

if ($directory_to_search -eq "default"){ #if user doesnt wanna speficify second directory scan the defailt one twice but omit output because they will be same
    $directory_to_search = ".\Saved Images"
}

if (Test-Path -Path "./PBMZ-db-FP.sqlite"){ #test to make sure database exists
    $connection_results = Connection_and_query
    if ($connection_results){ #if connection returns a hash continue else no database/entry for current date
        $find_hash = Get-ChildItem ".\Saved Images" -Recurse | Get-FileHash | Where-object -Property Hash -e -Value $connection_results #search the ./Saved Images directory for a file with the same has a returned
        $find_hash_second_directory = Get-ChildItem $directory_to_search -Recurse | Get-FileHash | Where-object -Property Hash -e -Value $connection_results #same as above but on user defined directory. if default was provided then on ./Saved Images
        if (($find_hash) -or ($find_hash_second_directory)){ #if a file was found in either directory with same hash use that file
            if ($find_hash.Path -eq $find_hash_second_directory.Path){ #if the paths are the same only output one
                Write-Host "The file(s):" $find_hash.Path were located that contain the same hash as the current image of the day and will use one of the files instead #write-host doesnt add a \n automatically when not using quotes
            } else {
                Write-Host "The file(s):" $find_hash.Path $find_hash_second_directory.Path were located that contain the same hash as the current image of the day and will use one of the files instead #write-host doesnt add a \n automatically when not using quotes
            }
            if ($find_hash){
                $change_background = Change_background -image $find_hash.Path
            } else {
                $change_background = Change_background -image $find_hash_second_directory.Path
            }
            Write-Output $change_background
        } else { #if the directory exists, there is an entry for todays day, but the image has not be found, run python script to get the image but not append a new entry          
            Write-Output (FilePath_to_Background -state "2" -OutputStatement 0)
        }
    } else { #if the directory exists but no entry for the current day run python script to get todays image
        Write-Output (FilePath_to_Background -state "1" -OutputStatement 1)
    }
} else { #if database doesnt exists run python script to retrieve todays image and download the image
    Write-Output (FilePath_to_Background -state "1" -OutputStatement 2)
} 
#*-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-*#*-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-*#*-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-*
# Description:
#  This script will allow the user to change the background image of the computer to Nasa's Astronomy Image of the Day. This script works in conjuction with the script
#  "FinalProject.py" to complete the objective. This script will automatically start the python script if the image available for today is already downloaded. Note: 
#  the images for THIS script must be located in the directory called ".\Saved Images" to work properly. This script will create the directory and search that directory
#  for the images that are already downloaded. If the image is not found containing the hash in question the python script will activate and obtain the image. The Image
#  data will be saved to a database called "PBMZ-db_FP.db" which will also be created in the CWD when the python script is FIRST run. On subsequent runs, the data will be
#  appended to database instead.
#
# Usage
#  . .\FinalProject.ps1 
#
#  For a detailed summary on functionality and usability please visit the "README.md" file in the main Github repository
#
# History
#  For a detailed history summary vist the file "History.md" in the main Github repository 
#
#*-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-*#*-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-*#*-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-*
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
    #$date = "2020-04-13" #used to test other dates than current one
    $query = 'SELECT "SHA-256 Hash" FROM "Astronomy Image of The Day" WHERE "Date Image was Obtained" = "' + $date + '"'
    $connection_results = Invoke-SqliteQuery -SQLiteConnection $data_base -Query $query #makes query to database
    return $connection_results."SHA-256 Hash"
}

Function Change_background ([string]$image){
    set-itemproperty -path "HKCU:Control Panel\Desktop" -name Wallpaper -value $image
    RUNDLL32.EXE USER32.DLL,UpdatePerUserSystemParameters, 1, True
    $return_statement = "The background image of the computer was changed to: $image" 
    return $return_statement
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
    if ($connection_results){ #if connection returns a hash continue else no directory/entry for current date
        $find_hash = Get-ChildItem ".\Saved Images" -Recurse | Get-FileHash | Where-object -Property Hash -e -Value $connection_results #search the ./Saved Images directory for a file with the same has a returned
        $find_hash_second_directory = Get-ChildItem $directory_to_search -Recurse | Get-FileHash | Where-object -Property Hash -e -Value $connection_results #same as above but on user defined directory. if default was provided then on ./Saved Images
        if (($find_hash) -or ($find_hash_second_directory)){ #if a file was found in either directory with same hash use that file
            #Write-Output $connection_results
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
            Write-Output "No file matching the hash was found. Will start the FinalProject.py Script to obtain the image because it has not already been downloaded."
            $File_Path = $(python .\FinalProject.py "2")
            $File_location = Get-ItemProperty FullName -Path $File_Path 
            Write-Host The File $File_location.FullName "was retrieved from the python script and will be used to change the background image"
            $change_background = Change_background -image $File_location.FullName
            Write-Output $change_background
        }
    } else { #if the directory exists but no entry for the current day run python script to get todays image
        Write-Output "No directory entry for this day. Will obtain the image and create a new entry"
        $File_Path = $(python .\FinalProject.py "1")
        $File_location = Get-ItemProperty FullName -Path $File_Path 
        Write-Host The File $File_location.FullName "was retrieved from the python script and will be used to change the background image"
        $change_background = Change_background -image $File_location.FullName
        Write-Output $change_background
    }
} else { #if database doesnt exists run python script to retrieve todays image and download the image
    Write-Output "The directory './PBMZ-db-FP.sqlite' does not exist yet so will commense creation now and obtain the image of the day."
    $File_Path = $(python .\FinalProject.py "1")
    $File_location = Get-ItemProperty FullName -Path $File_Path 
    Write-Host The File $File_location.FullName "was retrieved from the python script and will be used to change the background image"
    $change_background = Change_background -image $File_location.FullName
    Write-Output $change_background
} 

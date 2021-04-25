#*-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-*#*-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-*#*-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-*
# Description:
#  This script will allow the user to change the background image of the computer to Nasa's Astronomy Image of the Day. This script works in conjuction with the script
#  "FinalProject.py" to complete the objective and is called by the RunAPODPBMZ.ps1 script. This script will automatically start the python script if the image available
#  for today is not already downloaded. Note: the images for THIS script must be located in the directory called ".\Saved Images" to work properly.
#  This script will search that directory plus anothor if selected for the images that are already downloaded. If the image is not found containing the hash in 
#  question the python script will activate and obtain the image. The Image data will be saved to a database called "PBMZ-db_FP.db" which will also be created in the CWD
#  when the python script is FIRST run and it didn't return a video. On subsequent runs, the data will be appended to database instead. 
#  Note: This script uses command line parameters because it has the ability to create a new entry or just use a previous entry to redownload an image. This is provided
#  via the command line parameters and considered a "controlling" feature. If called by instelf, ensure either a 1 or 2 is specified based on the function you wish to 
#  complete. 
#
# Usage
#  . .\FinalProject.ps1 directorytosearch
#
# Parameters
#  directorytosearch = This is the parameter to specify which additional directory to search (max 1). Enter the full path of the directory to search recursilvly, 
#                      or enter "default" to search ./Saved Images twice (only outputs the path once though so not duplicating output)
#
#  For a detailed summary on functionality and usability please visit the "README.md" file
#
# History
#  For a detailed history summary visit the file "History.md"
#
#*-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-*#*-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-*#*-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-*
if (Get-InstalledModule -Name "PSSQLite"){ #installs the reqiured module if not already installed.
    Import-Module PSSQLite -Force
    Write-Host "Imported the module: " -ForegroundColor "Red" -NoNewline ; Write-Host "PSSQLite" -ForegroundColor "Yellow"
} else {
    Install-Module -Name PSSQLite -Force -Scope CurrentUser #used to query the database from powershell, also do queries in python but if dont need to run python script
    Import-Module PSSQLite
    Write-Host "The modile PSSQLite is required to run this script and has been downloaded and imported automatically" -ForegroundColor "Red"
}
Function Connection_and_query{
    #the next few lines connects to the database and makes a query for TODAYS hash value. 
    $date = Get-Date -Format "yyyy/MM/dd" #gets current date
    $data_base = New-SQLiteConnection -Datasource "PBMZ-db-FP.sqlite" #states the location of connection-not connection itself
    $query = 'SELECT "SHA-256 Hash" FROM "Astronomy Image of The Day" WHERE "Date Image was Obtained" = "' + $date + '"' #query for connection, getting todays hash if available
    $connection_results = Invoke-SqliteQuery -SQLiteConnection $data_base -Query $query #makes query to database and the actual connection and response
    return $connection_results."SHA-256 Hash" #output only the hash, none of the nonsense
}

Function Change_background ([string]$image){ #changes background of host computer to that of returned path
    $num_monitors = (Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorBasicDisplayParams | Where-Object {$_.Active -like "True"}).Active.Count #gets the number of monitors
    if (-not($num_monitors -eq "1")){ #if more than 1 monitor prompt the user with warning/confirmation
        Write-Host "The script has detected a multiple monitor setup. Please ensure that all monitors contain images that are indentical before continuing. Otherwise only one monitor will be changed" -ForegroundColor "Red"
        $acceptance = Read-Host "Press anything to continue" 
    }
    remove-itemproperty -path "HKCU:Control Panel\Desktop" -name Wallpaper #removes the old wallpaper first
    set-itemproperty -path "HKCU:Control Panel\Desktop" -name Wallpaper -value $image #set the new value in the registry to the path of the $image
    for ($i = 0 ; $i -le 35; $i++ ){ #sets a loop to ensure the background is chnages without reboot, doesnt work everytime so put in a loop of 35 times to ensure it changes
        RUNDLL32.EXE USER32.DLL,UpdatePerUserSystemParameters 1, True # used to set the variable to true
    }
    $return_statement = "The background image of the computer was changed to: $image" 
    return $return_statement
}

Function FilePath_to_Background ([string]$State, [string]$OutputStatement){ #used to take the filepath and call the python script and then use that output to call the call the change background function about and chnage the background
    #Below assigns the statements to an array for easy access base on when this function is called will output something different
    $statements = ("No file matching the hash value returned for the current date was found. Will start the FinalProject.py Script to obtain the image because it has not already been downloaded.", "No entry for this day can be found in the database. Will commence obtaining the image and create a new entry", "The directory './PBMZ-db-FP.sqlite' does not exist yet so will commense creation now and obtain the image of the day.")
    Write-Host $statements[$OutputStatement] -ForegroundColor "Green"
    $Path = $(python .\FinalProject.py $State) #call the python script
    if (Test-Path "./temp.txt"){ #if the file exists read content, output it and then delete it. 
        $python_output = Get-Content -Path "./temp.txt" #read contents
        $python_out1 = $python_output -replace "'\]", "" #the next four lines reformat the txt the nice output, need new variables bc.....powershell is weird?!?!
        $python_out2 = $python_out1 -replace "\['", ""
        $python_out3 = $python_out2 -replace "', '", " "
        Write-Host $python_out3 -ForegroundColor "Green" #write the outout of the python script to the screen 
        Remove-Item -Path "./temp.txt" #delete the file that contained the temp above info
    }

    $File_location = Get-ItemProperty FullName -Path $Path #take the half-@$$ string "./Saved Images/oshdbc...blah" to the full string for the background changer
    Write-Host The File $File_location.FullName "was retrieved from the python script and will be used to change the background image" -ForegroundColor "Green" #write the returned path as if python did all the work
    $change_background = Change_background -image $File_location.FullName #call function to change background to path returned
    return $change_background #return the output of the background changer
}

$directory_to_search = $Args[0] #directory to search

if ($directory_to_search -eq "default"){ #if user doesnt wanna speficify second directory scan the default one twice but omit output because they will be same
    $directory_to_search = ".\Saved Images"
}

if (Test-Path -Path "./PBMZ-db-FP.sqlite"){ #test to make sure database exists, if it does continue
    $connection_results = Connection_and_query #get the hash of the current day
    if ($connection_results){ #if connection returns a hash continue else no database/entry for current date
        $find_hash = Get-ChildItem ".\Saved Images" -Recurse | Get-FileHash | Where-object -Property Hash -e -Value $connection_results #search the ./Saved Images directory for a file with the same has a returned
        $find_hash_second_directory = Get-ChildItem $directory_to_search -Recurse | Get-FileHash | Where-object -Property Hash -e -Value $connection_results #same as above but on user defined directory. if default was provided then on ./Saved Images
        if (($find_hash) -or ($find_hash_second_directory)){ #if a file was found in either directory with same hash use that file
            if ($find_hash.Path -eq $find_hash_second_directory.Path){ #if the paths are the same only output one
                Write-Host "The file:" $find_hash.Path was located that contains the same hash value as the current image of the day and will be used to change the background of the computer -ForegroundColor 'Green' #write-host doesnt add a \n automatically when not using quotes
            } else {
                Write-Host "The file:" $find_hash.Path $find_hash_second_directory.Path was located that contains the same hash value as the current image of the day and will be used to change the background of the computer -ForegroundColor 'Green' #write-host doesnt add a \n automatically when not using quotes
            }
            if ($find_hash){ #if file that was found is in the default folder use that first, because mine script rules....jk...but it does
                $change_background = Change_background -image $find_hash.Path #change background base on image found in todays directory instead of calling the python script becasue it is already downlaoded
            } else {
                $change_background = Change_background -image $find_hash_second_directory.Path
            }
            Write-Host $change_background -ForegroundColor "Green"
        } else { #if the directory exists, there is an entry for todays day, but the image has not be found, run python script to get the image but not append a new entry          
            Write-Host (FilePath_to_Background -state "2" -OutputStatement 0) -ForegroundColor "Green"
        }
    } else { #if the directory exists but no entry for the current day run python script to get todays image
        Write-Host (FilePath_to_Background -state "1" -OutputStatement 1) -ForegroundColor "Green"
    }
} else { #if database doesnt exists run python script to retrieve todays image and download the image
    Write-Host (FilePath_to_Background -state "1" -OutputStatement 2) -ForegroundColor "Green"
}
Read-Host -Prompt "Enter Any Key to Exit" 
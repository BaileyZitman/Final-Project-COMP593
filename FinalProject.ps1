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

Function locate_file_w_hash{ #used to compare the hash values of the images in the directory ./Saved Images/ to the hash value of the latest image. 
    Get-ChildItem ".\Saved Images\" |
    #get the hash value for each file in the directory .\Saved Images
     ForEach-Object { 
         $hash = Get-FileHash ".\Saved Images\$_" | Format-List -Property Hash | Out-String
         $hash_converted = $hash -Replace " Hash : ", "" #ensures same format as other hash to compare properly
         $hash_final = $hash_converted | ConvertFrom-String
         $status = "!="
         while ($status = "!="){
           $status = compare_hashes -Database_hash $connection_results -File_hash $hash.p4   
         }  
     }
     return $status
}

Function Connection_and_query{
    #the next few lines connects to the database and makes a query for TODAYS hash value. 
    $date = Get-Date -Format "yyyy/MM/dd" | Out-String
    $date = $date.Replace("/", "-") #gets the date of the current date for the query
    $data_base = New-SQLiteConnection -Datasource "PBMZ-db-FP.sqlite"
    $date = "2021-04-11"
    $query = 'SELECT "SHA-256 Hash" FROM "Astronomy Image of The Day" WHERE "Date Image was Obtained" = "' + $date + '"'
    $connection_results = Invoke-SqliteQuery -SQLiteConnection $data_base -Query $query
    return $connection_results."SHA-256 Hash"
}

Function compare_hashes {
    Param (
        [Object] $Database_hash,
        [Object] $File_hash
    )

    if ($Database_hash -Match "[/d/w]"){
    Write-Output $Database_hash
    Write-Output $File_hash

        if ($File_hash-eq $Database_hash){
            Write-Output "The Image is already located in the Directory ./Saved Images and that file will be used instead of obtaining a new image and information"
            return "="
        } else {
            Write-Output "The Astronomy Image of the Day is not located in ./Saved Images already and as a result the script will commense fetching procedure"
            return "!="   
        }

    } else {
        Write-Output "There is no entry in the database for the current day and therefore the image could not possibly be downloaded by this script already."
}

}

$connection_results = Connection_and_query 
$status = locate_file_w_hash
Write-Output $status


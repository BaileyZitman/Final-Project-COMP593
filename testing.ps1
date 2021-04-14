if (Get-InstalledModule -Name "PSSQLite"){ #installs the reqiured module if not already installed.
    Import-Module PSSQLite
} else {
    Install-Module -Name PSSQLite -Force -Scope CurrentUser 
    Write-Output "The modile PSSQLite is required to run this script and has been downloaded automatically" 
}
Function Connection_and_query{
    #the next few lines connects to the database and makes a query for TODAYS hash value. 
    $date = Get-Date -Format "yyyy/MM/dd"
    #$date = $date.Replace("/", "-") #gets the date of the current date for the query
    $data_base = New-SQLiteConnection -Datasource "PBMZ-db-FP.sqlite"
    #$date = "2021-04-13"
    $query = 'SELECT "SHA-256 Hash" FROM "Astronomy Image of The Day" WHERE "Date Image was Obtained" = "' + $date + '"'
    $connection_results = Invoke-SqliteQuery -SQLiteConnection $data_base -Query $query
    return $connection_results."SHA-256 Hash"
}

Function locate_file_w_hash{ #used to compare the hash values of the images in the directory ./Saved Images/ to the hash value of the latest image. 
    #get the hash value for each file in the directory .\Saved Images
    $images = Get-ChildItem ".\Saved Images\*"
    $status = @{dummy = "!"}
    foreach ($file in $images){ 
        $hash = Get-FileHash $file | Format-List -Property Hash | Out-String
        $hash_converted = $hash -Replace " Hash : ", "" #ensures same format as other hash to compare properly
        $hash_final = $hash_converted | ConvertFrom-String
        $status[$file]= compare_hashes -Database_hash $connection_results -File_hash $hash_final.p4
    }
    $status.Remove("dummy")
    return $status
}

Function compare_hashes {
    Param (
        [Object] $Database_hash,
        [Object] $File_hash
    )

    if ($Database_hash -Match "[/d/w]"){
        #Write-Output $Database_hash
        #Write-Output $File_hash
        if ($File_hash-eq $Database_hash){
            return "="
        } else {
            return "!"   
        }
    } else {
        return "!!!"
    }

}

$connection_results = Connection_and_query 
Write-Output $connection_results
$hash = locate_file_w_hash
Write-Output $hash
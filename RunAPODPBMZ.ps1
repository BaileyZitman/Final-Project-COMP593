#*-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-*#*-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-*#*-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-*
# Description:
#  This script will be the main script that runs and will be used to configure the FinalProject.ps1 script. This script allows you to specify how you would like the
#  FinalProject.ps1 and subsequently the FinalProject.py script to run. This allows you to set a task to run: once at a specific time and daily at a specific time. 
#  This script will create the task based on the time the user configures to run it. You can also choose now which will not create a task but directly run FinalProject.ps1
#
# Usage
#  . .\RunAPODPBMZ.ps1
#
#  For a detailed summary on functionality and usability please visit the "README.md" file in the main Github repository
#
# History
#  For a detailed history summary vist the file "History.md" in the main Github repository 
#
#*-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-*#*-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-*#*-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-**-*
Write-Host "Welcome To Bailey's APOTD Configuration Script" -ForegroundColor "Red"
Write-Host "This script will be used to determine the configuration settings for the script: " -ForegroundColor "Green" -NoNewline ; Write-Host "./FinalProject.ps1" -ForegroundColor "Yellow"
Write-Host "Additional Directory Configuration:" -ForegroundColor "Cyan"
Write-Host "Enter an additional Directory to search for images in addition to the directory: " -ForegroundColor "Green" -NoNewline ; Write-host "./Saved Images/" -ForegroundColor "Yellow" -NoNewLine
Write-Host ". For example, if the Downloads folder should be searched for images as well as the default directory, enter: " -ForegroundColor "Green" -NoNewline ; Write-Host "C:\Users\baile\Downloads" -ForegroundColor "Yellow" -NoNewline
Write-Host ". Note: If you only want to search the default directory, enter: " -ForegroundColor "Green" -NoNewline; Write-Host "default" -ForegroundColor "Yellow"

Function Create_task ([String]$Occurrence, [String]$Directory, [String]$Time){  #will create the task 
    $current_Directory = Get-Location #gets current directory of this script so we know which directory to start the powershell session in ;)
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument ". .\FinalProject.ps1 $Directory" -WorkingDirectory $current_Directory.Path #this is the actuon that is preformed when the trigger happens.
    if ($Occurrence -eq "Once"){ #because cannot convert string to automation object, need to do this
        $trigger = New-ScheduledTaskTrigger -Once -At $Time #run once, this is the trigger
    } else {
        $trigger = New-ScheduledTaskTrigger -Daily -At $Time #run daily, this is the trigger
    }
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries #applies settings, 
    $register = Register-ScheduledTask -TaskName "PBMZ Background Changer" -Action $action -Trigger $trigger -Settings $settings #create the task with the action, trigger and settings configured. assigned to unused variable to not get output
    return "The Task was created succesfully. 'PBMZ Background Changer' will run $Occurrence at $Time" #output this to the original terminal this was run. 
}

$Setting_configuration_one = "yes"
while ($Setting_configuration_one -eq "yes"){ #ensures a correct entry is entered
    $additional_directory = Read-Host "Enter the additional directory to search"
    if (($additional_directory -match "^default$") -or (Test-Path $additional_directory)){ #if default was entered or a valid directory continue
        $Setting_configuration_one = "no"
    } else { #bad entry, print error and present option again until valid
        Write-Host "Error: The directory entered is not valid, enter the directory again or enter 'default' instead" -ForegroundColor "Red"
    }
}
Write-Host "Occurrence Configuration:" -ForegroundColor "Cyan"
$Timing_Options  = ("Once", "Daily", "Now") #available options 
Write-Host "This configuration setting allows you to select how often the script will run. The options available are: " -ForegroundColor "Green" -NoNewline; Write-Host $Timing_Options -ForegroundColor "Yellow"
$Setting_configuration_two = "yes"
while ($Setting_configuration_two -eq "yes"){ #ensures a correct entry is entered
    $Occurrence = Read-Host "Enter an available option"
    if (-not($Timing_Options.IndexOf($Occurrence) -like "-1")){ #if entered value is available
        $Setting_configuration_two = "no"
    } else {
        Write-Host "Error: The occurence entered is not valid. Please enter an available option." -ForegroundColor "Red"
    }
}
$Setting_configuration_three = "yes"
if (-not($Occurrence -eq "Now")){ #only need to get time if not Now
    Write-Host "Run-Time Configuration:" -ForegroundColor "Cyan"
    Write-Host "This configuration setting allows you to specify which time you wish to set the script to run at. Note: Please enter " -ForegroundColor "Green" -NoNewline; Write-Host "AM" -ForegroundColor "Yellow" -NoNewline
    Write-Host " and " -ForegroundColor "Green" -NoNewline ; Write-Host "PM" -ForegroundColor "Yellow" -NoNewline; Write-Host " exactly as shown." -ForegroundColor "Green" -NoNewline
    Write-Host " Example: To run the script at 6:00 in the morning enter: " -ForegroundColor "Green" -NoNewline ; Write-Host "6:00AM" -ForegroundColor "Yellow" -NoNewline; Write-Host ". Note: The ':' is mandatory" -ForegroundColor "Green"
    while ($Setting_configuration_three -eq "yes"){ #checks to make sure enter value is accepted
        $Run_Time = Read-Host "Enter the time you wish to run the script"
        if ($Run_Time -match "^[1-9][12]?:[0-5][0-9] ?[PA]M$"){ #used to make sure valid entry
            $Setting_configuration_three = "no"
        } else {
            Write-Host "Error: The Time entered is not in the correct format. Please enter a new time." -ForegroundColor "Red" 
        }
    }
}
if ($Occurrence -eq "Now"){ #run the script from here without making a task for it. 
    $current_Directory = Get-Location 
    Start-Process -FilePath "Powershell.exe" -ArgumentList ". .\FinalProject.ps1 $additional_directory"  -WorkingDirectory $current_Directory #starts the process in a new terminal
} else { #else if once or Daily but not now 
    $create_task = Create_task -Time $Run_Time -Occurrence $Occurrence -Directory $additional_directory #schedule the task based on user input
    Write-Host $create_task -ForegroundColor "Green"
}
# Code to ensure SQLPS is loaded
cls
function Import-Module-SQLPS {
    #pushd and popd to avoid import from changing the current directory (ref: http://stackoverflow.com/questions/12915299/sql-server-2012-sqlps-module-changing-current-location-automatically)
    #3>&1 puts warning stream to standard output stream (see https://connect.microsoft.com/PowerShell/feedback/details/297055/capture-warning-verbose-debug-and-host-output-via-alternate-streams)
    #out-null blocks that output, so we don't see the annoying warnings described here: https://www.codykonior.com/2015/05/30/whats-wrong-with-sqlps/
    push-location
    import-module sqlps 3>&1 | out-null
    pop-location
}
 
Import-Module-SQLPS

###########################################################################################################
# SET THESE VARIABLES TO DEFINE THE TARGET DB FOR THE JSON FILE TO BE LOADED TO
###########################################################################################################
$serverName = 'azsdl-vwsqlstg1'
$databaseName = 'Other'
$tableName = 'dbo.JSONFileImport'
# Expected structure of table is as below
#	CREATE TABLE dbo.JSONFileImport (
#		ID BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY   -- Not Required for script
#		,DBInsertDate DATETIME NULL DEFAULT GETDATE()  -- Not Required for script
#		,Name nvarchar(255) NULL
#		,Date DATETIME NULL
#		,Size FLOAT NULL
#		,Contents NVARCHAR(MAX) NULL
#	)
$jsonFiles = "$PSScriptRoot\"
$fileExtension = "*.json"
###########################################################################################################

# Loop through specified directory looking for files with the specified file type
Get-ChildItem -Path $jsonFiles -Recurse -Filter $fileExtension -File | sort CreationTime |
ForEach-Object {
    # insert file metadata and contents into the specified table
    $fileName = $_.Name
    $fileDate = $_.CreationTime
    $fileSize = $_.Length
    $fileContent = Get-Content $_.FullName -Raw
    $sqlQuery = "INSERT INTO $tableName ( Name, Date, Size, Contents ) VALUES ( '$fileName', '$fileDate', $fileSize, '$fileContent' )"
    Invoke-Sqlcmd -Query $sqlQuery -ServerInstance $serverName -Database $databaseName

    # Delete file after upload
    $_.Delete()
}
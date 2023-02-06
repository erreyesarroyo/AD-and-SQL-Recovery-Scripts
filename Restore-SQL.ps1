
#Begin with try statement for error catching
try
{
   #Import right Module
   if (Get-Module -Name sqlps) { Remove-Module sqlps }
   Import-Module -Name SqlServer

   #Set variable for name of SQL instance
   $sqlServerInstanceName = "SRV19-PRIMARY\SQLEXPRESS"

   #Set variable for name of database
   $databaseName = 'ClientDB'
   
   #Check for database existance in (IF 19-21) will create it and (ELSE 24 to 32) will deleted if it already exists and created it.
   $QueryDB = Get-SqlDatabase -ServerInstance $sqlServerInstanceName -name $databaseName

   if ($QueryDB -eq $null) 
   {
       Write-host -Foregroundcolor Magenta "$databasename does not exist and will be created."
   }
   else
   {
       Write-Host -Foregroundcolor Magenta $databaseName already exists and will be deleted.
             
       Invoke-Sqlcmd -ServerInstance $SQLServerInstanceName -Query "ALTER DATABASE $databaseName SET SINGLE_USER WITH ROLLBACK IMMEDIATE; `
DROP DATABASE $databaseName;"
   }
   #Create SQL Server reference
   $sqlServerObject = New-Object -TypeName microsoft.sqlserver.management.smo.server -ArgumentList $sqlServerInstanceName

   #Create database object reference
   $databaseObject = New-Object -TypeName microsoft.sqlserver.management.smo.database -ArgumentList $sqlServerObject, $databaseName

   #Call the create method on the database object to create the database
   $databaseObject.Create()

   Write-Host -Foregroundcolor Cyan "Database $databaseName created."
   # create Table
   Invoke-Sqlcmd -ServerInstance $sqlServerInstanceName -Database $databaseName -InputFile $PSScriptRoot\Client_A_Contacts.sql

   $tablename = 'Client_A_Contacts'

   Write-Host -Foregroundcolor Magenta "Table $tablename created."

   # Create insert into variable
   $Insert = "INSERT INTO [$($tablename)] (first_name, last_name, city, county, zip, officephone, mobilePhone)"

   #Import CSV with data for table
   $NewClientData = Import-Csv $PSScriptRoot\NewClientData.csv

   #Foreach loop to format the values
   foreach($NewClient in $NewClientData)
   {
   $values = "VALUES (`
                       '$($NewClient.first_name)',`
                       '$($NewClient.last_name)',`
                       '$($NewClient.city)',`
                       '$($NewClient.county)',`
                       '$($NewClient.zip)',`
                       '$($NewClient.officePhone)',`
                       '$($NewClient.mobilePhone)')"
                       
                 
   $query = $Insert + $values
   Invoke-sqlCmd -Database $databaseName -ServerInstance $sqlServerInstanceName -Query $query
   }

   Write-Host -Foregroundcolor Magenta "CSV imported."
   # create .txt output as required
   Invoke-sqlCmd -Database $databaseName -ServerInstance $sqlServerInstanceName -Query 'SELECT * from dbo.Client_A_Contacts' > .\SqlResults.txt

   Write-Host -Foregroundcolor cyan "SqlResults.txt created."
   }
   #End with catch statement for error handling if needed.
   catch {
   
   }

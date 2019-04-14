Import-Module (Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) "Microsoft.PowerApps.Administration.PowerShell.psm1") -Force

# file paths
$AppFilePath = ".\Apps.csv"
$AppRoleAssignmentsFilePath = ".\AppPermissions.csv"
$FlowFilePath = ".\Flows.csv"
$FlowRoleAssignmentsFilePath = ".\FlowPermissions.csv"

# Add the header to the app csv file
$appFileHeaders = "EnvironmentName," `
        + "AppName," `
        + "CreatedTime," `
        + "LastModifiedTime," `
        + "AppDisplayName," `
        + "AppOwnerObjectId," `
        + "AppOwnerDisplayName," `
        + "AppOwnerDisplayEmail," `
        + "AppOwnerUserPrincipalName," `
        + "AppConnections";
Add-Content -Path $AppFilePath -Value $appFileHeaders

# Add the header to the app roles csv file
$appRoleAssignmentsHeaders = "EnvironmentName," `
        + "AppName," `
        + "CreatedTime," `
        + "LastModifiedTime," `
        + "AppDisplayName," `
        + "AppOwnerObjectId," `
        + "AppOwnerDisplayName," `
        + "AppOwnerDisplayEmail," `
        + "AppOwnerUserPrincipalName," `
        + "AppConnections," `
        + "RoleType," `
        + "RolePrincipalType," `
        + "RolePrincipalObjectId," `
        + "RolePrincipalDisplayName," `
        + "RolePrincipalEmail," `
        + "RoleUserPrincipalName,";
Add-Content -Path $AppRoleAssignmentsFilePath -Value $appRoleAssignmentsHeaders

# Add the header to the flow  csv file
$flowFileHeaders = "EnvironmentName," `
        + "FlowName," `
        + "CreatedTime," `
        + "LastModifiedTime," `
        + "FlowDisplayName," `
        + "FlowOwnerObjectId," `
        + "FlowOwnerDisplayName," `
        + "FlowOwnerDisplayEmail," `
        + "FlowOwnerUserPrincipalName," `
        + "FlowConnections";
Add-Content -Path $FlowFilePath -Value $flowFileHeaders

# Add the header to the app roles csv file
$flowRoleAssignmentsHeaders = "EnvironmentName," `
        + "FlowName," `
        + "CreatedTime," `
        + "LastModifiedTime," `
        + "FlowDisplayName," `
        + "FlowOwnerObjectId," `
        + "FlowOwnerDisplayName," `
        + "FlowOwnerDisplayEmail," `
        + "FlowOwnerUserPrincipalName," `
        + "FlowConnections," `
        + "RoleType," `
        + "RolePrincipalType," `
        + "RolePrincipalObjectId," `
        + "RolePrincipalDisplayName," `
        + "RolePrincipalEmail," `
        + "RoleUserPrincipalName,";
Add-Content -Path $FlowRoleAssignmentsFilePath -Value $flowRoleAssignmentsHeaders


Add-PowerAppsAccount

#populate the app files
$apps = Get-AdminApp

foreach($app in $apps)
{
    #Get the details around who created the app
    $AppEnvironmentName = $app.EnvironmentName
    $Name = $app.AppName
    $DisplayName = $app.displayName -replace '[,]'
    $OwnerObjectId = $app.owner.id
    $OwnerDisplayName = $app.owner.displayName -replace '[,]'
    $OwnerDisplayEmail = $app.owner.email
    $CreatedTime = $app.CreatedTime
    $LastModifiedTime = $app.LastModifiedTime

    $userOrGroupObject = Get-UsersOrGroupsFromGraph -ObjectId $OwnerObjectId
    $OwnerUserPrincipalName = $userOrGroupObject.UserPrincipalName

    #Get the list of connections for the app
    $connectionList = ""
    foreach($conRef in $app.Internal.properties.connectionReferences)
    {
        foreach($connection in $conRef)
        {
            foreach ($connId in ($connection | Get-Member -MemberType NoteProperty).Name) 
            {
                $connDetails = $($connection.$connId)

                $connDisplayName = $connDetails.displayName -replace '[,]'
                $connIconUri = $connDetails.iconUri
                $isOnPremiseConnection = $connDetails.isOnPremiseConnection
                $connId = $connDetails.id


                $connectionList += $connDisplayName + "; "
            }
        }        
    }

    # First write the app record along with who created it and the connections of the app
    $row = $AppEnvironmentName + "," `
        + $Name + "," `
        + $CreatedTime + "," `
        + $LastModifiedTime + "," `
        + $DisplayName + "," `
        + $OwnerObjectId + "," `
        + $OwnerDisplayName + "," `
        + $OwnerDisplayEmail + "," `
        + $OwnerUserPrincipalName + "," `
        + $connectionList;
    Add-Content -Path $AppFilePath -Value $row 

    #Get all of the details for each user the app is shared with
    $principalList = ""
    foreach($appRole in ($app | Get-AdminAppRoleAssignment))
    {
        $RoleEnvironmentName = $appRole.EnvironmentName
        $RoleType = $appRole.RoleType
        $RolePrincipalType = $appRole.PrincipalType
        $RolePrincipalObjectId = $appRole.PrincipalObjectId
        $RolePrincipalDisplayName = $appRole.PrincipalDisplayName -replace '[,]'
        $RolePrincipalEmail = $appRole.PrincipalEmail
        $CreatedTime = $app.CreatedTime
        $LastModifiedTime = $app.LastModifiedTime

        If($appRole.PrincipalType -eq "Tenant")
        {
            $RolePrincipalDisplayName = "Tenant"
            $RoleUserPrincipalName = ""
        }
        If($appRole.PrincipalType -eq "User")
        {
            $userOrGroupObject = Get-UsersOrGroupsFromGraph -ObjectId $appRole.PrincipalObjectId 
            $RoleUserPrincipalName = $userOrGroupObject.UserPrincipalName  
            
        }

        # Write this permission record 
        $row = $AppEnvironmentName + "," `
                + $Name + "," `
                + $CreatedTime + "," `
                + $LastModifiedTime + "," `
                + $DisplayName + "," `
                + $OwnerObjectId + "," `
                + $OwnerDisplayName + "," `
                + $OwnerDisplayEmail + "," `
                + $OwnerUserPrincipalName + "," `
                + $connectionList + "," `
                + $RoleType + "," `
                + $RolePrincipalType + "," `
                + $RolePrincipalObjectId + "," `
                + $RolePrincipalDisplayName + "," `
                + $RolePrincipalEmail + "," `
                + $RoleUserPrincipalName;
        Add-Content -Path $AppRoleAssignmentsFilePath -Value $row 
    }
}
        

#populate the flow files
$flows = Get-AdminFlow

foreach($flow in $flows)
{
    #Get the details around who created the flow
    $FlowEnvironmentName = $flow.EnvironmentName
    $Name = $flow.FlowName
    $DisplayName = $flow.displayName -replace '[,]'
    $OwnerObjectId = $flow.createdBy.objectid
    $OwnerDisplayName = $flow.createdBy.displayName -replace '[,]'
    $OwnerDisplayEmail = $flow.createdBy.email
    $CreatedTime = $flow.CreatedTime
    $LastModifiedTime = $flow.LastModifiedTime

    $userOrGroupObject = Get-UsersOrGroupsFromGraph -ObjectId $OwnerObjectId
    $OwnerUserPrincipalName = $userOrGroupObject.UserPrincipalName

    $flowDetails = $flow | Get-AdminFlow

    $connectionList = ""
    foreach($conRef in $flowDetails.Internal.properties.connectionReferences)
    {
        foreach($connection in $conRef)
        {
            foreach ($connId in ($connection | Get-Member -MemberType NoteProperty).Name) 
            {
                $connDetails = $($connection.$connId)

                $connDisplayName = $connDetails.displayName -replace '[,]'
                $connIconUri = $connDetails.iconUri
                $isOnPremiseConnection = $connDetails.isOnPremiseConnection
                $connId = $connDetails.id

                $connectionList += $connDisplayName + "; "
            }
        }        
    }
    
    # First write the flow record along with who created it and the connections of the flow
    $row = $FlowEnvironmentName + "," `
        + $Name + "," `
        + $CreatedTime + "," `
        + $LastModifiedTime + "," `
        + $DisplayName + "," `
        + $OwnerObjectId + "," `
        + $OwnerDisplayName + "," `
        + $OwnerDisplayEmail + "," `
        + $OwnerUserPrincipalName + "," `
        + $connectionList;
    Add-Content -Path $FlowFilePath -Value $row 


    $principalList = ""
    foreach($flowRole in ($flow | Get-AdminFlowOwnerRole))
    {        
        $RoleEnvironmentName = $flowRole.EnvironmentName
        $RoleType = $flowRole.RoleType
        $RolePrincipalType = $flowRole.PrincipalType
        $RolePrincipalObjectId = $flowRole.PrincipalObjectId
        $RolePrincipalDisplayName = $flowRole.PrincipalDisplayName -replace '[,]'
        $RolePrincipalEmail = $flowRole.PrincipalEmail

        If($flowRole.PrincipalType -eq "Tenant")
        {
            $RolePrincipalDisplayName = "Tenant"
            $RoleUserPrincipalName = ""
        }
        If($flowRole.PrincipalType -eq "User")
        {
            $userOrGroupObject = Get-UsersOrGroupsFromGraph -ObjectId $flowRole.PrincipalObjectId 
            $RoleUserPrincipalName = $userOrGroupObject.UserPrincipalName  
            
        }

        # Write this permission record 
        $row = $RoleEnvironmentName + "," `
            + $Name + "," `
            + $CreatedTime + "," `
            + $LastModifiedTime + "," `
            + $DisplayName + "," `
            + $OwnerObjectId + "," `
            + $OwnerDisplayName + "," `
            + $OwnerDisplayEmail + "," `
            + $OwnerUserPrincipalName + "," `
            + $connectionList + "," `
            + $RoleType + "," `
            + $RolePrincipalType + "," `
            + $RolePrincipalObjectId + "," `
            + $RolePrincipalDisplayName + "," `
            + $RolePrincipalEmail + "," `
            + $RoleUserPrincipalName;
        Add-Content -Path $FlowRoleAssignmentsFilePath -Value $row 
    }
}
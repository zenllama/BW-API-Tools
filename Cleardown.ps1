function GenerateHeaders( $auth ) {
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Content-Type", "application/json")
    $headers.Add("Accept","application/json;odata=fullmetadata")    
    $headers.Add("Authorization", "Basic $($auth)")

    return $headers
}

function GenerateHeaders( $auth, $continueFlag ) {
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("x-amz-meta-continuationtoken", $continueFlag)
    $headers.Add("Content-Type", "application/json")
    $headers.Add("Accept","application/json;odata=fullmetadata")    
    $headers.Add("Authorization", "Basic $($auth)")

    return $headers
}

function BWDeleteAllRequest( $server, $auth, $endpoint) {

    $body = @{lastUpdated="0001-01-01";}
 
    $headers = GenerateHeaders $auth

    $url = "https://$($server)/v1/$($endpoint)"

    $response = Invoke-RestMethod $url -Method 'DELETE' -Headers $headers -Body ($body|ConvertTo-Json)

    return $response
}

function BWDeleteAllListRequest( $server, $auth, $list) {

    $body = @{lastUpdated="0001-01-01";}
 
    $headers = GenerateHeaders $auth

    $url = "https://$($server)/v1/lists/$($list)"

    $response = Invoke-RestMethod $url -Method 'DELETE' -Headers $headers -Body ($body|ConvertTo-Json)   

    return $response
}

function Get-Request( $server, $auth, $url) {    
    $headers = GenerateHeaders $auth
   
    $response = Invoke-RestMethod $url -Method 'GET' -Headers $headers    

    return $response
}

function Get-BasicAuth($username, $password) {
    $Text = "$($username):$($password)"
    $Bytes = [System.Text.Encoding]::ASCII.GetBytes($Text)
    $result =[Convert]::ToBase64String($Bytes)
    return $result
}

function ClearDown($server, $auth, $Lists, $APIS) {   

    $responseList = @()

    Write-Host "Deleting Endpoint Data:"

    foreach( $api in $APIS ) {
        Write-Host "`t $($api)"
        $res = BWDeleteAllRequest $server $auth $api
        $responseList += @(@{name=$api; link=$res.statusApiLink})        
    }

    Write-Host "Deleting List Data:"
    foreach( $list in $Lists ) {
        Write-Host "`t $($list)"

        $res = BWDeleteAllListRequest $server $auth $list
       
        $responseList += @{name=$list; link=$res.statusApiLink; staus=$res.taskStatus;} 

        # Sleep added as if you call a delete again too quickly the API will complain about a delete already in progress
        Start-Sleep -Seconds 5      
    }

    Write-Host "Waiting 20 seconds"
    Start-Sleep -Seconds 20
    
    Write-Host "Deleted Data now checking on Responses:"

    foreach( $r in $responseList ) {
        
        if ($r.link.Length -gt 0) {

            $resx = Get-Request $server $auth $r.link
            Write-Host ("Delete for '$($r.name)'; `t status: $($resx.taskStatus); `t Record Count: $($resx.recordCount); `t Link: $($r.link)")
        } else {
            Write-Host "Delete for '$($r.name)';`t status: $($r.status);"
        }

    }
}

function ConfirmGo() {
    $title    = 'Basware API Cleardown'
    $question = "Are you sure you want to proceed? `nThis will delete ALL data"
    $choices  = '&Yes', '&No'

    $decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
    if ($decision -eq 0) {
        Cleardown
    } else {
        Write-Host 'Cancelled'
    }
}

function Cleardown(){

    # All list that you wanted cleared from the API database
    $Lists = @("INV_LIST_20","ACC_LIST_31","ACC_LIST_3","ACC_LIST_4","ACC_LIST_5","ACC_LIST_6","ACC_LIST_7","ACC_LIST_8")

    # All endpoints you want to clear
    $APIS = @("exchangeRates", "paymentTerms", "taxCodes", "costCenters", "matchingOrderLines", "matchingOrders", "vendors")

    # Generate BASIC Auth string
    $auth = GGet-BasicAuth "<Client>-openapi-consultant@basware.com" "<password>"
    
    # US TEST Server
    $server = "test-api.basware.com"

    # EU Test Server
    #$server = "test-api.us.basware.com"

    ClearDown $server $auth $Lists $APIS
}

# Execution starts here
ConfirmGo
   
   


$link = ".p2p.basware.com/ap/invoice/details?docId="
$tenant = "" #put your tenant name here

[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') 
$docid = [Microsoft.VisualBasic.Interaction]::InputBox('Enter the Invoice ID', 'Basware Invoice Lookup') 

Start-Process "https://$tenant.p2p.basware.com/ap/invoice/details?docId=$docid"
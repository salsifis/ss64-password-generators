#powershell PasswdGen

function SS64pwgen_SetClipboard {
    ## From Windows PowerShell Cookbook (O'Reilly)
    ## by Lee Holmes (http://www.leeholmes.com/guide)

    param(
        [Parameter(ValueFromPipeline = $true)]
        [object[]] $InputObject
    )
    begin
    {
        Set-StrictMode -Version Latest
        $objectsToProcess = @()
    }
    process
    {
        ## Collect everything sent to the script either through
        ## pipeline input, or direct input.
        $objectsToProcess += $inputObject
    }
    end
    {
        ## Launch a new instance of PowerShell in STA mode.
        ## This lets us interact with the Windows clipboard.
        $objectsToProcess | PowerShell -NoProfile -STA -Command {
            Add-Type -Assembly PresentationCore
            ## Convert the input objects to a string representation
            $clipText = ($input | Out-String -Stream) -join "`r`n"
            ## And finally set the clipboard text
            [Windows.Clipboard]::SetText($clipText)
        }
    }
}

function SS64pwgen_ToHash {
    <#

    .SYNOPSIS

    Computes a checksum from a given input string, using a given algorithm
    The result is a byte array.

    .EXAMPLE

    SS64pwgen_ToHash -InputString "abc" -Algorithm SHA1
    SS64pwgen_ToHash SHA1 'abc'

    .EXAMPLE

    Dir | SS64pwgen_ToHash SHA256

    #>
    param(
          [Parameter(ValueFromPipeline = $false)] [string] $Algorithm = 'SHA1' , ## algorithm to use
          [Parameter(ValueFromPipeline = $true)] [string] $InputString           ## String from which to compute hash
         )

    $utf8_encoder = [System.Text.Encoding]::UTF8
    $input_as_byte_array = $utf8_encoder.GetBytes($InputString)
    $hash_obj = [System.Security.Cryptography.HashAlgorithm]::Create($Algorithm)
    $hash_obj.ComputeHash($input_as_byte_array)
}


function SS64pwgen_ToBase64 {
    <#

    .SYNOPSIS

    Computes the base64 encoded value from a given byte array.
    The result is a string.

    .EXAMPLE

    SS64pwgen_ToBase64 (25, 25)

    .EXAMPLE

    SS64pwgen_ToSha256 "abc" | SS64pwgen_ToBase64

    #>
    param(
          [Parameter(ValueFromPipeline = $true)] [byte[]] $ByteArray ## byte array from which to compute base64
         )

    return [System.Convert]::ToBase64String($ByteArray)
}

function Get-StrongPw {
    <#

    .SYNOPSIS

    Computes a secure password for one or more specific site(s), given a
    user-provided key.
    There is a user prompt for the key.

    .EXAMPLE

    Get-StrongPw paypal

    .EXAMPLE

    Get-StrongPw paypal facebook

    #>
    if($args.length -eq 0) { return }

    $key = Read-Host -Prompt "Encryption key" -AsSecureString
    $strkey = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($key))

    foreach ($i in $args)
    {
        $site = $i
        $pw = [string](SS64pwgen_ToBase64 -ByteArray (SS64pwgen_ToHash -Algorithm SHA256 -InputString "${strkey}:${site}")).Replace("+","E").Replace("/","a").Substring(0,20)
        if ($args.length -eq 1)
        {
            SS64pwgen_SetClipboard $pw
            Write-Host "Password for ${site}: (in clipboard)"
        } else
        {
            Write-Host "Password for ${site}: ${pw}"
        }
    }

    $pw = [string](SS64pwgen_ToBase64 -ByteArray (SS64pwgen_ToHash -Algorithm SHA256 -InputString ":${strkey}:")).Replace("+","E").Replace("/","a").Substring(0,20)
    Write-Host "Verification code: ${pw}"
}

function Get-StdPw {
    <#

    .SYNOPSIS

    Computes a secure password for one or more specific site(s), given a
    user-provided key.
    There is a user prompt for the key.

    .EXAMPLE

    Get-StdPw paypal

    .EXAMPLE

    Get-StdPw paypal facebook

    #>
    if($args.length -eq 0) { return }

    $key = Read-Host -Prompt "Encryption key" -AsSecureString
    $strkey = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($key))

    foreach ($i in $args)
    {
        $site = $i
        $pw = [string](SS64pwgen_ToBase64 -ByteArray (SS64pwgen_ToHash -Algorithm SHA1 -InputString "${strkey}:${site}")).Substring(0,8) + "1a"
        if ($args.length -eq 1)
        {
            SS64pwgen_SetClipboard $pw
            Write-Host "Password for ${site}: (in clipboard)"
        } else
        {
            Write-Host "Password for ${site}: ${pw}"
        }
    }

    $pw = [string](SS64pwgen_ToBase64 -ByteArray (SS64pwgen_ToHash -Algorithm SHA256 -InputString ":${strkey}:")).Replace("+","E").Replace("/","a").Substring(0,20)
    Write-Host "Verification code: ${pw}"
}

Export-ModuleMember Get-StrongPw
Export-ModuleMember Get-StdPw

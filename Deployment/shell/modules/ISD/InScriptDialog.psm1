# This script is named InScriptDialog.psm1

function Write-BoxBorder {
<#    .SYNOPSIS    Workout width of text from pipeline and box it.
    .DESCRIPTION
        Workout width of text from pipeline and box it, passing the object on.    Optionally add a title.    .EXAMPLE    "hello" | Write-BoxBorder | Write-Host    .-------.    | hello |    '-------'    .EXAMPLE    "hello world" | Write-BoxBorder -Title "Greeting" | Write-Host    .- Greeting --.    | hello world |    '-------------'#>
    Param(        [parameter(ValueFromPipeline)]        $line,
        [parameter(Mandatory=$false)]        [String] $Title
    )

    Begin {
        $maxLen = 0
        $rows = @()
        
    }

    Process {
        $lineLen = ($line).length
        if ($lineLen -gt $maxLen) {
            $maxLen = $lineLen
        }

        $rows += $line
    }

    End {
        $horzLn = '-' * $maxLen
        if ($Title) {
            $horzLnTitle = '-' * ($maxLen - ($Title).length - 2)
            ".- $Title $horzLnTitle-." 
        } else {
            ".-$horzLn-."
        }
       
        foreach ($r in $rows) {
            "| {0,-$maxLen} |" -f $r
        }

        "'-$horzLn-'"
    }

}

function Write-ObjectProperties {<#    .SYNOPSIS    From pipeline Write object property name/value strings to output
    .DESCRIPTION
        Using .NET composite formatting, present object properties    neatly in a grid if mutiple objects in pipeline.    Optionally add a title, and override lengths for name/value fields#>

    Param(
        [parameter(ValueFromPipeline)]        $m,
        [parameter(Mandatory=$false)]        [int] $lenName = 12,
        [parameter(Mandatory=$false)]        [int] $lenValue = 17,
        [parameter(Mandatory=$false)]        [String] $Title
    )
  
    Begin {
        $lines = @() # array stores output lines
        $col = 0
        $row = 0
        $lineOffset = 0
    }

    Process {
        # output object contents
        $i = $lineOffset # line array offset
        foreach ($prop in $m.psobject.properties) {
            $cont = "{0,$lenName}: {1,-$lenValue}" -f $prop.name, $prop.value

            # append/create array content
            if ($col -gt 0) {
                $lines[$i] = $lines[$i] + $cont
            } else {
                $lines += $cont
            }
            $i++
        }
        
        # next column
        $col++

        # until ...
        if ($col -gt 2) {
            # then, add a separator line
            $lines += ''
            $lineOffset = $i + 1
            # start from left again / next row
            $col = 0
            $row++
        }    
    }

    End {
        $lines | Write-BoxBorder -Title $Title
    }
    
       
}


# Export-ModuleMember -Function Write-BoxBorder, Write-ObjectProperties
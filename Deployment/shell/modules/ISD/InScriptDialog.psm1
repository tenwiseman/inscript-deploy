﻿# This script is named InScriptDialog.psm1

function Write-BoxBorder {
<#
    .DESCRIPTION
    
    Param(
        [parameter(Mandatory=$false)]
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

function Write-ObjectProperties {
    .DESCRIPTION
    

    Param(
        [parameter(ValueFromPipeline)]
        [parameter(Mandatory=$false)]
        [parameter(Mandatory=$false)]
        [parameter(Mandatory=$false)]
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
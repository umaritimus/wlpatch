# @summary Apply Weblogic patches
#
# Apply Weblogic Patches
#
# @example
#   include wlpatch
class wlpatch  (
  Optional[Hash[Integer,String]] $weblogic_patches = lookup('weblogic_patches',undef,undef,undef)
){
  if ($facts['operatingsystem'] == 'windows') {
    if (!empty($weblogic_patches)) {
      debug ("Running on Windows OS with the following weblogic_patches set: ${weblogic_patches}")
      $weblogic_patches.each | Integer $patch_index, String $patch_path | {
        if (!empty($patch_path)) {
          $weblogic_path = regsubst("${lookup('weblogic_location')}", '(/|\\\\)', '\\', 'G')
          $pkgtemp = regsubst("${weblogic_path}-${patch_index}", '(/|\\\\)', '\\', 'G')
          $jar_path = regsubst("${lookup('jdk_location')}/bin/jar.exe", '(/|\\\\)', '\\', 'G')

          exec { "Check ${patch_path}" :
            command   => Sensitive(@("EOT")),
                Test-Path -Path ${regsubst("\'${patch_path}\'", '(/|\\\\)', '\\', 'G')} -ErrorAction Stop
              |-EOT
            provider  => powershell,
            logoutput => true,
          }

          exec { "Check ${jar_path}" :
            command   => Sensitive(@("EOT")),
                Test-Path -Path ${regsubst("\'${jar_path}\'", '(/|\\\\)', '\\', 'G')} -ErrorAction Stop
              |-EOT
            provider  => powershell,
            logoutput => true,
          }

          exec { "Expand ${patch_path} to ${pkgtemp}" :
            command   => Sensitive(@("EOT")),
                Try {
                  New-Item -Path "${pkgtemp}" -Type Directory -Force | Out-Null
                  Set-Location -Path "${pkgtemp}"
                  Copy-Item -Path ${regsubst("\'${patch_path}\'", '(/|\\\\)', '\\', 'G')} -Destination "./"
                  Start-Process `
                    -FilePath ${regsubst("\'${lookup('jdk_location')}/bin/jar.exe\'", '(/|\\\\)', '\\', 'G')} `
                    -ArgumentList @( `
                          "-xf", `
                          "$(Resolve-Path -Path 'p*_Generic.zip')" `
                    ) `
                    -Wait `
                    -ErrorAction Stop `
                    -NoNewWindow | Out-Null
                } Catch {
                  Exit 1
                }
              |-EOT
            provider  => powershell,
            logoutput => true,
            timeout   => 600,
            require   => [ Exec["Check ${patch_path}","Check ${jar_path}"] ],
          }

          exec { "Deploy ${pkgtemp}" :
            command   => Sensitive(@("EOT")),
                Try {
                  Set-Location -Path $(Resolve-Path -Path "${pkgtemp}/WLS_SPB*/tools/spbat/generic/SPBAT")
                  Start-Process `
                    -FilePath "$(Resolve-Path -Path './spbat.bat')" `
                    -ArgumentList @( `
                          "-phase apply", `
                          "-oracle_home ${$weblogic_path}" `
                    ) `
                    -Wait `
                    -ErrorAction Stop `
                    -NoNewWindow | Out-Null
                } Catch {
                  Exit 1
                }
              |-EOT
            provider  => powershell,
            logoutput => true,
            timeout   => 600,
            require   => [ Exec["Expand ${patch_path} to ${pkgtemp}"] ],
          }

          exec { "Delete ${pkgtemp} Directory" :
            command   =>  Sensitive(@("EOT")),
                New-Item -Path ${regsubst("\'${weblogic_path}-empty\'", '(/|\\\\)', '\\', 'G')} -Type Directory -Force

                Start-Process `
                  -FilePath "C:\\windows\\system32\\Robocopy.exe" `
                  -ArgumentList @( `
                    ${regsubst("\'${weblogic_path}-empty\'", '(/|\\\\)', '\\', 'G')}, `
                    ${regsubst("\'${pkgtemp}\'" ,'/', '\\\\', 'G')}, `
                    "/E /PURGE /NOCOPY /MOVE /NFL /NDL /NJH /NJS > nul" `
                  ) `
                  -Wait `
                  -NoNewWindow | Out-Null

                Get-Item -Path ${regsubst("\'${pkgtemp}\'" ,'/', '\\\\', 'G')} -ErrorAction SilentlyContinue `
                | Remove-Item -Force -Recurse
              |-EOT
            provider  => powershell,
            logoutput => true,
            require   => [ Exec["Deploy ${pkgtemp}"] ],
          }
        }
      }
    }
  }
}

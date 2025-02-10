#securepass.txt file
read-host -prompt "Enter password to be encrypted in securepass.txt "
-assecurestring | convertfrom-securestring | out-file "\\ODIN\Users\Administrator\Desktop\SCCM\SCCM Boot Images\PowerShellScripts\adminPass.txt"
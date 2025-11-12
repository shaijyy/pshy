# PSHY: Powershell scripts heck yeah!
### A curated list of PowerShell scripts to do various stuff on Windows :)

> **Note:** Exported data may contain sensitive info. Keep private.  
> **Warning:** Always inspect any script before ***iex***-ing it. Don’t run remote code you don’t trust.

1. **Gimme Product Key**  
   Gives the user the Product Key used to activate Windows on that device.  
   USAGE:
   ```powershell
   irm https://dub.sh/gimme_product_key | iex
   ```

2. **Gimme System Info**  
   Generates a full system report: OS, CPU, RAM, disks, network adapters, BIOS, uptime, top processes, and installed hotfixes.  
   Can optionally export JSON, CSV, or TXT reports.  
   USAGE:
   ```powershell
   irm https://dub.sh/gimme_system_info | iex
   ```


3. **Gimme Installed Apps**  
   Lists installed applications from registry (Win32) and optionally Appx/UWP packages.  
   Can export to CSV, JSON, or TXT.  
   USAGE:
   ```powershell
   irm https://dub.sh/gimme_installed_apps | iex
   ```
   

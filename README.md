# Examples-of-PowerShell-Scripts-MF
 **This GIt Repo Is for examples for Muscle Food only**


## Exchange Migration Scripts

* __*01 - Gather Ad Sec Group permissions on Shared MBs*__
* __*02 - Add Explicit Permissions onto Shared Mailboxes*__
* __*03 - Remove AD Sec Group from permissions on Shared MB*__

These scripts where part of a little project to prepare the shared mailboxes for migration to Exchange Online. We needed to remove any permissions on shared mailboxes which were applied using a AD security group, as Exchange Online doesn’t support on-premise AD groups. We successfully went through over 1000 shared mailboxes within an afternoon to allow for a faster migration.

* __*Setting Correct Routing Address after Migration*__

I created this script when I found that during the migration of our Exchange, I found that emails were not being delivered to people post migration. During research, I was able to identify that the routing address for the on-prem Exchange had not be changed to the @(*O365TenantPrefix*.).Mail.Onmicrosoft.com address. With our set up, this meant that the users’ emails were being delivered to on-prem exchange, where they would be missing. This script allowed us to close a lot of tickets and change the migration process to make sure the routing address was set correctly.

## Office 365

* __*Check-O365GUID*__

This was created when some users were recreated within AD, were not syncing up their O365/Azure AD account. It would get the on-prem AD Object GUID for the user and convert it into Base64. Base64 is the format of data which the ImmutableID uses which is the GUID for the O365 user. We were then able to confirm if this was the issue and speed up fixes.

* __*Grant-MailboxAccessMFA*__
* __*Remove-MailboxAccessMFA*__

Both functions were created to allow the team to more easily apply permission in line with our processes. It also allowed for easier on boarding for promoted members of the team which needed to perform theses actions. Before I left MyDentist, the next step was to create more of these scripts to allow the Helpdesk to perform theses task to free us up for project work and keep it uniform.

## Server Migration (2008 to 2012)

* __*Audit of ESXI Information for Upgrading*__

This was used to access all our 600+ servers within the estate and collect information on their configuration then store this data within a SQL database I had created. This allowed the engineering and project team to better plan best course of action and efficiently tackle any prerequisites before starting the project. Unfortunately, we didn’t have the correct license available for me to change the configuration remotely.

* __*SQLSERVER Automation Step 1-4*__
* __*SQLSERVER Automation Step 6-9*__
* __*SQLSERVER Automation Step 14-18*__
* __*Printer Migration Tool.bat*__

My last project I worked on in MyDentist was to upgrade the servers from Windows Server 2008 R2 to Windows Server 2012 R2, in line with the end of life of the product. In total, we had 500 servers to upgrade between to January 14, 2020 (EOL). I left before the project completed but theses scripts allowed the team of 3-4 to go from 2 servers a night to 4 to 5. This dramatically improved the delivery and cut out most, if not all, of the human error during upgrades. This meant our sites did not experience any down time due to the upgrade unless there were any hardware errors. 

## Unique User Project

* __*New-UniqueUser (ADHOC)*__

We had to roll out between 2500-3500 unique users to all our dentists. Due to my work within PowerShell and automation, I was tasked to help our infrastructure project manager deliver this roll-out. I created this advanced function to allow me to quickly process the accounts, generating a random secure password and assigning them to the correct groups depending on their practice. All data created with this script was imported into a SQL database for auditing then exported directly into an excel document for the Project Manager to distribute the account information to the sites manager to give to the dentist. 

* __*Create-DentistPerSite*__

As the project manager was also a member of the infrastructure team and trusted, I created this script to allow him to run this script. As this was a script and following the same process/logic of my script, there was no change in process and allowed me to be freed up for other tasks. The way the script is created, the Project Manager was happy with the process and the project got praise from the leadership team.

## Others

* __*New-ENWLUser*__

I have made this script in both of my companies. It is a standard user creation script but modified to match different business processes. I created Validated Sets within some parameters to stop any non-uniform data being inputted. When I joined the business, the 3rd party service desk was having issue whereas they were creating users but some of the information was either incorrect or misspelt which would cause some of the on boarding to be incorrect. This script uniformed the process, and both allowed for a smooth onboarding but also elevated pressure on the department. 

* __*Restore-AX*__

When I joined our project department as a technical lead, we were in the process of onboarding/supporting the new HR/Payroll system. The infrastructure was hosted within Azure and application was supported by a 3rd party company. When it came to the 3rd party working in our DEV/TEST/UAT environments, they would need us to restore data from another environment and make sure the system was available for use. Once this task was given to me, I was told it would normally take a working day or more to complete. The HR department were the owners of the service and were very keen on speeding up delivery of the environments to allow for quicker testing/deployments. As the application was so critical to the business, when a restore was needed, we had to drop our other work to cover the support. This was causing delays in other work which the other Project Managers could not afford to do. I decided, when I joined the team, to try and alleviate this and potentially speed up the process.

This script helped the restore the environment from a full working day to 2 hours.

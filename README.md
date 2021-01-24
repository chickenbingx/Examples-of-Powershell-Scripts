# Examples-of-Powershell-Scripts-MF
 **This GIt Repo Is for examples for Muscle Food only**


## Exchange Migration Scripts

* __*01 - Gather Ad Sec Group permissions on Shared MBs*__
* __*02 - Add Explicit Permissions onto Shared Mailboxes*__
* __*03 - Remove AD Sec Group from permissions on Shared MB*__

These scripts where part of a little project to prepare the shared mailboxes for migration to Exchange Online. We needed to remove any permissions on shared mailboxes which were applied using a AD security group, as Exchange Online doesnt support on-premise AD groups. We sucuessfully went through over 1000 shared mailboxes within an afternoon to allow for a faster migration.

* __*Setting Correct Routing Address after Migration*__

I created this script when i found that during the migration of our Exchange, I found that emails were not being delivered to people post migration. During research, i was able to identify that the routing address for the on-prem Exchange had not be changed to the @(*O365TenantPrefix*.).Mail.Onmicrosoft.com address. With our set up, this meant that the users emails were being delivered to on-prem exchange, where they would be missing. This script allowed us to close alot of tickets and change the migration process to make sure the routing address was set correctly.

## Office 365

* __*Check-O365GUID*__

This was created when some users were recreated within AD, were not syncing up their O365/Azure AD account. It would get the on-prem AD Object GUID for the user and convert it into Base64. Base64 is the format of data which the ImmutableID uses which is the GUID for the O365 user. We were then able to confirm if this was the issue and speed up fixes.

* __**__

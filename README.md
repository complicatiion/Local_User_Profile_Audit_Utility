# Local User Profile Audit Utility

Batch script for auditing, reporting, and cleaning local and domain user profiles on a Windows PC.

## Functions

- **List user accounts and profiles**  
  Shows detected local and domain/external profiles with basic profile details.

- **Profile details and last usage sorting**  
  Displays profile type, last use time, inactivity age, status, and path sorted by oldest to newest.

- **Profile size check**  
  Calculates profile sizes and shows storage usage per profile.

- **Report generation**  
  Creates a TXT report in:
  `Desktop\UserReports`

- **Delete profile (clean)**  
  Removes a selected Windows profile using `Win32_UserProfile`.

- **Delete local user account**  
  Deletes a selected local Windows account.

- **Delete profile and local account**  
  Removes both the selected profile and its related local account.

- **Delete all domain/external profiles**  
  Deletes all non-local profiles while keeping local profiles intact.

- **Delete old domain profiles only**  
  Deletes only domain/external profiles older than the configured threshold.

- **Whitelist support**  
  Automatically protects profiles with `ADMP` or `Admin` in the profile name.

- **Loaded profile protection**  
  Skips profiles that are currently loaded and in use.

- **Old domain profile preview**  
  Shows matching old domain profiles before deletion.

- **Local profile protection**  
  Local profiles on the PC are preserved during domain-profile cleanup.

## Notes

- Administrator rights are required for deletion actions.
- Profile age threshold is currently set to **60 days**.
- Whitelist matching is based on the local profile folder name.


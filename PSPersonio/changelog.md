# Changelog
## 0.1.4 (2023-07-11)
 - Fix:
    - Personio.Absence.AbsencePeriod: \
    Fix wrong type definition on member "DaysCount". Previously, it was an \[int\], actually it is a \[float\]

## 0.1.3 (2023-06-28)
 - Upd:
    - Connect-Personio: Starting June 2023 Personio decides to step away from JWT tokens and began to invent a service specific token format. This update handles both behaviours.\
    So, the update is highly RECOMMENDED to not break the auth process.
## 0.1.2 (2023-01-28)
 - Fix:
    - Connect-Personio: broken token creation. v0.1.0 was unable to login to service. fixed
## 0.1.0 (2023-01-26)
 - New: Frist Version with commands
    -  API core service commands
        - Connect-Personio
        - Invoke-PersRequest

    - Absence
        - Get-PERSAbsenceType
        - Get-PERSAbsence
        - New-PERSAbsence
        - Remove-PERSAbsence
        - Get-PERSAbsenceSummary
    - Attendance
        - Get-PERSAttendance
        - New-PERSAttendance
        - Remove-PERSAttendance

    - Employee
        - Get-PERSEmployee
 - Upd: ---
 - Fix: ---
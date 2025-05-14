mkdir C:\BitLockerKeys
manage-bde -on C: -RecoveryPassword -RecoveryKey C:\BitLockerKeys -SkipHardwareTest
manage-bde -protectors -get C:

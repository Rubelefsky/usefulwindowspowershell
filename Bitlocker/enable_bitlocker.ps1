mkdir C:\BitLockerKeys

# Add a recovery password protector and save the recovery key
manage-bde -protectors -add C: -RecoveryPassword
manage-bde -protectors -add C: -RecoveryKey C:\BitLockerKeys

# Now enable BitLocker
manage-bde -on C: -SkipHardwareTest

# (Optional) Show protectors
manage-bde -protectors -get C:
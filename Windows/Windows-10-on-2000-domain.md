# Windows 10 on 2000 domain

## Credentials manager error: 0x80090345

Dette er lidt noget bras, men dette skyldes at DC’et er så gammelt at de ikke mere kan snakke sammen korrekt og gemme legitimationsoplysninger.

Dette blokerer blandt andet også aktivering af Office pakken.

## Reg key tilrettelse for at få legitimations manager til at virke igen

    HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography\Protect\Providers\df9d8cd0-1501-11d1-8c7a-00c04fc297eb
    DWORD(32-Bit): ProtectionPolicy=1

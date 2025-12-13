# Ručni testovi: korisnici, grupe i sudo pravila

Ovaj dokument opisuje ručne testove za provjeru da FreeIPA korisnici, grupe i sudo pravila implementiraju princip najmanje privilegije (PoLP).

## Priprema

- Pretpostavka: FreeIPA server je konfiguriran prema `implementation/setup.md`.
- Klijent je uspješno pridružen domeni i ima omogućen SSSD sudo responder.
- Sljedeći testovi se izvode na klijentskom stroju.

## Test 1: Ivana (System Administrator) – puni pristup

**Korisnik:** `ivana`  
**Grupa:** `sysadmins`  
**Očekivanje:** Ivana može izvršavati bilo koju sudo naredbu (puni root pristup).

Koraci:
```bash
ssh ivana@ipa1.iam.lab
```
(_unesi ivana lozinku_)
```bash
sudo id
sudo whoami 
sudo cat /etc/shadow 
exit
```


Očekivani ishodi:

- `sudo id` vraća `uid=0(root)`.
- `sudo whoami` vraća `root`.
- `sudo cat /etc/shadow` se izvršava bez greške.

## Test 2: Pero (Developer) – bez sudo pristupa

**Korisnik:** `pero`  
**Grupa:** `developers`  
**Očekivanje:** Pero nema nikakav sudo pristup.

Koraci:
```bash
ssh pero@ipa1.iam.lab
```
(_unesi pero lozinku_)
```bash
sudo id
exit
```

Očekivani ishodi:

- Pokušaj `sudo id` završava porukom da korisnik ne smije pokretati sudo na tom hostu.

## Test 3: David (IT Support) – ograničen na dijagnostiku

**Korisnik:** `david`  
**Grupa:** `itsupport`  
**Očekivanje:** David može koristiti samo dijagnostičke naredbe (journalctl, ss), ali ne i ostale privilegirane naredbe.

Koraci:
```bash
ssh david@ipa1.iam.lab
```
(_unesi david lozinku_)
```bash
sudo journalctl -n 5
sudo ss -tuln
sudo cat /etc/shadow
exit
```

Očekivani ishodi:

- `sudo journalctl -n 5` i `sudo ss -tuln` se izvršavaju uspješno.
- `sudo cat /etc/shadow` je odbijen uz poruku da korisnik nema dopuštenje.

## Test 4: Ana (Web Administrator) – ograničene web naredbe

**Korisnik:** `ana`  
**Grupa:** `webadmins`  
**Očekivanje:** Ana može upravljati web servisom, ali nema opći root pristup.

Koraci:
```bash
ssh ana@ipa1.iam.lab
```
(_unesi ana lozinku_)
```bash
sudo systemctl status nginx
sudo systemctl restart httpd
sudo journalctl -n 5
sudo whoami
exit
```

Očekivani ishodi:

- `sudo systemctl status nginx` i `sudo systemctl restart httpd` rade.
- `sudo journalctl -n 5` i `sudo whoami` su odbijeni.


Cilj ovih testova je potvrditi da:

- samo sysadmini imaju puni root pristup,
- webadmini imaju minimalne potrebne privilegije za web,
- IT support ima samo dijagnostiku,
- developeri nemaju sudo.

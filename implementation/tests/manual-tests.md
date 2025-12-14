# 1. Korisnici, grupe i sudo pravila

Ovaj dio dokumenta opisuje ručne testove za provjeru da FreeIPA korisnici, grupe i sudo pravila implementiraju princip najmanje privilegije (PoLP).

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

![polp-sysadmin-ivana-id-whoami-allowed](https://github.com/mbanovic21/identity-and-authentication-management-system/blob/main/results/screenshots/polp-sysadmin-ivana-id-whoami-allowed.jpg)

![polp-sysadmin-ivana-shadow-allowed](https://github.com/mbanovic21/identity-and-authentication-management-system/blob/main/results/screenshots/polp-sysadmin-ivana-shadow-allowed.jpg)

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

![polp-developer-pero-sudo-denied](https://github.com/mbanovic21/identity-and-authentication-management-system/blob/main/results/screenshots/polp-developer-pero-sudo-denied.jpg)

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

![polp-itsupport-david-journalctl-allowed](https://github.com/mbanovic21/identity-and-authentication-management-system/blob/main/results/screenshots/polp-itsupport-david-journalctl-allowed.jpg)

![polp-itsupport-david-ss-allowed](https://github.com/mbanovic21/identity-and-authentication-management-system/blob/main/results/screenshots/polp-itsupport-david-ss-allowed.jpg)

![polp-itsupport-david-shadow-denied](https://github.com/mbanovic21/identity-and-authentication-management-system/blob/main/results/screenshots/polp-itsupport-david-shadow-denied.jpg)

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

![polp-webadmin-ana-httpd-allowed](https://github.com/mbanovic21/identity-and-authentication-management-system/blob/main/results/screenshots/polp-webadmin-ana-httpd-allowed.jpg)

![polp-webadmin-ana-nginx-allowed](https://github.com/mbanovic21/identity-and-authentication-management-system/blob/main/results/screenshots/polp-webadmin-ana-nginx-allowed.jpg)

![polp-webadmin-ana-journal-whomai-denied](https://github.com/mbanovic21/identity-and-authentication-management-system/blob/main/results/screenshots/polp-webadmin-ana-journal-whoami-denied.jpg)

Cilj ovih testova je potvrditi da:

- samo sysadmini imaju puni root pristup,
- webadmini imaju minimalne potrebne privilegije za web,
- IT support ima samo dijagnostiku,
- developeri nemaju sudo.

# 2. Brute-force napad i zaključavanje računa

## Cilj
Potvrditi da password policy (Max failures, Failure reset interval, Lockout duration) ispravno zaključava račun nakon previše pogrešnih lozinki.

## Preduvjeti
- FreeIPA server s globalnom password policy:
  - Max failures: 5
  - Failure reset interval: 300 s
  - Lockout duration: 600 s
- Klijentski sustav postavljen u FreeIPA (SSSD radi).
- Test korisnik: ivana.

## Koraci
**1. Na klijentskom sustavu:**
```bash
ssh ivana@ipa1.iam.lab
```
- Potrebno je 5 puta unijeti namjerno pogrešnu lozinku

**2. Šesti pokušaj s točnom lozinkom:**
- Očekivano: login ne uspijeva, poruka o zaključanom računu.

![brute-force-client](https://github.com/user-attachments/assets/78f2de97-9d51-458d-9d9a-5631e0fbf3f7)

**3. Nakon 600 s ili nakon `ipa user-unlock ivana` na serveru:**
- Ponovni login s točnom lozinkom uspijeva.

## Očekivani rezultat
- Nakon Max failures pokušaja, račun je zaključan za vrijeme definirano u Lockout duration.
- FreeIPA time-based lockout mehanizam radi i time mitigira brute-force napade.

![brute-force-server](https://github.com/mbanovic21/identity-and-authentication-management-system/blob/main/results/screenshots/brute-force-server.png)


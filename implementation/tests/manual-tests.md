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

# 3. Testiranje autentifikacije putem GUI klijentske aplikacije

Ovo poglavlje opisuje ručne testove provedene pomoću jednostavne GUI klijentske aplikacije razvijene u Pythonu, čija je svrha testiranje autentifikacije korisnika prema FreeIPA sustavu.
GUI aplikacija služi kao alternativni klijentski ulaz u sustav, uz SSH, te koristi Kerberos mehanizam (kinit) za provjeru korisničkih vjerodajnica.

Cilj ovih testova je potvrditi da se iste autentifikacijske i sigurnosne politike (neispravna lozinka, zaključavanje računa) primjenjuju neovisno o načinu pristupa sustavu (CLI ili GUI).

## Priprema

**Pretpostavke:**

* FreeIPA server je konfiguriran prema dokumentu implementation/setup.md.

* Klijentski sustav je pridružen FreeIPA domeni.

* Kerberos autentifikacija (kinit) radi ispravno na klijentu.

* GUI aplikacija je pokrenuta na klijentskom sustavu.

## Test 1: Uspješna autentifikacija putem GUI-a

**Korisnik:** `ivo`

**Očekivanje:** Autentifikacija s ispravnim vjerodajnicama uspješno prolazi.

### Koraci:

1. Pokrenuti GUI aplikaciju na klijentskom sustavu.

2. U polje za korisničko ime unijeti ivo.

3. U polje za lozinku unijeti ispravnu lozinku.

4. Kliknuti na gumb za prijavu.

### Očekivani ishodi:

GUI aplikacija prikazuje poruku o uspješnoj autentifikaciji.

![ispravni_podaci](https://github.com/mbanovic21/identity-and-authentication-management-system/blob/main/results/screenshots/prijava_ispravni_podaci.png?raw=true)

## Test 2: Neuspješna autentifikacija – pogrešna lozinka

**Korisnik:** `ivo`

**Očekivanje:** Autentifikacija ne prolazi zbog pogrešne lozinke.

### Koraci:

1. Pokrenuti GUI aplikaciju.

2. Unijeti korisničko ime ivo.

3. Unijeti namjerno pogrešnu lozinku.

4. Kliknuti na gumb za prijavu.

### Očekivani ishodi:

GUI aplikacija prikazuje poruku o neuspješnoj autentifikaciji (pogrešna lozinka).

![neispravni_podaci](https://github.com/mbanovic21/identity-and-authentication-management-system/blob/main/results/screenshots/pokusaj_prijave_neto%C4%8Dna_lozinka.png?raw=true)


## Test 3: Zaključavanje korisničkog računa putem GUI-a (brute-force simulacija)

**Korisnik:** ivo
**Očekivanje:** Račun se zaključava nakon maksimalnog broja neuspješnih pokušaja prijave.

### Preduvjeti:

* FreeIPA password policy:

* Max failures: 5

* Failure reset interval: 300 s

* Lockout duration: 600 s

### Koraci:

1. Pokrenuti GUI aplikaciju.

2. Pet puta uzastopno pokušati prijavu s pogrešnom lozinkom.

3. Šesti put pokušati prijavu s ispravnom lozinkom.

### Očekivani ishodi:

* GUI aplikacija prikazuje poruku da je korisnički račun zaključan.

* Autentifikacija ne prolazi unatoč ispravnoj lozinci.

![zakljucan_profil](https://github.com/mbanovic21/identity-and-authentication-management-system/blob/main/results/screenshots/prijava_nakon_zakljucavanja_profila.png?raw=true)

## Test 4: Ponovna autentifikacija nakon isteka lockouta

**Korisnik:** ivo
**Očekivanje:** Autentifikacija ponovno uspijeva nakon isteka lockout perioda ili ručnog otključavanja računa.

### Koraci:

1. Pričekati isteka vremena definiranog u Lockout duration (600 s)
ili otključati korisnika na FreeIPA serveru pomoću:

`ipa user-unlock ivana`


2. Pokrenuti GUI aplikaciju.

3. Pokušati prijavu s ispravnom lozinkom.

### Očekivani ishodi:

* GUI aplikacija prikazuje poruku o uspješnoj autentifikaciji.

## Zaključak

Provedeni testovi potvrđuju da FreeIPA autentifikacijske i sigurnosne politike (neispravna lozinka, zaključavanje računa) djeluju jednako neovisno o klijentskom sučelju.
Time je potvrđeno da se mehanizmi zaštite od brute-force napada konzistentno primjenjuju i na razini aplikacijskog klijenta.

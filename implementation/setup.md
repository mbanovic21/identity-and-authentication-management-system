# Setup
# 1. Implementacija IAM poslužitelja (FreeIPA) – Infrastructure & Server Core

**Autor:** _Matej Banović_  
**Uloga:** Član 1 – Inženjer za infrastrukturu i Server Core  
**Tehnologije:** VirtualBox, Rocky Linux 9, FreeIPA (LDAP + Kerberos + DNS)

---

## 1. Uloga i ciljevi

Moja uloga u projektu je:

1. **Postavljanje IAM poslužitelja** – instalacija i osnovna konfiguracija FreeIPA servera na virtualnoj mašini.
2. **Konfiguracija jezgre sustava** – LDAP, Kerberos, mrežne postavke, DNS.
3. **Implementacija password politika** – definiranje i testiranje sigurnosnih pravila lozinki (duljina, složenost, povijest, lockout).

Cilj je osigurati stabilnu i sigurnu bazu na koju se ostali članovi tima mogu osloniti (klijent konfiguracija, PoLP, sudo pravila, dodatne usluge).

---

## 2. Arhitektura i okruženje

### 2.1. Logička arhitektura

- **IAM server (FreeIPA)**  
  - LDAP (389 Directory Server) – pohrana korisnika, grupa i ostalih objekata  
  - Kerberos KDC – centralna autentikacija i SSO  
  - Dogtag CA – certifikati (unutarnja PKI)  
  - DNS – centralni DNS za domenu `iam.lab`

- **Klijentske VM-ove** (radit će ostatak tima)  
  - Linux klijenti pridruženi u FreeIPA domenu  
  - Autentikacija korisnika prema FreeIPA-u

### 2.2. Odabrana domena i imena

| Element          | Vrijednost           |
|------------------|----------------------|
| DNS domena       | `iam.lab`            |
| Kerberos realm   | `IAM.LAB`            |
| FQDN servera     | `ipa1.iam.lab`       |
| Hostname (short) | `ipa1`               |
| Primjer IP adrese| `192.168.56.10`      |

(*IP adresa se prilagođava prema stvarnoj mreži / Host-only mreži u VirtualBoxu.*)

---

## 3. Priprema virtualne mašine

### 3.1. Kreiranje VM-a u VirtualBoxu

1. **New → Name and operating system**
   - Name: `IAM-IPA-Server`
   - Type: `Linux`
   - Version: `Red Hat (64-bit)` ili `Other Linux (64-bit)` (za Rocky Linux).

2. **Memory size**
   - 4096 MB (4 GB) – preporučeno  
   - Minimalno 2048 MB (2 GB), ali FreeIPA radi ugodnije s 4 GB.

3. **Hard disk**
   - Create a virtual hard disk now → VDI → Dynamically allocated → 20 GB ili više.

4. **Network**
   - Adapter 1: `Host-only Adapter` (za komunikaciju s klijentima i hostom).
   - Adapter 2 (opcionalno, ali preporučeno): `NAT` (za pristup internetu iz VM-a).

Ovim dobivamo:
- Host-only mrežu (npr. 192.168.56.0/24) za internu komunikaciju s klijentima.
- NAT za pristup internetu (update, paketi).

### 3.2. Instalacija OS-a (Rocky Linux 9)

1. Preuzeti `Rocky Linux 9` ISO (npr. DVD ili Minimal).
2. U VirtualBoxu u `Settings → Storage` mountati ISO na optički pogon VM-a.
3. Pokrenuti VM i slijediti installer:
   - Jezik: npr. English (United States) ili Hrvatski.
   - Installation Destination: automatsko particioniranje je dovoljno.
   - Network & Hostname:
     - Uključiti mrežu.
     - Postaviti hostname (kasnije ćemo ga precizno podesiti, ali može odmah npr. `ipa1.iam.lab`).
   - Root password i/ili kreiranje korisnika s admin privilegijama.
4. Po završetku instalacije, reboot.

---

## 4. Osnovna konfiguracija OS-a

Nakon logina u VM (kao user sa sudo pravima ili root):

### 4.1. Postavljanje točnog hostname-a

```bash
sudo hostnamectl set-hostname ipa1.iam.lab
```
Provjera:
```bash
hostname
hostnamectl
hostname -f
```
Očekivani outputi:
* `hostname` -> `ipa1`
* `hostnamectl` -> `Static hostname: ipa1.iam.lab`
* `hostname -f` -> `ipa1.iam.lab`

---

### 4.2. Provjera IP adrese
```bash
ip addr
```
Bilježi se IP adresa Host-only adaptera, npr. `192.168.X.X`

---

### 4.3. Uređivanje `/etc/hosts`
```bash
sudo nano /etc/hosts
```
Primjer sadržaja (prilagoditi IP):
```bash
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

192.168.56.10   ipa1.iam.lab   ipa1
```
**Važno: FQDN ipa1.iam.lab mora biti vezan uz pravu IP adresu VM-a (ne stavljati FQDN uz 127.0.0.1)!**

Provjera:
```bash
ping -c 3 ipa1.iam.lab
ping -c 3 ipa1
```

---

### 4.4 Ažuriranje sustava
```bash
sudo dnf update -y
sudo reboot
```

---

### 4.5. Firewall i SELinux

Za potrebe laboratorija:

* SELinux je ostavljen u **enforcing** (FreeIPA ga podržava),
* firewall je privremeno zaustavljen radi jednostavnosti testiranja
  (kod produkcije bi se otvorili samo potrebni portovi).

Komande:

```bash
sudo systemctl stop firewalld
sudo systemctl disable firewalld
```

Provjera:

```bash
sudo systemctl status firewalld
```

---

## 5. Instalacija FreeIPA servera

### 5.1. Instalacija potrebnih paketa

```bash
sudo dnf install -y ipa-server ipa-server-dns
```

**Objašnjenje:**

* `ipa-server` → osnova FreeIPA (LDAP, Kerberos, web sučelje, CA),
* `ipa-server-dns` → omogućuje da FreeIPA upravlja DNS zonom (`iam.lab`).

---

### 5.2. Pokretanje glavnog setupa (`ipa-server-install`)

Pokrenuo sam instalacijski čarobnjak:

```bash
sudo ipa-server-install --setup-dns
```

Zatim sam odgovorio na pitanja (tekst može malo varirati ovisno o verziji):

1. **Server host name**

   * predloženo: `ipa1.iam.lab`
   * potvrđeno: **Enter**

2. **Domain name**

   * predloženo: `iam.lab`
   * potvrđeno: **Enter**

3. **Realm name**

   * predloženo: `IAM.LAB`
   * potvrđeno: **Enter**

4. **Directory Manager password**

   * unesena jaka lozinka (npr. `s1spr0jekt@!`)
   * ova lozinka se ne koristi u svakodnevnom radu, ali je kritična za LDAP administraciju.

5. **IPA admin password**

   * unesena lozinka za korisnika `admin` (FreeIPA administrator).

6. **DNS forwarders**

   * odabrao sam da želim koristiti DNS forwarder → `8.8.8.8` (Google DNS).
   * to omogućuje da FreeIPA rješava i vanjske domene.

7. **Reverse zone**

   * za laboratorijske potrebe prihvatio sam kreiranje predložene reverse zone.

Na kraju čarobnjak prikaže sažetak konfiguracije i pita:

> Continue to configure the system with these values? (yes/no)

Odabrano je: `yes`.

Nakon nekoliko minuta instalacije, pojavila se poruka:

> The ipa-server-install command was successful

Time je:

* podignut LDAP (389-ds),
* konfiguriran Kerberos KDC i admin server,
* postavljen DNS,
* generirani potrebni certifikati,
* kreiran `admin` korisnik.

---

## 6. Verifikacija rada FreeIPA servera

### 6.1. Kerberos autentifikacija

Prvo sam učitao Kerberos ticket za admina:

```bash
kinit admin
```

Unio sam `admin` lozinku definiranu tijekom instalacije.

Provjera:

```bash
klist
```

Očekivani rezultat:

* `Default principal: admin@IAM.LAB`
* ticket validan određeni vremenski period (npr. 10h)

Ako `kinit` ne uspije, instalacija nije ispravna ili postoji problem s vremenom/DNS-om.

---

### 6.2. Test `ipa` CLI alata

Provjera dostupnosti korisnika:

```bash
ipa user-find
```

Očekivano:

* prikazuje se barem `admin` korisnik i eventualno sistemski nalozi.

Time je potvrđeno da:

* Kerberos radi (autentifikacija admina),
* LDAP radi (dohvaćanje liste korisnika),
* mrežna konfiguracija i DNS su ispravni.

---

## 7. Konfiguracija Password Policy (pravila lozinki)

Jedan od ključnih dijelova moje uloge je implementacija sigurnosnih pravila lozinki.

### 7.1. Pregled početne politike

Prvo sam pogledao trenutne postavke:

```bash
ipa pwpolicy-show
```

Ovdje se prikazuje:

* minimalna duljina lozinke,
* minimalan broj klasa znakova,
* broj dozvoljenih neuspjelih prijava,
* vrijeme zaključavanja itd.

### 7.2. Odabrana sigurnosna pravila

Dogovorena password politika za projekt:

* **Minimalna duljina lozinke:** 12 znakova
* **Minimalan broj klasa znakova:** 3 (mala slova, velika slova, brojke, specijalni znakovi)
* **Povijest lozinki:** 5 (korisnik ne smije ponovno koristiti zadnjih 5 lozinki)
* **Maksimalan broj neuspjelih prijava:** 5
* **Fail interval:** 300 sekundi (5 min) – u tom razdoblju se broje neuspjele prijave
* **Lockout vrijeme:** 900 sekundi (15 min) – račun ostaje zaključan nakon prekoračenja broja pokušaja

Postavljanje je napravljeno serijom pojedinačnih komandi:

```bash
ipa pwpolicy-mod --minlength=12
ipa pwpolicy-mod --minclasses=3
ipa pwpolicy-mod --history=5
ipa pwpolicy-mod --maxfail=5
ipa pwpolicy-mod --failinterval=300
ipa pwpolicy-mod --lockouttime=900
```

Nakon svake komande mogla se izvršiti provjera:

```bash
ipa pwpolicy-show
```

da bi se potvrdilo da su vrijednosti ažurirane.

---

## 8. Kreiranje testnog korisnika i testiranje password politike

### 8.1. Kreiranje testnog korisnika

Kreiran je korisnički račun:

```bash
ipa user-add testuser --first=Test --last=User
```

Ova komanda **ne traži odmah lozinku**, pa sam je naknadno postavio preko:

```bash
ipa passwd testuser
```

Zatim sam testirao password policy:

1. **Pokušaj slabe lozinke**

   * npr. `lozinka`
   * očekivani rezultat: FreeIPA odbija lozinku jer ne zadovoljava minimalnu duljinu i složenost.

2. **Pokušaj jake lozinke**

   * npr. `JakaLozinka123!`
   * očekivani rezultat: lozinka prihvaćena.

Ovim je potvrđeno da se pravila složenosti i duljine primjenjuju.

---

### 8.2. Testiranje lockout mehanizma

Testirano je zaključavanje računa nakon više neuspjelih prijava:

1. Na serveru (ili klijentu, kada bude spojen), pokrenuo sam:

   ```bash
   kinit testuser
   ```

2. Namjerno sam unio **pogrešnu lozinku 5 puta zaredom** (koliko je postavljeno `--maxfail=5`).

3. Nakon toga, i s ispravnom lozinkom račun je bio privremeno zaključan (`lockouttime=900`).

Ovisno o verziji i konfiguraciji, dodatni detalji o zaključavanju mogu se vidjeti u logovima:

```bash
sudo journalctl -u krb5kdc | tail
sudo journalctl -u dirsrv@IAM-LAB.service | tail
```

*(napomena: naziv `dirsrv@IAM-LAB.service` može se malo razlikovati, ali princip je isti)*

---

## 9. Priprema za povezivanje klijenata (kratki pregled)

Detaljna konfiguracija klijenata bit će dio zadatka drugih članova tima, ali ovdje navodim osnovne preduvjete koje sam osigurao:

* FreeIPA server je dostupan na IP adresi `192.168.56.10` (Host-only mreža),
* DNS ime `ipa1.iam.lab` ispravno se mapira na tu IP adresu,
* Kerberos realm: `IAM.LAB`,
* domain: `iam.lab`.

Tipičan klijent (npr. drugi Rocky Linux 9 VM) će se povezivati pomoću:

```bash
sudo dnf install -y ipa-client sssd oddjob oddjob-mkhomedir adcli samba-common-tools
sudo ipa-client-install --mkhomedir
```

Tijekom `ipa-client-install` klijent će koristiti:

* domain: `iam.lab`,
* server: `ipa1.iam.lab`,
* realm: `IAM.LAB`,
* korisnika `admin` za enrolment.

# 2. Upravljanje identitetima i pristupom – Users, Groups & PoLP

**Autor:** _Lana Ljubičić_  
**Uloga:** Član 2 – Inženjer za identitete i upravljanje pristupom  
**Tehnologije:** VirtualBox, Rocky Linux 9, FreeIPA

Ovaj dio opisuje konkretne korake za reprodukciju konfiguracije korisnika, grupa i sudo pravila u FreeIPA serveru. Pretpostavlja se da je FreeIPA server već instaliran i inicijalno konfiguriran (koraci člana 1) te da je administrator prijavljen kao `admin`.

## 0. Priprema

```bash
kinit admin
```

(_unesite lozinku za admin korisnika_)

## 1. Kreiranje korisnika

Sljedeće naredbe kreiraju testne korisnike koji će se koristiti za provjeru PoLP-a (za svakog korisnika potrebno je kreirati lozinku):

```bash
ipa user-add ivana --first=Ivana --last=Ivic --email=ivana@iam.lab --password 
ipa user-add ivo --first=Ivo --last=Ivanic --email=ivo@iam.lab --password
ipa user-add marija --first=Marija --last=Maric --email=marija@iam.lab --password
ipa user-add marta --first=Marta --last=Miric --email=marta@iam.lab --password
ipa user-add pero --first=Pero --last=Peric --email=pero@iam.lab --password
ipa user-add david --first=David --last=Horvat --email=david@iam.lab --password
ipa user-add ana --first=Ana --last=Anic --email=ana@iam.lab --password
```

Nakon kreiranja korisnika može se provjeriti stanje:

`ipa user-find`

## 2. Kreiranje grupa i dodavanje članova

Definiraju se četiri uloge u obliku FreeIPA grupa i članovi tih grupa:

Kreiranje grupa
```bash
ipa group-add sysadmins --desc="System Administrators"
ipa group-add developers --desc="Developers"
ipa group-add webadmins --desc="Web Server Admins"
ipa group-add itsupport --desc="IT Support Team"
```

Dodavanje korisnika u grupe
```bash
ipa group-add-member sysadmins --users=ivana
ipa group-add-member sysadmins --users=marta
ipa group-add-member developers --users=ivo
ipa group-add-member developers --users=marija
ipa group-add-member developers --users=pero
ipa group-add-member webadmins --users=ana
ipa group-add-member itsupport --users=marta
ipa group-add-member itsupport --users=david
```

Provjera grupa i članova:

```bash
ipa group-find
ipa group-show sysadmins
ipa group-show developers
ipa group-show webadmins
ipa group-show itsupport
```

## 3. Sudo pravila (PoLP)

### 3.1 System administrators – `sysadmin_all`

Puno sudo pravo za članove `sysadmins`:

```bash
ipa sudorule-add sysadmin_all --hostcat=all --runasusercat=all --runasgroupcat=all --cmdcat=all
ipa sudorule-add-user sysadmin_all --groups=sysadmins
```

### 3.2 Web administrators – `webadmin_http`

Ograničeni skup naredbi vezanih uz web server za grupu `webadmins`:

```bash
ipa sudorule-add webadmin_http --hostcat=all --runasusercat=all --runasgroupcat=all
ipa sudocmdgroup-add webadmin_cmds --desc="Web Commands"
ipa sudocmd-add /usr/bin/systemctl
ipa sudocmd-add /usr/sbin/nginx
ipa sudocmdgroup-add-member webadmin_cmds --sudocmds="/usr/bin/systemctl"
ipa sudocmdgroup-add-member webadmin_cmds --sudocmds="/usr/sbin/nginx"
ipa sudorule-add-allow-command webadmin_http --sudocmdgroups=webadmin_cmds
ipa sudorule-add-user webadmin_http --groups=webadmins
```

### 3.3 IT support – `itsupport_limited`

Dijagnostičke/monitoring naredbe za grupu `itsupport`:

```bash
ipa sudorule-add itsupport_limited --hostcat=all --runasusercat=all --runasgroupcat=all
ipa sudocmdgroup-add itsupport_cmds --desc="IT Support Commands"
ipa sudocmd-add /usr/bin/journalctl
ipa sudocmd-add /usr/sbin/ss
ipa sudocmdgroup-add-member itsupport_cmds --sudocmds="/usr/bin/journalctl"
ipa sudocmdgroup-add-member itsupport_cmds --sudocmds="/usr/sbin/ss"
ipa sudorule-add-allow-command itsupport_limited --sudocmdgroups=itsupport_cmds
ipa sudorule-add-user itsupport_limited --groups=itsupport
```

Provjera definiranih sudo pravila:

`ipa sudorule-find`

## 4. Napomene za klijentske sustave (SSSD cache)

Na klijentskim sustavima sudo pravila se povlače preko SSSD-a i ne primjenjuju se odmah. Za ubrzano testiranje može se osvježiti cache:

**na klijentu, kao root**
```bash
sss_cache -E
rm -rf /var/lib/sss/db/*
systemctl restart sssd
```

opcionalno za brže osvježavanje
```bash
echo "sudo_responder_refresh_interval = 1" >> /etc/sssd/sssd.conf
systemctl restart sssd
```

# 4. 2FA i provjera prijave korisnika u sustav
**Autor:** Anamarija Dominiković

**Uloga:** Član 4 – Inženjer za 2FA i sigurnosnu autentifikaciju

**Tehnologije:** VirtualBox, Rocky Linux 9, FreeIPA, Kerberos, SSSD

Ovaj dio opisuje implementaciju **dvofaktorske autentikacije (2FA)** korištenjem **TOTP tokena** u FreeIPA sustavu te provjeru autentikacije korisnika.
2FA je integrirana u Kerberos autentikacijski mehanizam i **selektivno se primjenjuje po korisnicima**, ovisno o sigurnosnim pravilima.
________________________________________
## 0. Priprema (server)
Administrator se autentificira u Kerberos realm:
```bash
kinit admin
klist
```
(_unesite lozinku za admin korisnika_)

**Očekivani ishod:**
Default principal: admin@IAM.LAB

Potvrđena administrativna autentifikacija

Omogućeno izvođenje FreeIPA administrativnih naredbi
________________________________________
## 1. Provjera korisnika i omogućavanje 2FA (server)
### 1.1 Provjera postojećih postavki korisnika ana
```bash
ipa user-show ana
```
**Svrha:**
Provjerava postojeće postavke autentikacije korisnika (uključujući User authentication types).
________________________________________
### 1.2 Omogućavanje OTP autentikacije za korisnicu ana
```bash
ipa user-mod ana --user-auth-type=otp
```
**Svrha:**
Korisnici se postavlja autentikacijski tip OTP, čime se zahtijeva lozinka + TOTP kod.

**Očekivani ishod:**
U ipa user-show ana prikazuje se:
```bash
User authentication types: otp
```
________________________________________
## 2. Kreiranje TOTP tokena (server)
### 2.1 Primarni TOTP token za ana
```bash
ipa otptoken-add --type=totp --owner=ana --description="TOTP token za korisnika ana"
```

**Svrha:**
Generira se TOTP tajni ključ i QR kod.
**Očekivani ishod:**
URI za TOTP i	ASCII QR kod
QR kod se skenira u Google Authenticator aplikaciji i aplikacija generira 6-znamenkasti kod
________________________________________
### 2.2 Pregled tokena korisnice ana
```bash
ipa otptoken-find --owner=ana
```

**Očekivani ishod:**
```bash
Unique ID: <TOKEN_ID>
```
Unique ID se koristi za administraciju i brisanje tokena.
________________________________________
### 2.3 Backup (recovery) TOTP token za ana
```bash
ipa otptoken-add --type=totp --owner=ana --description="Backup TOTP token za korisnika ana"
```
Naredba služi za oporavak pristupa u slučaju gubitka primarnog uređaja
________________________________________

## 3. Primjena 2FA na dodatne korisnike (server)
### 3.1 Omogućavanje OTP za korisnicu ivana
```bash
ipa user-mod ivana --user-auth-type=otp
```
### 3.2 Kreiranje TOTP tokena za ivana
```bash
ipa otptoken-add --type=totp --owner=ivana --description="TOTP za ivanu"
```
### 3.3 Kreiranje backup tokena za ivana
```
ipa otptoken-add --type=totp --owner=ivana --description="Backup token za korisnika ivana"
```
________________________________________
### 3.4 Omogućavanje OTP za administratoricu marta
```bash
ipa user-mod marta --user-auth-type=otp
```
### 3.5 Kreiranje TOTP tokena za marta
```bash
ipa otptoken-add --type=totp --owner=marta --description="TOTP za martu"
```
### 3.6 Kreiranje backup tokena za marta
```bash
ipa otptoken-add --type=totp --owner=marta --description="Backup TOTP token za martu"
```
2FA je primijenjena selektivno – po korisnicima i ulogama
________________________________________
## 4. Provjera prijave korisnika (klijent)
### 4.1 Prijava korisnice ivana
```bash
su - ivana
```
ili
```
kinit ivana
```
Redoslijed unosa:
1.	Lozinka
2.	TOTP kod
________________________________________
### 4.2 Prijava korisnice marta
```bash
su - marta
```
ili
```bash
kinit marta
```
________________________________________
### 4.3 Provjera Kerberos ticketa
```bash
klist
```
**Očekivani ishod:**
```bash
Default principal: ivana@IAM.LAB
```
ili
```bash
Default principal: marta@IAM.LAB
```
Potvrđena uspješna 2FA autentikacija
________________________________________
## 5. Aktivacija OTP servisa (server)
```bash
sudo systemctl enable --now ipa-otpd.socket
systemctl status ipa-otpd.socket
```
**Očekivani ishod:**

```bash
active (listening)
```
OTP daemon sluša zahtjeve za TOTP autentikaciju
________________________________________
## 6. Recovery postupci (incident response)
### 6.1 Administratorska autentifikacija
```bash
kinit admin
klist
```
________________________________________
### 6.2 Identifikacija tokena kompromitirane korisnice (marta)
```bash
ipa otptoken-find --owner=marta
```
________________________________________
### 6.3 Brisanje TOTP tokena po ID-u
```bash
ipa otptoken-del <TOKEN_ID>
```
Uklanja kompromitirani TOTP token
________________________________________
### 6.4 Otključavanje korisničkog računa
(u slučaju premašivanja broja neuspjelih pokušaja)
```bash
ipa user-unlock marta
```
________________________________________
### 7. Provjera sigurnosnih logova
```bash
journalctl -u krb5kdc | tail -n 50
```
Svrha:
Analiza pokušaja prijave, grešaka i 2FA događaja u Kerberos KDC-u.
________________________________________
### 8. Sažetak
* Implementirana je 2FA autentikacija (TOTP)

* Selektivna primjena po korisnicima - 2FA za administratore i samo lozinka za ostale grupe korisnika

* Backup tokeni za recovery u slučaju zaključavanja korisničkog profila ili kompromitiranja

* Testirana je prijava korisnika

* Definiran recovery plan

* Centralizirani audit kroz Kerberos logove za praćenje prijava korisnika u sustav


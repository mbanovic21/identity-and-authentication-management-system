# Identity & Authentication Management – Teorijski dio

## 1. Uvod u IAM sustave

Identity and Access Management (IAM) predstavlja skup tehnologija i metoda koje omogućuju organizaciji upravljanje identitetima korisnika, njihovim autentifikacijskim podacima i razinama ovlasti. IAM sustav omogućuje:

- centralizirano upravljanje korisničkim računima,
- kontrolu pristupa sistemima, servisima i resursima,
- provedbu sigurnosnih politika (password policy, MFA, PoLP),
- auditiranje pristupa.

U modernim mrežama IAM je ključna komponenta sigurnosti. Bez centraliziranog identitetskog sustava pristup bi bio fragmentiran, teško nadziran i podložan sigurnosnim rizicima.

---

## 2. Temeljni koncepti IAM-a

### 2.1 Autentifikacija & Autorizacija

| Pojam | Objašnjenje |
|-------|------------|
| **Autentifikacija** | Provjera identiteta korisnika (tko si?) |
| **Autorizacija** | Provjera što korisnik smije raditi (što možeš raditi?) |

Autentifikacija može biti:

- **lozinka** (najčešće),
- **certifikat/kerberos ticket**,
- **2FA/MFA** (otp tokeni, aplikacije, smartcard).

Autorizacija se provodi kroz:

- ACL liste,
- grupe,
- role based access control (RBAC),
- sudo policy.

---

### 2.2 Direktori servisi (Directory Services)

Directory Service je centralizirana baza podataka optimizirana za čitanje korisničkih informacija, grupa i autentifikacijskih atributa. Najčešće korišteni protokol:

> **LDAP – Lightweight Directory Access Protocol**

LDAP baze su organizirane hijerarhijski, u obliku stabla:

```

dc=iam,dc=lab
├── cn=users
│    ├── uid=admin
│    └── uid=testuser
└── cn=groups
└── cn=admins

```

LDAP ne autentificira korisnike direktno — umjesto toga **provjerava identitet**, dok autentifikaciju često obavlja Kerberos.

---

## 3. Kerberos – autentifikacijski sustav

Kerberos je mrežni protokol dizajniran za sigurno dokazivanje identiteta u distribiranim sustavima. Temelji se na kriptografiji i rad s **ticketima**, a ne slanjem lozinki preko mreže.

### 3.1 Ključne komponente Kerberosa

| Komponenta | Uloga |
|-----------|-------|
| **KDC** (Key Distribution Center) | Glavna Kerberos usluga |
| **AS** (Authentication Server) | Izdaje inicijalni ticket (TGT) |
| **TGS** (Ticket Granting Service) | Izdaje ticket-e za servise |
| **TGT** | Ticket koji dokazuje identitet korisnika |
| **Service ticket** | Pristup specifičnom servisu |

### 3.2 Kako Kerberos radi (pojednostavljeno)

1. Korisnik izvršava `kinit username`
2. Kerberos traži lozinku → provjerava je lokalno
3. Ako je ispravna → korisnik dobiva TGT
4. Za pristup servisu → TGT se zamjenjuje **service ticketom**

Nakon toga autentifikacija je:

- bez lozinke,
- brza,
- sigurna,
- pogodna za Single Sign-On (SSO).

Kerberos **mora imati točno vrijeme**  
→ zato smo instalirali i uključili **chrony**.

---

## 4. FreeIPA – centralni IAM sustav

FreeIPA = **Identity, Policy & Audit**

Integrira više servisa u jednu platformu:

| Komponenta | Funkcija |
|-----------|----------|
| LDAP (389-DS) | Pohrana identiteta, objekata i grupa |
| Kerberos KDC | Autentifikacija korisnika |
| DNS server | Rješavanje imena i servis rekordova |
| Dogtag CA | Upravljanje certifikatima |
| SSSD | Client-side authentication service |
| WebUI + CLI | Upravljanje sustavom |

To znači da FreeIPA u jednom sustavu objedinjuje:

✔ autentifikaciju  
✔ autorizaciju  
✔ identitete  
✔ password policy  
✔ certifikate  
✔ DNS zone  

---

### 4.1 Zašto FreeIPA?

Prednosti:

- open-source, enterprise-grade,
- jednostavno dodavanje korisnika i grupa,
- sustav politika lozinki,
- mogućnost integracije s Active Directory,
- odličan za razvojni, nastavni i produkcijski kontekst.

Nedostaci:

- primarno orijentiran na Linux okruženje,
- Windows klijenti zahtijevaju dodatnu konfiguraciju.

---

## 5. DNS u FreeIPA sustavu

FreeIPA koristi DNS za:

- hostname → IP rezoluciju,
- Kerberos realm mapping,
- SRV zapise (`_kerberos._tcp`, `_ldap._tcp`),
- prepoznavanje domena između servera i klijenata.

Zato je **/etc/hosts i DNS namještanje kritičan dio instalacije**.

Primjer zapisa:

```

192.168.56.10   ipa1.iam.lab   ipa1

```

Ako DNS nije ispravno postavljen → Kerberos ne radi.

---

## 6. Password Policy (sigurnosne politike lozinki)

Password politika definira:

- složenost lozinke,
- duljinu,
- povijest,
- broj pokušaja,
- vrijeme zaključavanja,
- expire period.

U projektu je implementirana policy:

| Pravilo | Vrijednost |
|--------|------------|
| Min length | 12 |
| Character classes | 3 |
| History | 5 |
| Max failures | 5 |
| Lockout | 15 min |
| Fail interval | 5 min |

Ovo drastično povećava sigurnost te sprječava brute-force napade.

---

## 7. Princip najmanje privilegije

Princip najmanje privilegije (PoLP – Principle of Least Privilege) jedan je od temeljnih sigurnosnih koncepata u administraciji sustava i upravljanju pristupom. Ideja je da svaki korisnik, proces ili servis dobije samo onaj minimalni skup dopuštenja koji mu je nužan za obavljanje zadataka – ni više, ni manje. Time se smanjuje površina napada, posljedice pogrešaka i rizik zloupotrebe ovlasti.

U praksi to znači da se izbjegava rad kao root ili s punim administratorskim pravima kad god to nije apsolutno potrebno. Umjesto toga, korisnici se raspoređuju u uloge i grupe (npr. sysadmin, developer, web administrator, IT podrška), a svaka uloga dobiva ograničen, jasno definiran skup privilegija. Ako se kompromitira račun s ograničenim pravima, napadač može napraviti znatno manje štete nego da odmah preuzme puni root pristup.

U Linux okruženju tipičan alat za provedbu PoLP-a je sudo, kojim se precizno kontrolira koje naredbe određeni korisnici ili grupe smiju pokretati s povišenim privilegijama. Centralizirani IAM sustavi poput FreeIPA dodatno omogućuju da se ta pravila definiraju i primjenjuju centralno nad više poslužitelja, umjesto ručnog uređivanja lokalnih sudoers datoteka na svakom hostu.

---

## 8. Uloga FreeIPA u projektu

U okviru ovog projekta FreeIPA djeluje kao **jezgra sustava**.  

Moja odgovornost kao **Član 1 – Infrastruktura & Server Core** bila je:

1. Priprema virtualnog okoliša  
2. Instalacija OS-a i konfiguracija mreže  
3. Postavljanje FreeIPA servera  
4. Verifikacija LDAP i Kerberos funkcionalnosti  
5. Implementacija password policy-ja  
6. Izrada dokumentacije  

FreeIPA sada omogućuje:

- da ostatak tima spaja klijente,
- kreira korisnike, grupe i role,
- primjenjuje sudo pravila i PoLP,
- implementira 2FA, certifikate i auditing.

---

## 9. Zaključak

Teorijska podloga koja čini ovaj projekt usko je vezana uz IAM sustave i njihove temeljne tehnologije.  
LDAP osigurava skladištenje i organizaciju identiteta, Kerberos osigurava siguran model autentifikacije, a FreeIPA spaja ova dva mehanizma u jedinstvenu platformu s dodatnim funkcijama poput DNS-a, certifikata i politika lozinki.

Ovaj teorijski okvir predstavlja osnovu za implementaciju koja je realizirana u projektu o čemu govori `report.md`, dok tehnička izvedba korak-po-korak stoji u `implementation/setup.md`.

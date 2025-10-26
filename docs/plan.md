# Implementation plan

---

## 📘 1. Pregled projekta

Cilj projekta je osmisliti i implementirati **sustav za upravljanje identitetima i autentifikacijom (IAM – Identity and Authentication Management)** koristeći **open-source tehnologije**.
Sustav omogućava sigurno upravljanje korisnicima, grupama, lozinkama te višefaktorsku autentifikaciju (2FA).
Kroz projekt se povezuje teorijsko znanje o sigurnosnim mehanizmima s praktičnom implementacijom u stvarnom okruženju.

Projekt se provodi u sklopu kolegija **Sigurnost informacijskih sustava**, a cilj je razumjeti i prikazati principe sigurnog pristupa i kontrole identiteta u informatičkim sustavima.

---

## 🎯 2. Glavni ciljevi

1. Razviti razumijevanje načela upravljanja identitetima i autentifikacijom.
2. Osmisliti arhitekturu praktičnog IAM sustava.
3. Implementirati sustav koristeći open-source alate (OpenLDAP, FreeIPA, SSSD).
4. Osigurati dvofaktorsku autentifikaciju i politiku lozinki.
5. Testirati otpornost sustava na tipične sigurnosne napade (npr. brute-force).
6. Evaluirati učinkovitost i sigurnost rješenja.

---

## ⚙️ 3. Struktura projekta

Projekt se sastoji od **teorijskog** i **praktičnog** dijela.

### 🔹 Teorijski dio

* Analiza principa IAM sustava.
* Pregled standarda i sigurnosnih protokola (LDAP, Kerberos, SAML, OAuth2).
* Istraživanje najboljih praksi u zaštiti identiteta i kontrole pristupa.
* Definiranje zahtjeva za sigurnost, autentifikaciju i administraciju korisnika.

### 🔹 Praktični dio

* Implementacija prototipa IAM sustava koristeći:

  * **OpenLDAP** – za upravljanje korisnicima i grupama.
  * **FreeIPA** – za centralizirano upravljanje identitetima i autentifikacijom.
  * **SSSD (System Security Services Daemon)** – za autentifikaciju korisnika na razini operacijskog sustava.
  * **FreeOTP / Google Authenticator** – za dvofaktorsku autentifikaciju (2FA).
* Testiranje sigurnosti sustava i performansi.

---

## 🧭 4. Plan rada po fazama

| Faza                                     | Opis                                                                     | Alati / tehnologije                        | Očekivani rezultat                               |
| ---------------------------------------- | ------------------------------------------------------------------------ | ------------------------------------------ | ------------------------------------------------ |
| **1. Istraživanje i analiza**            | Proučiti IAM koncepte, protokole (LDAP, Kerberos) i open-source alate.   | Online dokumentacija, OWASP, RFC standardi | Definiran teorijski okvir i arhitektura sustava. |
| **2. Dizajn sustava**                    | Izrada arhitekture i definiranje odnosa korisnika, grupa i servisa.      | Draw.io, Lucidchart                        | Dijagram sustava i plan implementacije.          |
| **3. Implementacija**                    | Instalacija i konfiguracija OpenLDAP-a, FreeIPA-e i SSSD-a.              | Linux (Ubuntu/CentOS), CLI                 | Funkcionalan IAM sustav.                         |
| **4. Konfiguracija sigurnosnih pravila** | Postavljanje password policy-a, 2FA autentifikacije i korisničkih prava. | FreeIPA, FreeOTP                           | Uspješno implementirana sigurnosna pravila.      |
| **5. Testiranje**                        | Testiranje autentifikacije, provjera 2FA, pokušaji brute-force napada.   | Hydra, custom skripte                      | Analiza otpornosti sustava.                      |
| **6. Evaluacija**                        | Procjena stabilnosti i sigurnosti sustava, izrada zaključaka.            | Dokumentacija                              | Završni izvještaj s prijedlozima poboljšanja.    |

---

## 🧠 5. Obrazloženje izbora tehnologija

| Tehnologija                        | Uloga u projektu                                                        | Zašto je odabrana                                                                                         |
| ---------------------------------- | ----------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| **OpenLDAP**                       | Osnova sustava za direktorij i pohranu korisničkih podataka.            | Lagan, stabilan i besplatan alat koji se koristi u profesionalnim okruženjima za LDAP autentifikaciju.    |
| **FreeIPA**                        | Centralizirano rješenje za upravljanje identitetima i autentifikacijom. | Integrira LDAP, Kerberos i certifikate u jedno rješenje. Omogućava jednostavno dodavanje 2FA i policy-ja. |
| **SSSD**                           | Omogućava autentifikaciju Linux korisnika prema centralnom direktoriju. | Potrebna komponenta za integraciju sustava s OS-om i servisima.                                           |
| **FreeOTP / Google Authenticator** | Implementacija dvofaktorske autentifikacije.                            | Jednostavni, open-source i sigurni alati za 2FA.                                                          |
| **Linux (Ubuntu / Fedora)**        | Operativni sustav za implementaciju i testiranje.                       | Otvorena platforma s podrškom za sve potrebne alate i servise.                                            |
| **Hydra / testne skripte**         | Testiranje otpornosti na brute-force napade.                            | Omogućuju realno testiranje sigurnosnih mehanizama.                                                       |

---

## 🔒 6. Očekivani rezultati

* Funkcionalan IAM sustav koji omogućava sigurno upravljanje korisnicima i autentifikacijom.
* Uvedena dvofaktorska autentifikacija i politika lozinki.
* Dokumentirana arhitektura i koraci implementacije.
* Rezultati testiranja sigurnosti i analiza ranjivosti.
* Prijedlozi za unaprjeđenje i mogućnosti daljnjeg razvoja (npr. integracija s Active Directoryjem ili cloud servisima).

---

## 🚀 7. Zaključak

Projekt omogućuje razumijevanje i praktičnu primjenu koncepata iz područja **sigurnosti informacijskih sustava**.
Korištenjem otvorenih tehnologija studenti mogu naučiti kako se gradi i štiti infrastruktura za upravljanje identitetima, što je ključno u svakoj modernoj organizaciji.

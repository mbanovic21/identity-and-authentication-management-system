# Evaluacija PoLP implementacije

U ovom dijelu sažeti su rezultati testiranja konfiguracije korisnika, grupa i sudo pravila u FreeIPA sustavu.

## Rezultat: usklađenost s PoLP-om

Na temelju ručnih testova iz `implementation/tests/manual-tests.md`:

- **System Administrators (`sysadmins`)**  
  Članovi (npr. `ivana`) imaju puni sudo pristup prema pravilu `sysadmin_all`. To je namjerno jer ova uloga zahtijeva puni root za administraciju sustava.

- **Developers (`developers`)**  
  Članovi (npr. `pero`) nemaju nikakav sudo pristup. Time se PoLP poštuje jer razvojni korisnici ne trebaju administrativne privilegije na produkcijskim ili serverskim sustavima.

- **Web Server Administrators (`webadmins`)**  
  Članovi (npr. `ana`) mogu koristiti sudo samo za web server naredbe (`systemctl` za web servis, `nginx`) kroz pravilo `webadmin_http`. Ostale sudo naredbe (npr. `journalctl`, `whoami`) su ispravno odbijene.

- **IT Support (`itsupport`)**  
  Članovi (npr. `david`) mogu koristiti sudo samo za dijagnostičke naredbe (`journalctl`, `ss`) preko pravila `itsupport_limited`. Pokušaji pristupa osjetljivim datotekama (npr. `/etc/shadow`) su odbijeni.

## Uočeni problemi i rješenja

Tijekom implementacije i testiranja pojavilo se par problema:

- **Sudo pravila nisu odmah primjenjena na klijentu**  
  Razlog je SSSD cache i odgođeno osvježavanje sudo pravila. Problem je riješen ručnim osvježavanjem cachea na klijentskom sustavu (`sss_cache -E`, brisanje `db` direktorija i restart `sssd` servisa) te, po potrebi, podešavanjem brzine osvježavanja.
- **Pravila nisu vrijedila na svim hostovima**  
  Kada `hostcat` nije bio ispravno postavljen, pravila se nisu primjenjivala. Korištenje `--hostcat=all` osiguralo je da se pravila vežu na očekivane klijente.

## Zaključak

Konfiguracijom korisnika, grupa i sudo pravila postignuta je granularna kontrola pristupa u skladu s principom najmanje privilegije:

- Svaka uloga ima točno onoliko privilegija koliko joj je potrebno.  
- Neautorizirani ili preširoki pristup je spriječen kroz precizno definirana sudo pravila.  
- Testovi pokazuju da se ponašanje sustava podudara s dizajnom opisanom u `docs/plan.md`.

Ovi rezultati mogu poslužiti kao osnova za daljnje proširenje pravila (npr. dodavanje dodatnih uloga ili razdvajanje okruženja na više hostgroup-a).

## 🔥 Instalacija i pokretanje FreeIPA servera

### 1. Na **server VM** (Rocky Linux 9)

```bash
cd implementation/src
chmod +x freeipa-install.sh
sudo ./freeipa-install.sh
```

Nakon instalacije:

```bash
kinit admin
klist
ipa user-find
```

Ako vidiš ticket u `klist` → Kerberos radi 👍

---

## 🔗 Spajanje klijenta na FreeIPA

### 2. Na **client VM**:

```bash
cd implementation/src
chmod +x ipa-client-setup.sh
sudo ./ipa-client-setup.sh
```

Test pristupa:

```bash
id admin
id testuser
su - testuser      # ako je kreiran na serveru
```

---

## 🧪 Testiranje sustava

```bash
cd implementation/tests
./kerberos-test.sh
./ipa-user-test.sh
```

Rezultate upisati u → `implementation/tests/test-results.md`.
Screenshotove staviti u → `results/screenshots/`.
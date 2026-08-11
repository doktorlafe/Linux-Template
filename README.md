# Infrastruktura-Template

> Šablona pro AL projekty v Microsoft Dynamics 365 Business Central

## 📋 O projektu

**Infrastruktura-Template** je výchozí šablona (template) určená pro rychlé zahájení vývoje AL rozšíření pro **Microsoft Dynamics 365 Business Central**. Cílem je zajistit konzistentní strukturu napříč projekty a ušetřit čas při zakládání nových repozitářů.

## 🗂️ Struktura projektu

Typická AL projektová struktura zahrnuje následující složky a soubory:

```
Infrastruktura-Template/
├── .vscode/              # Konfigurace VS Code (launch.json, settings.json) — ignorováno Gitem
├── .alcache/             # Cache AL kompilátoru — ignorováno Gitem
├── .alpackages/          # Stažené symboly závislostí — ignorováno Gitem
├── .snapshots/           # Snapshoty pro testování UI — ignorováno Gitem
├── .output/              # Výstupní soubory testů — ignorováno Gitem
├── .gitignore            # Pravidla pro ignorovánís souborů
├── LICENSE               # GNU GPL v3 licence
├── README.md             # Tento soubor
└── app.json              # Manifest AL rozšíření (přidat dle potřeby)
```

> Složky ignorované Gitem jsou součástí standardního AL workflow, ale nepatří do verzování.

## 🚀 Jak začít

1. **Použij tuto šablonu** jako základ nového repozitáře (tlačítko *Use this template* na GitHubu).
2. **Otevři projekt** ve VS Code s nainstalovaným rozšířením [AL Language](https://marketplace.visualstudio.com/items?itemName=ms-dynamics-smb.al).
3. **Nakonfiguruj `app.json`** — nastav `id`, `name`, `publisher`, `version` a závislosti.
4. **Nakonfiguruj `.vscode/launch.json`** — připoj k Business Central prostředí (OnPrem nebo SaaS).
5. **Stáhni symboly** příkazem `AL: Download Symbols` (Ctrl+Shift+P).
6. **Začni vyvíjet** — přidej objekty (tabulky, stránky, codeunits…) do struktury projektu.

## ⚙️ Požadavky

| Nástroj | Verze |
|---|---|
| VS Code | nejnovější stabilní |
| AL Language extension | nejnovější |
| Business Central | dle cílové verze projektu |
| .NET SDK | dle potřeby AL kompilátoru |

## 📄 Konvence pojmenování

Doporučené konvence pro AL objekty:

- **Prefix/Suffix**: vždy používat registrovaný prefix/suffix objektů (dle partnera/zákazníka)
- **Tabulky**: `Tab<ID> <Název>.al`
- **Stránky**: `Pag<ID> <Název>.al`
- **Codeunity**: `Cod<ID> <Název>.al`
- **Reporty**: `Rep<ID> <Název>.al`
- **Enumy**: `Enu<ID> <Název>.al`

## 🧪 Testování

- Testovací codeunity ukládej do složky `Tests/`
- Výsledky testů jsou generovány do `TestResults.xml` (ignorováno Gitem)
- Používej AL Test Runner rozšíření pro spouštění testů přímo z VS Code

## 📦 Ignorované soubory (.gitignore)

| Soubor / Složka | Důvod ignorování |
|---|---|
| `.vscode/` | Lokální konfigurace editoru |
| `.alcache/` | Cache kompilátoru, generováno automaticky |
| `.alpackages/` | Stažené symboly závislostí |
| `.snapshots/` | Snapshoty UI testů |
| `.output/` | Výstupy testování |
| `*.app` | Zkompilovaný balíček rozšíření |
| `rad.json` | RAD soubor (Rapid Application Development) |
| `*.g.xlf` | Základní překladový soubor (generovaný) |
| `*.bclicense` / `*.flf` | Licenční soubory |
| `TestResults.xml` | Výsledky testů |

## 📜 Licence

Tento projekt je licencován pod **GNU General Public License v3.0** — viz soubor [LICENSE](./LICENSE) pro podrobnosti.

---

*Šablona udržována jako součást infrastruktury AL vývoje.*

# Vorschläge für konkrete Aufgaben

## 1) Tippfehler korrigieren
**Titel:** Dungeon-Beschreibung in Zul'Farrak korrigieren (`Divino-matic` → `Divino-Matic Rod`)

**Problem:** In der Zul'Farrak-Beschreibung wird der Quest-Name verkürzt bzw. uneinheitlich geschrieben. Das wirkt wie ein Tippfehler und erschwert die Suche nach dem korrekten Questbezug.

**Betroffene Stelle:** `EOA_Data_Dungeons.lua` (Zul'Farrak-Abschnitt).

**Vorschlag zur Umsetzung:**
- Textstelle auf den etablierten Namen `Divino-Matic Rod` anpassen.
- Optional: identische Schreibweise in allen Daten-Dateien per Suche sicherstellen.

**Akzeptanzkriterien:**
- Der Begriff `Divino-matic` kommt im Repository nicht mehr vor.
- In der Zul'Farrak-Beschreibung steht `Divino-Matic Rod`.

## 2) Programmierfehler korrigieren
**Titel:** Progressions-Check für Dungeons/Raids berücksichtigt `levelMin` nicht

**Problem:** Die Funktion `EntryMeetsProgressionRequirement` verwendet für Nicht-Sammelrouten nur `levelRecommended`. Dungeon- und Raid-Einträge besitzen jedoch überwiegend `levelMin/levelMax`. Dadurch werden Dungeons/Raids aktuell fast immer als „nicht gesperrt“ dargestellt.

**Betroffene Stellen:**
- `EdgeOfAzeroth.lua`: `EntryMeetsProgressionRequirement`.
- `EOA_Data_Dungeons.lua` / `EOA_Data_Raids.lua`: Nutzung von `levelMin`.

**Vorschlag zur Umsetzung:**
- In `EntryMeetsProgressionRequirement` fallback-Logik ergänzen:
  - `required = entry.levelRecommended or entry.levelMin or 0`
- Bestehende Logik für `HERBS`/`MINING` unverändert lassen.

**Akzeptanzkriterien:**
- Einträge mit `levelMin` werden für unterlevelte Charaktere als „Locked“ markiert.
- Einträge ohne Level-Anforderung verhalten sich wie bisher.

## 3) Dokumentations-Unstimmigkeit korrigieren
**Titel:** Addon-Notiz in der TOC mit tatsächlichem Funktionsumfang synchronisieren

**Problem:** Die TOC-Notiz nennt „Scenic Spots, Dungeon Entrances, and Farming“, obwohl zusätzlich Raid-Daten im Addon enthalten sind. Dadurch ist die Kurzbeschreibung veraltet.

**Betroffene Stellen:**
- `EdgeOfAzeroth.toc`: `## Notes`.
- `EdgeOfAzeroth.lua`: `MODE_OPTIONS` enthält `RAID`.

**Vorschlag zur Umsetzung:**
- `## Notes` um Raids (und optional weitere aktive Modi) ergänzen.

**Akzeptanzkriterien:**
- TOC-Notes nennen mindestens Scenic, Dungeons, Raids und Farming.
- Beschreibung stimmt mit den sichtbaren Hauptmodi überein.

## 4) Test-Qualität verbessern
**Titel:** Automatisierte Regressionstests für Filter-/Sortier- und Progressionslogik einführen

**Problem:** Für zentrale Entscheidungslogik (Filter, Sortierung, Lock-Status) gibt es keine automatisierten Tests. Regressionen in `RefreshFilteredEntries` und `EntryMeetsProgressionRequirement` sind daher schwer erkennbar.

**Vorschlag zur Umsetzung:**
- Lua-Testsetup ergänzen (z. B. mit `busted` oder minimalem lokalen Test-Runner).
- Mindestens folgende Testfälle abdecken:
  - Modusfilter (`ALL`, `DUNGEON`, `RAID`, `FARM`, `FAVORITES`)
  - Farm-Kategorie-Sortierung (`XP/CLOTH`, `HERBS/MINING`, `REPUTATION/TREASURE`)
  - Progressionslogik mit `skillRequired`, `levelRecommended`, `levelMin`-Fallback

**Akzeptanzkriterien:**
- Tests lassen sich lokal mit einem dokumentierten Kommando ausführen.
- Mindestens ein Test schlägt auf dem alten Stand fehl und auf dem gefixten Stand erfolgreich durch.

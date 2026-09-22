---
title: Panoptikum — Projektfortschritt
type: slide
slideOptions:
  transition: slide
---

# Panoptikum
## Projektfortschritt

Neuigkeiten für Nutzer, Podcaster und Moderatoren

---

# Neuigkeiten für Nutzer
## Design, Geschwindigkeit & Entdecken

- Komplette **optische Überarbeitung**: moderne Phoenix-LiveView-Komponenten, neuer Tailwind/DaisyUI-Look — übersichtlichere Seiten, besserer Kontrast, besser lesbare Buttons und Formulare
- Spürbar **schnellere Ladezeiten** (der zugrunde liegende Webserver wurde gewechselt, ~20 % schneller)
- Neu: Podcasts durchstöbern, organisiert in kuratierten **[Communities](/communities)**
- Die Suche kann jetzt **nach Sprache gefiltert** werden, mit einer gruppierten Sprachauswahl und einer gespeicherten Präferenz

---

# Neuigkeiten für Nutzer
## Neue Funktionen

- Empfehlungen/Kommentare funktionieren jetzt auch für **einzelne Kapitel**, nicht nur für ganze Episoden oder Podcasts
- Personen-Profile unterstützen jetzt **Markdown-Beschreibungen** und einen **„rel=me"-Link** (praktisch zur Verifizierung von Mastodon-/Fediverse-Konten)
- Der kostenpflichtige „Pro"-Tarif wurde **eingestellt** — Panoptikum ist jetzt komplett kostenlos nutzbar
- Links zu den **Podcaster- und Hörer-Handbüchern** sowie zur **API-Dokumentation** wurden in die Fußzeile aufgenommen

---

# Neuigkeiten für Nutzer
## Aktuell: Installierbare App & Konto-Funktionen

- Panoptikum kann jetzt **als App installiert** werden, auf dem Smartphone oder Desktop; bereits besuchte Seiten funktionieren auch **offline**, und das Cover der gerade abgespielten Episode erscheint in der Medien-Steuerung des Geräts
- Neue Option **„Angemeldet bleiben für 30 Tage"** beim Login
- Der Login mit Passwort erfordert jetzt eine **verifizierte E-Mail-Adresse**; eine neue Seite ermöglicht das erneute Versenden der Verifizierungsmail
- Lange inaktive oder unverifizierte Konten erhalten jetzt eine **Warnmail mit einem Einmal-Login-Link**, bevor sie gelöscht werden

---

# Neuigkeiten für Podcaster
## Feed-Verarbeitung

- Podcast-Metadaten (Titel, Beschreibung, Artwork, Kategorien, Mitwirkende usw.) werden jetzt etwa einmal im Monat **automatisch aktualisiert**
- **`<podcast:person>`**-Mitwirkende werden jetzt korrekt importiert; veraltete Rollen werden bei jedem erneuten Einlesen automatisch bereinigt
- Das Podcast-**Artwork wird zusammen** mit den übrigen Feed-Daten aktualisiert

---

# Neuigkeiten für Podcaster
## Aktuell: Neue Werkzeuge

- Neuer Button **„Check my feed"** führt Panoptikums Feed-Compliance-Prüfung direkt auf der Podcast-Seite aus
- Neu: **Eigentümerschaft beanspruchen** für den eigenen Podcast über `/my_podcasts`; Admins können die Zuordnung vergeben, ändern oder entfernen
- Der kostenpflichtige „Pro"-Tarif wurde **eingestellt** — jeder Podcast wird jetzt gleich behandelt, kostenlos

---

# Neuigkeiten für Moderatoren
## Moderations-Werkzeuge

- Neue **Communities**-Funktion: Moderatoren können Podcasts direkt in den Feed ihrer Community aufnehmen und deren Kategorien selbst kuratieren
- Neues **Audit-Log (Journal)** protokolliert Moderations-/Admin-Aktionen, mit einem Button zum Leeren
- Neue Admin-Aktion, um außer Kontrolle geratene **Update-Intervalle zurückzusetzen** auf maximal eine Woche
- Das **Moderations-Grid wurde neu aufgebaut** auf dem neuen Komponentensystem, mit einer Spalte für die nächste Metadaten-Aktualisierung

---

# Neuigkeiten für Moderatoren
## Aktuell: Verwaltung für Aufbewahrung & Eigentümerschaft

- Admin-/Moderations-Grids unterstützen jetzt **Alles auswählen und das Löschen mehrerer Zeilen** auf einmal
- Neue Admin-Seite (**`/admin/users/retention`**): Filter, Suche, Massen-Markieren/Entmarkieren und Löschen sowie der Versand von Löschungs-Hinweismails
- Neue Admin-Seite (**`/admin/podcasts/owners`**), um die Eigentümerschaft von Podcasts zuzuweisen, neu zuzuweisen oder zu entfernen

---

# Danke

Fragen?

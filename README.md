# Trendschaetzung_DAS-Monitorg
Arbeit im Rahmen des Statistischen Praktikums an der LMU Muenchen
<br />
<br />
<br />

## 2021-12-17
### Sven
- Spline Schätzung
### Tim
- preprocessing \{rightarrow} Anzahl Beobachtungen
- preprocessing \{rightarrow} logarithmieren
- preprocessing \{rightarrow} Outlier(-detection)
### Chinjang
- lineare und quadratische regression
- plot der Zeitreihen


## 2021-12-07 
### Aufgaben
Idr. alles als generische Funktion die auf eine named list mit xts Objekten angewendet wird
<br />
#### Sven
- Bayesian Splines
- Trendschätzung
<br />
#### Tina
- data preprocessing \righarrow alle xts Zeitreihen in eine named list (Bsp im Skript)
<br />
#### Xinyang
- xts Liste von Tina splitten in Zähldaten-Liste und Liste mit metrischen Daten
- Nachforschung in wie weit wir Zähldaten anderst behandeln
### Tim
- Funktion die eine named List mit Zeitreihen und Kenngrößen (named list) engegennimmt und eine Tabelle für Markdown erstellt.
Bsp: list("BAU_I-5" = list(
                          "SurmUndHagel" = list(
                                      "KendallsTau" = 0.3,
                                      "ManKendall pValue" = 0.2
                          ),
                          ...
                          )
           )
    liefert 
    
    Name   |KendallsTau|ManKendall pValue
    -------|-----------|------------------
    Bau_I-5|        0.3|              0.2
    .....
    
## ToDo:
- [x] Protokoll erstellen
- [ ] R-Skript zum Einlesen der Daten (01_data_preprocessing)
- [ ] R-Skript Data preprocessing (01_data_preprocessing)
- [ ] R-Skript Statistische Analyse (02_trend_analysis)

## Ideas:
- Daten als xts object
- Meta daten sheet fuer Zuordnung Mess-/Zähldaten das in 01 script benutzt wird?
- dependencies fuer packages ? 



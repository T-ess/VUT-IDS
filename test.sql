DROP TABLE Don CASCADE CONSTRAINTS ;
DROP TABLE Familie CASCADE CONSTRAINTS ;
DROP TABLE Setkani_Donu CASCADE CONSTRAINTS ;
DROP TABLE Radovy_clen CASCADE CONSTRAINTS ;
DROP TABLE Aliance CASCADE CONSTRAINTS ;
DROP TABLE Kriminalni_cinnost CASCADE CONSTRAINTS ;
DROP TABLE Uzemi CASCADE CONSTRAINTS ;
DROP TABLE Objednavka CASCADE CONSTRAINTS ;
DROP TABLE R_Ucast_Na_Setkani CASCADE CONSTRAINTS;
DROP TABLE R_Clen_Cinnost CASCADE CONSTRAINTS;
--TODO: u FK omezeni je lepe explicitne deklarovat ON DELETE na NO ACTION nebo SET DEFAULT, aby nedoslo ke smazani produktu pri mazani kategorie
--TODO: unique a default
CREATE TABLE Don (
    Alias varchar(255) PRIMARY KEY,
    Jmeno varchar(255) NOT NULL ,
    Datum_narozeni varchar(255) NOT NULL ,
    Velikost_bot int NOT NULL
);

CREATE TABLE Familie(
  Nazev_familie varchar(255) PRIMARY KEY,
  Pocet_clenu int CHECK(Pocet_clenu>=0),
  Alias varchar(255) NOT NULL,
  CONSTRAINT Vedouci_FK FOREIGN KEY (Alias) REFERENCES Don(Alias)
);

CREATE TABLE Uzemi(
    ID_uzemi int PRIMARY KEY ,
    Ulice varchar(255) NOT NULL ,
    Mesto varchar(255) NOT NULL ,
    PSC number NOT NULL CHECK ( length(to_char(PSC)) = 5 ),
    Rozloha int NOT NULL ,
    GPS varchar(255) CHECK(REGEXP_LIKE(GPS, '^([0-9]|[1-8][0-9]|[9][0]) ([N]|[S]), ([0-9]|[1-9][0-9]|[1][0-7][0-9]|[1][8][0]) ([E]|[W])$')),

    Nazev_familie varchar(255) DEFAULT NULL,
    CONSTRAINT Familie_uzemi_FK FOREIGN KEY (Nazev_familie) REFERENCES Familie(Nazev_familie),
    Spada_od DATE DEFAULT NULL,
    Spada_do DATE DEFAULT NULL
    --TODO: historie - spada pod od-do
);

CREATE TABLE Setkani_Donu(
  ID_setkani int PRIMARY KEY,
  Datum_cas DATE NOT NULL,
  Misto varchar(255),
  ID_uzemi int NOT NULL,
  CONSTRAINT Uzemi_FK FOREIGN KEY (ID_uzemi) REFERENCES Uzemi(ID_uzemi)
);

CREATE TABLE  R_Ucast_Na_Setkani(
    Alias varchar(255) NOT NULL ,
    ID_setkani int NOT NULL ,
    CONSTRAINT Don_FK FOREIGN KEY (Alias) REFERENCES Don(Alias),
    CONSTRAINT Setkani_FK FOREIGN KEY (ID_setkani) REFERENCES Setkani_Donu(ID_setkani)
);

CREATE TABLE Radovy_clen(
    ID_clena int PRIMARY KEY,
    Jmeno varchar(255) NOT NULL,
    Datum_narozeni varchar(255) NOT NULL ,
    Datum_prijeti varchar(255),
    Nazev_familie varchar(255) NOT NULL,

    CONSTRAINT Familie_FK FOREIGN KEY (Nazev_familie) REFERENCES Familie(Nazev_familie),
    Role varchar(255) NOT NULL,
    Role_od DATE NOT NULL,
    Role_do DATE NOT NULL
);

CREATE TABLE Aliance(
  ID_aliance int PRIMARY KEY,
  Stav varchar(255) CHECK (Stav = 'aktivni' or Stav = 'pozastavena' or Stav = 'zrusena') NOT NULL ,
  Datum_zalozeni DATE,
  Datum_ukonceni DATE
    --TODO: vztah aliance a familie
);

CREATE TABLE Kriminalni_cinnost(
    Jmeno_operace varchar(255) PRIMARY KEY ,
    Doba_trvani varchar(255),
    Stav varchar(255) CHECK (Stav = 'vykonana' or Stav = 'pozastavena' or Stav = 'zrusena' or Stav = 'v procesu') NOT NULL ,
    Datum DATE,
    Type varchar(255) NOT NULL CHECK ( Type = 'Vrazda' or Type = 'Ostatni operace' ),
    --Vrazda
    Obet varchar(255), --TODO:nemoze byt Don == CHECK
    Misto varchar(255),
    --Ostatni operace
    Druh varchar(255),

    ID_aliance int,
    Nazev_familie varchar(255),

    CONSTRAINT Vedouci_Aliance_FK FOREIGN KEY (ID_aliance) REFERENCES Aliance(ID_aliance),
    CONSTRAINT Vedouci_Familie_FK FOREIGN KEY (Nazev_familie) REFERENCES Familie(Nazev_familie),

    ID_uzemi int NOT NULL,
    CONSTRAINT Uzemi_Cinnost_FK FOREIGN KEY (ID_uzemi) REFERENCES Uzemi(ID_uzemi),

    CHECK (
        ((ID_aliance is not NULL and Nazev_familie is NULL) or
        (ID_aliance is NULL and Nazev_familie is not NULL)) and
        ((Type = 'Vrazda' and Obet is not NULL and Misto is not NULL and Druh is NULL) or
        (type = 'Ostatni operace' and Druh is not NULL and Obet is NULL and Misto is NULL))
    )
);

CREATE TABLE  R_Clen_Cinnost(
    Jmeno_operace varchar(255) NOT NULL,
    ID_clena int NOT NULL,
    Role varchar(255) NOT NULL,
    CONSTRAINT Clen_FK FOREIGN KEY (ID_clena) REFERENCES Radovy_clen(ID_clena),
    CONSTRAINT Cinnost_FK FOREIGN KEY (Jmeno_operace) REFERENCES Kriminalni_cinnost(Jmeno_operace)
    --TODO: clen musi patrit do familie vedouci cinnost
);

CREATE TABLE Objednavka(
  ID_objednavky int PRIMARY KEY,
  Datum DATE,
  Stav varchar(255) CHECK (Stav = 'vykonana' or Stav = 'pozastavena' or Stav = 'zrusena' or Stav = 'v procesu') NOT NULL,
  Alias varchar(255) NOT NULL,
  Jmeno_operace varchar(255) NOT NULL, --TODO: trigger 'Type' musi byt 'Vrazda'
  CONSTRAINT Vytvoril_FK FOREIGN KEY (Alias) REFERENCES Don(Alias),
  CONSTRAINT Vrazda_FK FOREIGN KEY (Jmeno_operace) REFERENCES Kriminalni_cinnost(Jmeno_operace)
);

-------------------------------------------------------


INSERT INTO Don
VALUES ('Veduci','Jano','2.6.2000', 39);

INSERT INTO Don
VALUES ('Zabijak','Jozo','23.5.1980', 43);

INSERT INTO Familie(Nazev_familie, Pocet_clenu, Alias)
VALUES ('Jedlickovi', 23, 'Veduci');
INSERT INTO Familie(Nazev_familie, Pocet_clenu, Alias)
VALUES ('Kolarovi', 130, 'Zabijak');

INSERT INTO Uzemi(ID_uzemi, Ulice, Mesto, PSC, Rozloha, GPS, Nazev_familie, Spada_od, Spada_do)
VALUES(1,'Sedmikraskova', 'Brno', 95501, 35, '34 N, 180 W', 'Kolarovi', TO_DATE( '2020-03-01', 'YYYY-MM-DD' ), TO_DATE( '2020-05-01', 'YYYY-MM-DD' ));
INSERT INTO Uzemi(ID_uzemi, Ulice, Mesto, PSC, Rozloha, GPS)
VALUES (2, 'Pampeliskova', 'Cesky Krumlov', 45477, 64, '39 N, 120 W');


INSERT INTO Setkani_Donu(ID_setkani, Datum_cas, Misto, ID_uzemi)
VALUES (1, TO_DATE( '2020-03-01 15:15', 'YYYY-MM-DD HH24:MI' ), 'sklep u Joza', 1);

INSERT INTO Radovy_clen(ID_clena, Jmeno, Datum_narozeni, Datum_prijeti, Nazev_familie, Role, Role_od, Role_do)
VALUES(1,'Jozo','12.3.1990', null, 'Jedlickovi', 'zastupce Dona', TO_DATE( '2020-03-01', 'YYYY-MM-DD' ), TO_DATE( '2020-05-01', 'YYYY-MM-DD' ));
INSERT INTO Radovy_clen(ID_clena, Jmeno, Datum_narozeni, Datum_prijeti, Nazev_familie, Role, Role_od, Role_do)
VALUES(2,'Jan','24.11.2000', '4.8.2021', 'Kolarovi', 'cistic bot', TO_DATE( '2020-03-01', 'YYYY-MM-DD' ), TO_DATE( '2020-05-01', 'YYYY-MM-DD' ));

INSERT INTO Aliance(id_aliance, stav, datum_zalozeni, datum_ukonceni)
VALUES (1, 'aktivni', TO_DATE( '2020-03-01 15:15', 'YYYY-MM-DD HH24:MI' ), TO_DATE( '2020-05-01 15:15', 'YYYY-MM-DD HH24:MI' ));

INSERT INTO Kriminalni_cinnost(jmeno_operace, doba_trvani, stav, datum, type, obet, misto, druh, id_aliance, Nazev_familie, id_uzemi)
VALUES('Zabitie Fera', '2 dni', 'vykonana', TO_DATE( '2020-03-01 15:15', 'YYYY-MM-DD HH24:MI' ), 'Vrazda', 'Jozo', 'sklep', NULL, NULL, 'Jedlickovi', 1);
INSERT INTO Kriminalni_cinnost(jmeno_operace, doba_trvani, stav, datum, type, obet, misto, druh, id_aliance, Nazev_familie, id_uzemi)
VALUES('Okradnutie Fera', '1 den', 'vykonana', TO_DATE( '2020-03-01 15:15', 'YYYY-MM-DD HH24:MI' ), 'Ostatni operace', NULL, NULL, 'Kradez', 1, NULL, 1);


INSERT INTO  Objednavka(ID_objednavky, Datum, Stav, Alias, Jmeno_operace)
VALUES(1, TO_DATE( '2020-03-01 15:15', 'YYYY-MM-DD HH24:MI' ), 'vykonana', 'Veduci','Zabitie Fera');

INSERT INTO  R_Ucast_Na_Setkani(Alias, ID_setkani)
VALUES ('Veduci', 1);

INSERT INTO R_Clen_Cinnost(jmeno_operace, id_clena, role)
VALUES ('Okradnutie Fera', 2, 'ridic');
------------------------------------------------------

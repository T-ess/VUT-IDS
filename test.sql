DROP TABLE Don CASCADE CONSTRAINTS ;
DROP TABLE Familie CASCADE CONSTRAINTS ;
DROP TABLE Setkani_Donu CASCADE CONSTRAINTS ;
DROP TABLE Radovy_clen CASCADE CONSTRAINTS ;
DROP  TABLE Aliance CASCADE CONSTRAINTS ;
DROP  TABLE Kriminalni_cinnost CASCADE CONSTRAINTS ;
DROP  TABLE Vrazda CASCADE CONSTRAINTS ;
DROP  TABLE Ostatni_operace CASCADE CONSTRAINTS ;
DROP TABLE Uzemi CASCADE CONSTRAINTS ;
DROP TABLE Objednavka CASCADE CONSTRAINTS ;

CREATE TABLE Don (
    Alias varchar(255) PRIMARY KEY NOT NULL,
    Jmeno varchar(255) NOT NULL ,
    Datum_narozeni varchar(255) NOT NULL ,
    Velikost_bot int NOT NULL
);

CREATE TABLE Familie(
  Nazev varchar(255) PRIMARY KEY  NOT NULL,
  Pocet_clenu int CHECK(Pocet_clenu>=0),
  Alias varchar(255) NOT NULL,
  CONSTRAINT Vedouci_FK FOREIGN KEY (Alias) REFERENCES Don(Alias)
);

CREATE TABLE Setkani_Donu(
  ID_setkani int PRIMARY KEY NOT NULL,
  Datum_cas DATE,
  Misto varchar(255)
);

CREATE TABLE Radovy_clen(
    ID_clena int PRIMARY KEY NOT NULL,
    Jmeno varchar(255) NOT NULL,
    Datum_narozeni varchar(255) NOT NULL ,
    Datum_prijeti varchar(255)
);

CREATE TABLE Aliance(
  ID_aliance int PRIMARY KEY  NOT NULL,
  Stav varchar(255) CHECK (Stav = 'aktivni' or Stav = 'pozastavena' or Stav = 'zrusena') NOT NULL ,
  Datum_zalozeni DATE,
  Datum_ukonceni DATE
);

CREATE TABLE Kriminalni_cinnost(
    Jmeno_operace varchar(255) PRIMARY KEY NOT NULL ,
    Doba_trvani varchar(255),
    Stav varchar(255) CHECK (Stav = 'vykonana' or Stav = 'pozastavena' or Stav = 'zrusena' or Stav = 'v procesu') NOT NULL ,
    Datum DATE --zmenit v ERD
);

--pridat generalizaciu
CREATE TABLE  Vrazda(
    Obet varchar(255) NOT NULL, --nemoze byt Don == CHECK
    Misto varchar(255) NOT NULL
);

CREATE TABLE Ostatni_operace(
    Druh varchar(255) NOT NULL
);

CREATE TABLE Uzemi(
    ID_uzemi int PRIMARY KEY NOT NULL ,
    Adresa varchar(255) NOT NULL ,
    Rozloha int NOT NULL ,
    GPS varchar(255) CHECK(REGEXP_LIKE(GPS, '^([0-9]|[1-8][0-9]|[9][0]) ([N]|[S]), ([0-9]|[1-9][0-9]|[1][0-7][0-9]|[1][8][0]) ([E]|[W])$'))
);

CREATE TABLE Objednavka(
  ID_objednavky int PRIMARY KEY NOT NULL ,
  Datum DATE,
  Stav varchar(255) CHECK (Stav = 'vykonana' or Stav = 'pozastavena' or Stav = 'zrusena' or Stav = 'v procesu') NOT NULL
);

-------------------------------------------------------
INSERT INTO Don
VALUES ('Veduci','Jano','2.6.2000', 39);

INSERT INTO Don
VALUES ('Zabijak','Jozo','23.5.1980', 43);

INSERT INTO Familie(Nazev, Pocet_clenu, Alias)
VALUES ('Jedlickovi', 23, 'Veduci');
INSERT INTO Familie(Nazev, Pocet_clenu, Alias)
VALUES ('Kolarovi', 130, 'Zabijak');

INSERT INTO Setkani_Donu(ID_setkani, Datum_cas, Misto)
VALUES (1, TO_DATE( '2020-03-01 15:15', 'YYYY-MM-DD HH24:MI' ), 'sklep u Joza');

INSERT INTO Radovy_clen(ID_clena, Jmeno, Datum_narozeni, Datum_prijeti)
VALUES(1,'Jozo','12.3.1990', null);
INSERT INTO Radovy_clen(ID_clena, Jmeno, Datum_narozeni, Datum_prijeti)
VALUES(2,'Jan','24.11.2000', '4.8.2021');

INSERT INTO Kriminalni_cinnost(Jmeno_operace, Doba_trvani, Stav, Datum)
VALUES('Zabitie Fera', '2 dni', 'vykonana', TO_DATE( '2020-03-01 15:15', 'YYYY-MM-DD HH24:MI' ));

INSERT INTO Uzemi(ID_uzemi, Adresa, Rozloha, GPS)
VALUES('1','Sedmikraskova 9 Brno', '35', '34 N, 180 W');

------------------------------------------------------

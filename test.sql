-- SQL skript pro vytvoření základních objektů schématu databáze
-- Zadání: Mafie
-- Autor: Natália Marková (xmarko20), Tereza Burianová (xburia28)


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
DROP TABLE R_Spada_Pod CASCADE CONSTRAINTS ;
DROP TABLE R_Clen_Role CASCADE CONSTRAINTS ;
DROP SEQUENCE uzemi_seq;
DROP PROCEDURE vek_pri_prijeti;
DROP PROCEDURE statistika_ucasti_donu_na_setkani;

----------------------------------------------------------------------------------
-- Projekt 2 - vytvoreni tabulek
----------------------------------------------------------------------------------
CREATE TABLE Don (
    Alias varchar(255) PRIMARY KEY,
    Jmeno varchar(255) NOT NULL ,
    Prijmeni varchar(255) NOT NULL ,
    Datum_narozeni DATE NOT NULL ,
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
    PSC number(5) NOT NULL CHECK ( length(to_char(PSC)) = 5 ),
    Rozloha int NOT NULL CHECK ( Rozloha > 0 ),
    GPS varchar(255) CHECK(REGEXP_LIKE(GPS, '^([0-9]|[1-8][0-9]|[9][0]) ([N]|[S]), ([0-9]|[1-9][0-9]|[1][0-7][0-9]|[1][8][0]) ([E]|[W])$'))
);

CREATE TABLE R_Spada_Pod(
    ID_spada int PRIMARY KEY,
    ID_uzemi int NOT NULL,
    Nazev_familie varchar(255) DEFAULT NULL,
    Spada_od DATE DEFAULT NULL,
    Spada_do DATE DEFAULT NULL,
    CONSTRAINT Uzemi_Pod_FK FOREIGN KEY (ID_uzemi) REFERENCES Uzemi(ID_uzemi) ON DELETE CASCADE,
    CONSTRAINT Pod_Familii_FK FOREIGN KEY (Nazev_familie) REFERENCES Familie(Nazev_familie) ON DELETE CASCADE,
    CHECK ( Spada_od <= Spada_do )
    --TODO: trigger - kontrola, zda se data v radcich neprekryvaji
);

CREATE TABLE Setkani_Donu(
    ID_setkani int PRIMARY KEY,
    Datum_cas DATE NOT NULL,
    Misto varchar(255) NOT NULL,
    ID_uzemi int NOT NULL,
    CONSTRAINT Uzemi_FK FOREIGN KEY (ID_uzemi) REFERENCES Uzemi(ID_uzemi)
);

CREATE TABLE  R_Ucast_Na_Setkani(
    Alias varchar(255),
    ID_setkani int,
    PRIMARY KEY (Alias, ID_setkani),
    CONSTRAINT Don_FK FOREIGN KEY (Alias) REFERENCES Don(Alias) ON DELETE CASCADE,
    CONSTRAINT Setkani_FK FOREIGN KEY (ID_setkani) REFERENCES Setkani_Donu(ID_setkani) ON DELETE CASCADE
);

CREATE TABLE Radovy_clen(
    ID_clena int PRIMARY KEY,
    Jmeno varchar(255) NOT NULL,
    Prijmeni varchar(255) NOT NULL,
    Datum_narozeni DATE NOT NULL,
    Datum_prijeti DATE NOT NULL,
    Nazev_familie varchar(255) NOT NULL,
    CONSTRAINT Familie_FK FOREIGN KEY (Nazev_familie) REFERENCES Familie(Nazev_familie) ON DELETE CASCADE
);

CREATE TABLE R_Clen_Role(
    ID_role int PRIMARY KEY,
    ID_clena int NOT NULL,
    Role varchar(255) NOT NULL,
    Role_od DATE NOT NULL,
    Role_do DATE,
    CONSTRAINT Role_Clena_FK FOREIGN KEY (ID_clena) REFERENCES Radovy_clen(ID_clena) ON DELETE CASCADE,
    CHECK ( Role_od <= Role_do )
);

CREATE TABLE Aliance(
    ID_aliance int PRIMARY KEY,
    Stav varchar(255) CHECK (Stav = 'aktivni' or Stav = 'pozastavena' or Stav = 'zrusena') NOT NULL ,
    Datum_zalozeni DATE DEFAULT CURRENT_DATE,
    Datum_ukonceni DATE DEFAULT NULL,
    Familie1 varchar(255) NOT NULL,
    Familie2 varchar(255) NOT NULL,
    CHECK (
        ((Familie1 != Familie2) and
        (Familie1 < Familie2)) and
        (((Stav = 'aktivni' or Stav = 'pozastavena') and Datum_ukonceni is null) or
        (Stav = 'zrusena' and Datum_ukonceni is not null)) and
        (Datum_zalozeni <= Datum_ukonceni)
        ),
    CONSTRAINT Familie1_FK FOREIGN KEY (Familie1) REFERENCES Familie(Nazev_familie) ON DELETE CASCADE,
    CONSTRAINT Familie2_FK FOREIGN KEY (Familie2) REFERENCES Familie(Nazev_familie) ON DELETE CASCADE
);



CREATE TABLE Kriminalni_cinnost(
    Jmeno_operace varchar(255) PRIMARY KEY ,
    Doba_trvani varchar(255) NOT NULL,
    Stav varchar(255) CHECK (Stav = 'vykonana' or Stav = 'pozastavena' or Stav = 'zrusena' or Stav = 'v procesu') NOT NULL ,
    Datum DATE DEFAULT CURRENT_DATE,
    Type varchar(255) NOT NULL CHECK ( Type = 'Vrazda' or Type = 'Ostatni operace' ),
    --Vrazda
    Obet varchar(255), --TODO: trigger - obet nemuze byt Don
    Misto varchar(255),
    --Ostatni operace
    Druh varchar(255),
    ID_aliance int,
    Nazev_familie varchar(255),
    CONSTRAINT Vedouci_Aliance_FK FOREIGN KEY (ID_aliance) REFERENCES Aliance(ID_aliance) ON DELETE CASCADE ,
    CONSTRAINT Vedouci_Familie_FK FOREIGN KEY (Nazev_familie) REFERENCES Familie(Nazev_familie) ON DELETE CASCADE ,
    ID_uzemi int NOT NULL,
    CONSTRAINT Uzemi_Cinnost_FK FOREIGN KEY (ID_uzemi) REFERENCES Uzemi(ID_uzemi) ON DELETE SET NULL,
    CHECK (
        ((ID_aliance is not NULL and Nazev_familie is NULL) or
        (ID_aliance is NULL and Nazev_familie is not NULL)) and
        ((Type = 'Vrazda' and Obet is not NULL and Misto is not NULL and Druh is NULL) or
        (type = 'Ostatni operace' and Druh is not NULL and Obet is NULL and Misto is NULL))
    )
);

CREATE TABLE  R_Clen_Cinnost(
    Jmeno_operace varchar(255),
    ID_clena int,
    PRIMARY KEY (Jmeno_operace, ID_clena),
    Role varchar(255) NOT NULL,
    CONSTRAINT Clen_FK FOREIGN KEY (ID_clena) REFERENCES Radovy_clen(ID_clena) ON DELETE CASCADE ,
    CONSTRAINT Cinnost_FK FOREIGN KEY (Jmeno_operace) REFERENCES Kriminalni_cinnost(Jmeno_operace) ON DELETE CASCADE
    --TODO: trigger - clen musi patrit do familie vedouci cinnost
);

CREATE TABLE Objednavka(
    ID_objednavky int PRIMARY KEY,
    Datum DATE DEFAULT CURRENT_DATE,
    Stav varchar(255) CHECK (Stav = 'odeslana' or Stav = 'prijata' or Stav = 'zrusena') NOT NULL,
    Alias varchar(255) NOT NULL,
    Jmeno_operace varchar(255) NOT NULL, --TODO: trigger - 'Type' musi byt 'Vrazda'
    CONSTRAINT Vytvoril_FK FOREIGN KEY (Alias) REFERENCES Don(Alias) ON DELETE CASCADE ,
    CONSTRAINT Vrazda_FK FOREIGN KEY (Jmeno_operace) REFERENCES Kriminalni_cinnost(Jmeno_operace) ON DELETE CASCADE
);

----------------------------------------------------------------------------------
-- Projekt 4 - vytvoreni triggeru, procedur
----------------------------------------------------------------------------------
CREATE SEQUENCE uzemi_seq
    START WITH 1
    INCREMENT BY 1;
CREATE OR REPLACE TRIGGER uzemi_id
    BEFORE INSERT ON Uzemi
    FOR EACH ROW
    BEGIN
        :NEW.ID_Uzemi := uzemi_seq.nextval;
    END;
/

CREATE OR REPLACE TRIGGER familie_check
    BEFORE INSERT OR UPDATE ON R_Clen_Cinnost
    FOR EACH ROW
    DECLARE
        F_Cinnost VARCHAR2(255);
        F_Clen VARCHAR2(255);
    BEGIN
        IF INSERTING THEN
            SELECT Nazev_familie INTO F_Cinnost FROM Kriminalni_cinnost WHERE Kriminalni_cinnost.Jmeno_operace = :new.Jmeno_operace;
            SELECT Nazev_familie INTO F_Clen FROM Radovy_clen WHERE Radovy_clen.ID_clena = :new.ID_clena;
            IF F_Clen != F_Cinnost
            THEN
                RAISE_APPLICATION_ERROR(-20000, 'Tento radovy clen nepatri do Familie vedouci tuto cinnost.');
            END IF;
        END IF;
    END;
/

CREATE OR REPLACE PROCEDURE vek_pri_prijeti AS
        CURSOR clenove IS SELECT * FROM Radovy_clen;
        Clen Radovy_clen%ROWTYPE;
        rozdil INT;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Vek clenu pri jejich prijeti do Familie:');
        OPEN clenove;
        LOOP
            FETCH clenove INTO Clen;
            EXIT WHEN clenove%NOTFOUND;
            rozdil := EXTRACT(YEAR FROM Clen.Datum_prijeti) - EXTRACT(YEAR FROM Clen.datum_narozeni);
            IF EXTRACT(MONTH FROM Clen.Datum_prijeti) < EXTRACT(MONTH FROM Clen.Datum_narozeni)
            THEN
                rozdil := rozdil - 1;
            ELSIF (EXTRACT(MONTH FROM Clen.Datum_prijeti) = EXTRACT(MONTH FROM Clen.Datum_narozeni)) AND (EXTRACT(DAY FROM Clen.Datum_prijeti) < EXTRACT(DAY FROM Clen.Datum_narozeni))
            THEN
                rozdil := rozdil - 1;
            END IF;
            DBMS_OUTPUT.PUT_LINE('ID ' || Clen.ID_clena || ', ' || Clen.Jmeno || ' ' || Clen.Prijmeni || ' - ' || TO_CHAR(rozdil) || ' let');
        END LOOP;
    EXCEPTION
        WHEN others THEN
         DBMS_OUTPUT.PUT_LINE('Error executing the vek_pri_prijeti procedure.');
    END;
/

CREATE OR REPLACE PROCEDURE statistika_ucasti_donu_na_setkani AS
        CURSOR setkani IS SELECT * FROM Setkani_Donu;
        setkani_ID Setkani_Donu%ROWTYPE;
        celkem_donu NUMBER;
        pocet_ucastniku NUMBER;
        vypocet NUMBER;
    BEGIN
        SELECT COUNT(*) INTO celkem_donu FROM Don;
        DBMS_OUTPUT.PUT_LINE('Percentualni ucast na setkanich Donu:');
        OPEN setkani;
        LOOP
            FETCH setkani INTO setkani_ID;
            EXIT WHEN setkani%NOTFOUND;
            SELECT COUNT(*) INTO pocet_ucastniku FROM R_Ucast_Na_Setkani WHERE ID_setkani = setkani_ID.ID_setkani;
            vypocet := ROUND(pocet_ucastniku/celkem_donu*100, 2);
            DBMS_OUTPUT.PUT_LINE('Setkani ' || setkani_ID.ID_setkani || ': ' || TO_CHAR(vypocet) || ' %');
        END LOOP;
    EXCEPTION
        WHEN others THEN
         DBMS_OUTPUT.PUT_LINE('Error executing the statistika_ucasti_donu_na_setkani procedure.');
    END;
/

----------------------------------------------------------------------------------
-- Projekt 2 - vlozeni vzorovych dat
----------------------------------------------------------------------------------
INSERT INTO Don(Alias, Jmeno, Prijmeni, Datum_narozeni, Velikost_bot)
VALUES ('Veduci', 'Jano', 'Jedlicka', TO_DATE( '1967-11-01', 'YYYY-MM-DD' ), 39);
INSERT INTO Don(Alias, Jmeno, Prijmeni, Datum_narozeni, Velikost_bot)
VALUES ('Zabijak', 'Jozo', 'Ruzicka', TO_DATE( '2000-03-01', 'YYYY-MM-DD' ), 43);
INSERT INTO Don(Alias, Jmeno, Prijmeni, Datum_narozeni, Velikost_bot)
VALUES ('Kvetinka', 'Ludek', 'Kolar', TO_DATE( '1950-04-10', 'YYYY-MM-DD' ), 35);


INSERT INTO Familie(Nazev_familie, Pocet_clenu, Alias)
VALUES ('Jedlickovi', 23, 'Veduci');
INSERT INTO Familie(Nazev_familie, Pocet_clenu, Alias)
VALUES ('Ruzickovi', 130, 'Zabijak');
INSERT INTO Familie(Nazev_familie, Pocet_clenu, Alias)
VALUES ('Kolarovi', 130, 'Kvetinka');

-- Projekt 4 - demonstrace triggeru na doplneni chybejicich ID
INSERT INTO Uzemi(Ulice, Mesto, PSC, Rozloha, GPS)
VALUES('Sedmikraskova', 'Brno', 95501, 35, '34 N, 180 W');
INSERT INTO Uzemi(Ulice, Mesto, PSC, Rozloha, GPS)
VALUES ('Pampeliskova', 'Cesky Krumlov', 45477, 64, '39 N, 120 W');
INSERT INTO Uzemi(Ulice, Mesto, PSC, Rozloha, GPS)
VALUES ('Tulipanova', 'Sered', 25874, 112, '69 N, 69 E');


INSERT INTO R_Spada_Pod(ID_spada, ID_uzemi, Nazev_familie, Spada_od, Spada_do)
VALUES(1, 1, 'Jedlickovi', TO_DATE( '2020-03-01', 'YYYY-MM-DD' ), TO_DATE( '2020-04-05', 'YYYY-MM-DD' ));
INSERT INTO R_Spada_Pod(ID_spada, ID_uzemi, Spada_od, Spada_do)
VALUES(2, 1, TO_DATE( '2020-04-05', 'YYYY-MM-DD' ), TO_DATE( '2020-06-08', 'YYYY-MM-DD' ));
INSERT INTO R_Spada_Pod(ID_spada, ID_uzemi, Nazev_familie, Spada_od, Spada_do)
VALUES(3, 1, 'Kolarovi', TO_DATE( '2020-06-08', 'YYYY-MM-DD' ), TO_DATE( '2020-06-10', 'YYYY-MM-DD' ));
INSERT INTO R_Spada_Pod(ID_spada, ID_uzemi, Spada_od, Spada_do)
VALUES(4, 2, TO_DATE( '2020-06-08', 'YYYY-MM-DD' ), TO_DATE( '2021-01-08', 'YYYY-MM-DD' ) );
INSERT INTO R_Spada_Pod(ID_spada, ID_uzemi, Nazev_familie, Spada_od, Spada_do)
VALUES(5, 2, 'Ruzickovi', TO_DATE( '2021-01-08', 'YYYY-MM-DD' ), TO_DATE( '2021-03-08', 'YYYY-MM-DD' ));
INSERT INTO R_Spada_Pod(ID_spada, ID_uzemi, Nazev_familie, Spada_od, Spada_do)
VALUES(6, 3, 'Jedlickovi', TO_DATE( '2020-12-12', 'YYYY-MM-DD' ), TO_DATE( '2021-01-01', 'YYYY-MM-DD' ));


INSERT INTO Setkani_Donu(ID_setkani, Datum_cas, Misto, ID_uzemi)
VALUES (1, TO_DATE( '2020-03-01 15:15', 'YYYY-MM-DD HH24:MI' ), 'sklep u Joza', 1);
INSERT INTO Setkani_Donu(ID_setkani, Datum_cas, Misto, ID_uzemi)
VALUES (2, TO_DATE( '2020-06-05 10:30', 'YYYY-MM-DD HH24:MI' ), 'domov duchodcu', 2);
INSERT INTO Setkani_Donu(ID_setkani, Datum_cas, Misto, ID_uzemi)
VALUES (3, TO_DATE( '2021-09-17 19:00', 'YYYY-MM-DD HH24:MI' ), 'Salieriho bar', 3);


INSERT INTO Radovy_clen(ID_clena, Jmeno, Prijmeni, Datum_narozeni, Datum_prijeti, Nazev_familie)
VALUES(1, 'Jozo', 'Popleta', TO_DATE( '1990-03-12', 'YYYY-MM-DD' ), TO_DATE( '2018-06-06', 'YYYY-MM-DD' ), 'Kolarovi');
INSERT INTO Radovy_clen(ID_clena, Jmeno, Prijmeni, Datum_narozeni, Datum_prijeti, Nazev_familie)
VALUES(2, 'Jan', 'Spageta', TO_DATE( '2000-11-24', 'YYYY-MM-DD' ), TO_DATE( '2020-07-06', 'YYYY-MM-DD' ), 'Kolarovi');
INSERT INTO Radovy_clen(ID_clena, Jmeno, Prijmeni, Datum_narozeni, Datum_prijeti, Nazev_familie)
VALUES(3, 'Hildegarda', 'Nugeta',TO_DATE( '1986-01-31', 'YYYY-MM-DD' ),TO_DATE( '2021-01-01', 'YYYY-MM-DD' ), 'Ruzickovi');
INSERT INTO Radovy_clen(ID_clena, Jmeno, Prijmeni, Datum_narozeni, Datum_prijeti, Nazev_familie)
VALUES(4, 'Berta', 'Koketa', TO_DATE( '2000-02-15', 'YYYY-MM-DD' ),TO_DATE( '2020-05-19', 'YYYY-MM-DD' ), 'Jedlickovi');


INSERT INTO R_Clen_Role(ID_role, Role, Role_od, Role_do, ID_clena)
VALUES(1, 'cistic zachodu', TO_DATE( '2018-06-06', 'YYYY-MM-DD' ), TO_DATE( '2018-09-17', 'YYYY-MM-DD' ), 1);
INSERT INTO R_Clen_Role(ID_role, Role, Role_od, Role_do, ID_clena)
VALUES(2, 'cistic bot',  TO_DATE( '2018-09-17', 'YYYY-MM-DD' ), TO_DATE( '2019-02-25', 'YYYY-MM-DD' ), 1);
INSERT INTO R_Clen_Role(ID_role, Role, Role_od, Role_do, ID_clena)
VALUES(3, 'cistic aut',  TO_DATE( '2018-12-30', 'YYYY-MM-DD' ), null, 1);
INSERT INTO R_Clen_Role(ID_role, Role, Role_od, Role_do, ID_clena)
VALUES(4, 'vrah',  TO_DATE( '2020-07-06', 'YYYY-MM-DD' ), TO_DATE( '2020-10-11', 'YYYY-MM-DD' ), 2);
INSERT INTO R_Clen_Role(ID_role, Role, Role_od, Role_do, ID_clena)
VALUES(5, 'vrchni vrah', TO_DATE( '2020-10-11', 'YYYY-MM-DD' ), null, 2);
INSERT INTO R_Clen_Role(ID_role, Role, Role_od, Role_do, ID_clena)
VALUES(6, 'ridic', TO_DATE( '2021-01-01', 'YYYY-MM-DD' ), null, 3);
INSERT INTO R_Clen_Role(ID_role, Role, Role_od, Role_do, ID_clena)
VALUES(7, 'zastupce Dona',  TO_DATE( '2020-05-19', 'YYYY-MM-DD' ), null, 4);

INSERT INTO Aliance(id_aliance, stav, datum_zalozeni, familie1, familie2)
VALUES (1, 'aktivni', TO_DATE( '2020-03-01', 'YYYY-MM-DD' ), 'Jedlickovi', 'Kolarovi');
INSERT INTO Aliance(id_aliance, stav, datum_zalozeni, familie1, familie2)
VALUES (2, 'pozastavena', TO_DATE( '2020-12-24', 'YYYY-MM-DD' ), 'Jedlickovi', 'Ruzickovi');
INSERT INTO Aliance(id_aliance, stav, datum_zalozeni, Datum_ukonceni, Familie1, familie2)
VALUES (3, 'zrusena', TO_DATE( '2020-12-25', 'YYYY-MM-DD' ), TO_DATE( '2020-12-30', 'YYYY-MM-DD' ), 'Kolarovi', 'Ruzickovi');

INSERT INTO Kriminalni_cinnost(jmeno_operace, doba_trvani, stav, datum, type, obet, misto, druh, id_aliance, Nazev_familie, id_uzemi)
VALUES('Zabitie Fera', '2 dni', 'vykonana', TO_DATE( '2020-03-01 15:15', 'YYYY-MM-DD HH24:MI' ), 'Vrazda', 'Fero', 'sklep', NULL, NULL, 'Kolarovi' , 1);
INSERT INTO Kriminalni_cinnost(jmeno_operace, doba_trvani, stav, datum, type, obet, misto, druh, id_aliance, Nazev_familie, id_uzemi)
VALUES('Okradnutie Fera', '1 den', 'vykonana', TO_DATE( '2020-03-01 15:15', 'YYYY-MM-DD HH24:MI' ), 'Ostatni operace', NULL, NULL, 'Kradez', 1, NULL, 1);
INSERT INTO Kriminalni_cinnost(jmeno_operace, doba_trvani, stav, datum, type, obet, misto, druh, id_aliance, Nazev_familie, id_uzemi)
VALUES('Operace Jarmila', '5 dni', 'v procesu', TO_DATE( '2020-06-14 23:00', 'YYYY-MM-DD HH24:MI' ), 'Vrazda', 'Jarmila', 'kadernictvi', NULL, NULL, 'Ruzickovi', 3);

INSERT INTO  Objednavka(ID_objednavky, Datum, Stav, Alias, Jmeno_operace)
VALUES(1, TO_DATE( '2020-03-01 15:15', 'YYYY-MM-DD HH24:MI' ), 'prijata', 'Veduci','Zabitie Fera');
INSERT INTO  Objednavka(ID_objednavky, Datum, Stav, Alias, Jmeno_operace)
VALUES(2, TO_DATE( '2020-06-14 23:00', 'YYYY-MM-DD HH24:MI' ), 'prijata', 'Zabijak','Operace Jarmila');

INSERT INTO  R_Ucast_Na_Setkani(Alias, ID_setkani)
VALUES ('Veduci', 1);
INSERT INTO  R_Ucast_Na_Setkani(Alias, ID_setkani)
VALUES ('Kvetinka', 1);
INSERT INTO  R_Ucast_Na_Setkani(Alias, ID_setkani)
VALUES ('Zabijak', 1);
INSERT INTO  R_Ucast_Na_Setkani(Alias, ID_setkani)
VALUES ('Kvetinka', 2);
INSERT INTO  R_Ucast_Na_Setkani(Alias, ID_setkani)
VALUES ('Zabijak', 2);
INSERT INTO  R_Ucast_Na_Setkani(Alias, ID_setkani)
VALUES ('Kvetinka', 3);


INSERT INTO R_Clen_Cinnost(jmeno_operace, id_clena, role)
VALUES ('Zabitie Fera', 2, 'vrah');
INSERT INTO R_Clen_Cinnost(jmeno_operace, id_clena, role)
VALUES ('Okradnutie Fera', 1, 'zameteni stop');
INSERT INTO R_Clen_Cinnost(jmeno_operace, id_clena, role)
VALUES ('Okradnutie Fera', 4, 'vykradeni Ferova domu');
INSERT INTO R_Clen_Cinnost(jmeno_operace, id_clena, role)
VALUES ('Operace Jarmila', 3, 'Novicok do gati');


----------------------------------------------------------------------------------
-- Projekt 3 - vytvoreni selectu
----------------------------------------------------------------------------------

-- Select role Joza Poplety --
-- spojeni dvou tabulek --
SELECT
    R.Role,
    R.Role_od,
    R.Role_do
FROM Radovy_clen C, R_Clen_Role R
WHERE C.Jmeno='Jozo' and C.Prijmeni='Popleta' and R.ID_clena=C.ID_clena;

-- Select vsechny cleny Familie Kolarovi --
-- spojeni dvou tabulek --
SELECT
    R.Jmeno,
    R.Prijmeni
FROM Familie F, Radovy_clen R
WHERE R.Nazev_familie='Kolarovi' and R.Nazev_familie=F.Nazev_familie;

-- Select vsechny vrazdy objednane Veducim --
-- spojeni tri tabulek --
SELECT
    K.Jmeno_operace,
    D.Alias,
    O.ID_objednavky
FROM Kriminalni_cinnost K, Objednavka O, Don D
WHERE K.type='Vrazda' and O.Alias=D.Alias and D.Alias='Veduci' and O.Jmeno_operace=K.Jmeno_operace;


-- Select kolika setkani se jednotlivi Donove zucastnili --
-- GROUP BY a agregacni funkce  COUNT --
SELECT
    D.Alias,
    COUNT(U.ID_setkani) AS Pocet_setkani
FROM R_Ucast_Na_Setkani U, Don D
WHERE U.Alias=D.Alias
GROUP BY D.Alias;

-- Select clenu, kteri se zucastnili jen operace 'Zabitie Fera' --
-- predikat EXISTS --
SELECT C.*
FROM Radovy_clen C, R_Clen_Cinnost R
WHERE R.Jmeno_operace='Zabitie Fera' and C.ID_clena=R.ID_clena and
NOT EXISTS (
    SELECT *
    FROM R_Clen_Cinnost R
    WHERE R.Jmeno_operace<>'Zabitie Fera' and C.ID_clena=R.ID_clena
    );

-- Select setkani donu, ktera se konala na uzemich s rozlohou mensi nez 100 --
-- predikat IN s vnorenym selectem --
SELECT *
FROM Setkani_Donu
WHERE ID_uzemi IN (
        SELECT ID_uzemi
        FROM Uzemi
        WHERE Rozloha<100
    );
----------------------------------------------------------------------------------
-- Projekt 4 - prava pro druheho clena tymu
----------------------------------------------------------------------------------
GRANT ALL ON Don TO XMARKO20;
GRANT ALL ON Familie TO XMARKO20;
GRANT ALL ON Uzemi TO XMARKO20;
GRANT ALL ON R_Spada_Pod TO XMARKO20;
GRANT ALL ON Setkani_Donu TO XMARKO20;
GRANT ALL ON R_Ucast_Na_Setkani TO XMARKO20;
GRANT ALL ON Radovy_clen TO XMARKO20;
GRANT ALL ON R_Clen_Role TO XMARKO20;
GRANT ALL ON Aliance TO XMARKO20;
GRANT ALL ON Kriminalni_cinnost TO XMARKO20;
GRANT ALL ON R_Clen_Cinnost TO XMARKO20;
GRANT ALL ON Objednavka TO XMARKO20;

GRANT EXECUTE ON vek_pri_prijeti TO XMARKO20;
GRANT EXECUTE ON statistika_ucasti_donu_na_setkani TO XMARKO20;

DROP VIEW clenove_Familie_Kolarovi;

CREATE VIEW clenove_Familie_Kolarovi AS
    SELECT R.ID_clena, R.Jmeno, R.Prijmeni
    FROM XBURIA28.Radovy_clen R
    WHERE NAZEV_FAMILIE = 'Kolarovi';

DROP MATERIALIZED VIEW clenove_Familie_Kolarovi_mat;

CREATE MATERIALIZED VIEW clenove_Familie_Kolarovi_mat
REFRESH ON COMMIT AS
    SELECT ID_clena, Jmeno, Prijmeni
    FROM XBURIA28.Radovy_clen
    WHERE NAZEV_FAMILIE = 'Kolarovi';

----------------------------------------------------------------------------------
-- Projekt 4 - demonstrace
----------------------------------------------------------------------------------
-- Explain plan bez indexu
-- Select jakou celkovou rozlohu maji uzemi, ktera v historii patrila jednotlivym Familiim --
-- GROUP BY a agregacni funkce SUM --
EXPLAIN PLAN FOR
    SELECT
        S.Nazev_familie,
        SUM(U.Rozloha) AS Celkova_rozloha
    FROM Uzemi U, R_Spada_Pod S
    WHERE S.ID_uzemi=U.ID_uzemi and S.Nazev_familie IS NOT NULL
    GROUP BY S.Nazev_familie;
SELECT * FROM table (DBMS_XPLAN.DISPLAY);

-- Explain plan s indexem
-- Select jakou celkovou rozlohu maji uzemi, ktera v historii patrila jednotlivym Familiim --
-- GROUP BY a agregacni funkce SUM --

DROP INDEX Uzemi_index;
DROP INDEX Spada_pod_index;

CREATE INDEX Uzemi_index ON Uzemi(ID_uzemi, Rozloha);
CREATE INDEX Spada_pod_index ON R_Spada_Pod(ID_uzemi, Nazev_familie);

EXPLAIN PLAN FOR
    SELECT
        S.Nazev_familie,
        SUM(U.Rozloha) AS Celkova_rozloha
    FROM Uzemi U, R_Spada_Pod S
    WHERE S.ID_uzemi=U.ID_uzemi and S.Nazev_familie IS NOT NULL
    GROUP BY S.Nazev_familie;
SELECT * FROM table (DBMS_XPLAN.DISPLAY);

-- Volani procedur --
BEGIN
vek_pri_prijeti();
END;
BEGIN
statistika_ucasti_donu_na_setkani();
END;

-- Pohled a materializovany pohled --
SELECT * FROM clenove_Familie_Kolarovi;
SELECT * FROM clenove_Familie_Kolarovi_mat;

INSERT INTO XBURIA28.RADOVY_CLEN(ID_clena, Jmeno, Prijmeni, Datum_narozeni, Datum_prijeti, Nazev_familie)
VALUES(5, 'Klementina', 'Spagetova', TO_DATE( '1983-01-06', 'YYYY-MM-DD' ), TO_DATE( '2020-07-06', 'YYYY-MM-DD' ), 'Kolarovi');
COMMIT;

SELECT * FROM clenove_Familie_Kolarovi;
SELECT * FROM clenove_Familie_Kolarovi_mat;

-- Demonstrace triggeru na doplneni chybejicich ID --
SELECT * FROM Uzemi;

-- Trigger - kontrola, zda clen vykonavajici kriminalni cinnost patri do dane Familie --
-- Spravna hodnota --
INSERT INTO R_Clen_Cinnost(jmeno_operace, id_clena, role)
VALUES ('Zabitie Fera', 1, 'uklid tela ze sklepa');

-- Nespravna hodnota - vyjimka --
INSERT INTO R_Clen_Cinnost(jmeno_operace, id_clena, role)
VALUES ('Zabitie Fera', 3, 'uklid tela ze sklepa');
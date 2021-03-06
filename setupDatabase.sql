DROP TABLE IF EXISTS inprogress;
CREATE TABLE inprogress (PhoneNumber CHAR(10) NOT NULL,
 DeviceId VARCHAR(36) NOT NULL,
 InitialLatitude REAL NOT NULL,
 InitialLongitude REAL NOT NULL,
 InitialTime TIMESTAMP NOT NULL,
 LatestLatitude REAL NOT NULL,
 LatestLongitude REAL NOT NULL,
 LatestTime TIMESTAMP NOT NULL,
 ConfirmTime TIMESTAMP NOT NULL,
 CompleteTime TIMESTAMP NOT NULL,
 Status INT NOT NULL,
 Version INT NOT NULL DEFAULT 0,
 CONSTRAINT inprogress_pkey PRIMARY KEY (PhoneNumber, DeviceId),
 CONSTRAINT Check_PhoneNumber CHECK (CHAR_LENGTH(PhoneNumber) = 10));

DROP TABLE IF EXISTS pastpickups;
CREATE TABLE pastpickups (PhoneNumber CHAR(10) NOT NULL,
 DeviceId VARCHAR(36) NOT NULL,
 InitialLatitude REAL NOT NULL,
 InitialLongitude REAL NOT NULL,
 InitialTime TIMESTAMP NOT NULL,
 LatestLatitude REAL NOT NULL,
 LatestLongitude REAL NOT NULL,
 LatestTime TIMESTAMP NOT NULL,
 ConfirmTime TIMESTAMP NOT NULL,
 CompleteTime TIMESTAMP NOT NULL,
 Status INT NOT NULL,
 Version INT NOT NULL DEFAULT 0,
 CONSTRAINT Check_PhoneNumber CHECK (CHAR_LENGTH(PhoneNumber) = 10));

DROP TABLE IF EXISTS vanlocations;
CREATE TABLE vanlocations (VanId INT NOT NULL PRIMARY KEY,
 LatestLatitude REAL NOT NULL,
 LatestLongitude REAL NOT NULL,
 LatestTime TIMESTAMP NOT NULL,
 Version INT NOT NULL DEFAULT 0);

#View public schema tables
SELECT table_schema,table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_schema,table_name;

#Check for table existence
SELECT EXISTS (
   SELECT 1
   FROM   information_schema.tables 
   WHERE  table_schema = 'public'
   AND    table_name = 'inprogress'
);

#View inprogress table columns
SELECT *
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'inprogress'

#Insert new pickup
INSERT INTO inprogress (PhoneNumber, DeviceId, InitialLatitude, InitialLongitude, InitialTime, LatestLatitude, LatestLongitude, LatestTime, ConfirmTime, CompleteTime, Status)
  VALUES ('1234567890', '68753A44-4D6F-1226-9C60-0050E4C00067', 38.9844, 76.4889, '2002-10-02T10:00:00-05:00', 38.9844, 76.4889, '2002-10-02T10:00:00-05:00', DEFAULT, DEFAULT, 0);
SELECT * from inprogress;

#Update existing pickup by phone number
UPDATE inprogress SET LatestLatitude = 38.9855, LatestLongitude = 76.4900, LatestTime = '1111-11-11T11:11:11-05:00'
  WHERE PhoneNumber = '1234567890';
SELECT * from inprogress;

#Update existing pickup location by phone number
UPDATE inprogress SET LatestLatitude = 38.9855, LatestLongitude = 76.4900, LatestTime = '1111-11-11T11:11:11-05:00'
  WHERE PhoneNumber = '1234567890';
SELECT * from inprogress;

#confirm pickup by phone number
UPDATE inprogress SET Status = 2
  WHERE PhoneNumber = '1234567890';
SELECT * from inprogress;

#complete pickup by phone number
UPDATE inprogress SET Status = 3
  WHERE PhoneNumber = '1234567890';
SELECT * from inprogress;



(PhoneNumber, DeviceId, InitialLatitude, InitialLongitude, InitialTime, LatestLatitude, LatestLongitude, LatestTime, ConfirmTime, CompleteTime)
  VALUES ('1234567890', '68753A44-4D6F-1226-9C60-0050E4C00067', 38.9844, 76.4889, '2002-10-02T10:00:00-05:00', 38.9844, 76.4889, '2002-10-02T10:00:00-05:00', DEFAULT, DEFAULT);

#more pickup into pastpickups table and delete from inprogress table
INSERT INTO pastpickups 
 SELECT *
 FROM inprogress
 WHERE PhoneNumber = '1234567890';
DELETE FROM inprogress
 WHERE PhoneNumber = '1234567890';


SELECT * from inprogress;


#trigger for telling when a phone number row has been changed
DROP TRIGGER inprogresschange ON inprogress;

CREATE or REPLACE FUNCTION notifyPhoneNumber() RETURNS trigger AS $$
 BEGIN  
  IF TG_OP='DELETE' THEN
    EXECUTE FORMAT('NOTIFY notifyphonenumber, ''%s''', OLD.PhoneNumber); 
  ELSE
    EXECUTE FORMAT('NOTIFY notifyphonenumber, ''%s''', NEW.PhoneNumber); 
  END IF;
  RETURN NULL;
 END;  
$$ LANGUAGE plpgsql;  

CREATE TRIGGER inprogresschange AFTER INSERT OR UPDATE OR DELETE
 ON inprogress
 FOR EACH ROW 
 EXECUTE PROCEDURE notifyPhoneNumber();

CREATE TRIGGER inprogressdelete AFTER DELETE
 ON inprogress
 FOR EACH ROW 
 EXECUTE PROCEDURE notifyPhoneNumber();

#find own pid
SELECT * FROM pg_stat_activity WHERE pid = pg_backend_pid();

SELECT EXISTS(
    SELECT 1
    FROM pg_trigger
    WHERE tgname='inprogresschange')


--- Get ticket report

SELECT ticketid, ticketdate, ticketpcc, bookpcc, bpcc, son, pcc, line1, 
       line2, line3, segs, tvoid, topen, tused, texch, trfnd, tarpt, 
       tckin, tlftd, tunvl, tprtd, tsusp, 
       (topen + tused + tarpt + tckin + tlftd + tprtd + tunvl) as activesegs
FROM tickets
WHERE bpcc = 'B30' 
AND ticketdate >= '2016-01-01'::date
ORDER BY ticketdate;

--- Ticket summary
SELECT to_char(ticketdate, 'YYYY-MM'), bookpcc, bpcc, son, pcc, 
       sum(topen + tused + tarpt + tckin + tlftd + tprtd + tunvl) as activesegs
FROM tickets
WHERE bpcc = '3L3N' AND for_incentive = false
AND ticketdate >= '2016-01-01'::date
GROUP BY to_char(ticketdate, 'YYYY-MM'), bookpcc, bpcc, son, pcc
ORDER BY to_char(ticketdate, 'YYYY-MM');

--- Ticket details

SELECT tickets.ticketid, ticketdate, ticketpcc, bookpcc, bpcc, son, pcc, line1, 
       line2, line3, segs, tvoid, topen, tused, texch, trfnd, tarpt, 
       tckin, tlftd, tunvl, tprtd, tsusp, 
       tes.details,
       (topen + tused + tarpt + tckin + tlftd + tprtd + tunvl) as activesegs

FROM tickets INNER JOIN tes ON tickets.ticketid = tes.ticketid
WHERE tickets.bpcc = '3L3N' 
AND ticketdate >= '2016-01-01'::date
ORDER BY tickets.ticketdate;


--- DB clean ups
ALTER TABLE tickets
ADD	bpcc			varchar(12),
ADD son				varchar(4);

UPDATE tickets SET bpcc = (CASE WHEN (length(bookpcc) < 3) OR (length(bookpcc) > 10) THEN pcc ELSE substring(bookpcc from 1 for (length(bookpcc)-2)) END);
UPDATE tickets SET son = (CASE WHEN (length(bookpcc) < 3) OR (length(bookpcc) > 10) THEN '' ELSE substring(bookpcc from (length(bookpcc)-1) for 2) END);

DROP VIEW vwperiodyears;
DROP VIEW vwperiods;
DROP VIEW vwsegements;
DROP VIEW vwsonsegs;
DROP VIEW vwbookedsegs;
DROP VIEW vwdayssegs;
DROP VIEW vwdaysagencysegs;
DROP VIEW vwticketsegs;
DROP VIEW vwtickets;
DROP VIEW vwlogs;

UPDATE tickets SET ticketdate = ticketdate - interval '1 year' WHERE ticketdate > '2015-02-02';
UPDATE logs SET logdate = logdate - interval '1 year' WHERE logdate = > '2015-02-02';

DELETE FROM tes USING tickets WHERE tes.ticketid = tickets.ticketid AND ticketdate <= '2013-12-31';
DELETE FROM tickets WHERE ticketdate <= '2013-12-31';
DELETE FROM logdetails USING logs WHERE logdetails.logid = logs.logid AND logdate <= '2013-12-31';
DELETE FROM logs WHERE logdate <= '2013-12-31';

UPDATE tickets SET processed = true WHERE (processed = false) AND (ticketdate < '2017-05-20'::date);

INSERT INTO pccs (pcc, agencyname) VALUES ('781Y', 'FLEET TRAVEL - UAE');

SELECT * FROM vwdayssegs ORDER BY ticketdate;

SELECT vwsegements.yearmonth, vwsegements.spcc, vwsegements.agency, vwsegements.pcc, vwsegements.agencyname, vwsegements.ticketperiod, vwsegements.segperiod, vwsegements.aotsegs, vwsegements.totalsegs, vwsegements.variance
FROM vwsegements
WHERE vwsegements.yearmonth = '911';

------------------------------
SELECT tmp1.val1, a.agencyname, tmp1.val2, a.totalsegs, (tmp1.val2 - a.totalsegs)
FROM tmp1 LEFT JOIN (SELECT pcc, agencyname, totalsegs
	FROM vwbookedsegs WHERE (ticketperiod = '042010')) as a
ON tmp1.val1 = a.pcc
ORDER BY tmp1.val1;


SELECT tmp1.val1, a.agencyname, tmp1.val2, a.totalsegs
FROM tmp1 LEFT JOIN (SELECT pcc, agencyname, totalsegs
	FROM vwticketsegs WHERE (ticketperiod = '042010')) as a
ON tmp1.val1 = a.pcc
ORDER BY tmp1.val1;

SELECT tmp1.val1, a.agencyname, tmp1.val2, a.totalsegs, (tmp1.val2 - a.totalsegs)
FROM tmp1 FULL OUTER JOIN (SELECT pcc, agencyname, totalsegs
	FROM vwbookedsegs WHERE (ticketperiod = '042010')) as a
ON tmp1.val1 = a.pcc
ORDER BY tmp1.val1;


-------------------------------- New changes

ALTER TABLE pccs ADD 	iata_agent boolean default false not null;

-------------------------------- New updates

ALTER TABLE tickets ADD for_incentive		boolean default false;
ALTER TABLE tickets ADD incentive_updated	boolean default false;

ALTER TABLE pccs ADD	agency_incentive	boolean default false;
ALTER TABLE pccs ADD	incentive_son		varchar(12);

UPDATE pccs SET agency_incentive = true, incentive_son = 'PS' WHERE pcc = '77QU';
UPDATE pccs SET agency_incentive = true, incentive_son = 'NN' WHERE pcc = '7GQ4';


UPDATE tickets SET incentive_updated = true WHERE ticketdate < '2015-02-01';

SELECT *
FROM tickets
WHERE ticketdate >= '2015-02-01' and pcc = '77QU' and for_incentive = true and son = 'PS';

SELECT *
FROM tickets
WHERE ticketdate >= '2015-02-01' and  pcc = '7GQ4' and for_incentive = true and son = 'NN';





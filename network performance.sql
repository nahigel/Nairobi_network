select *
from nairobi_network_messy;
-- Renaming Tale
ALTER table nairobi_network_messy rename to nairobi_network;
-- 1. CLEANING DATA

select *
from nairobi_network;

-- a. i)Null values
SELECT * FROM nairobi_network
WHERE 
    data_speed_mbps IS NULL OR data_speed_mbps = ''
    OR signal_strength_dbm IS NULL OR signal_strength_dbm = ''
    OR latency_ms IS NULL OR latency_ms = ''
    OR uptime_pct IS NULL OR uptime_pct = '';

delete 
from nairobi_network
WHERE 
    data_speed_mbps IS NULL OR data_speed_mbps = ''
    OR signal_strength_dbm IS NULL OR signal_strength_dbm = ''
    OR latency_ms IS NULL OR latency_ms = ''
    OR uptime_pct IS NULL OR uptime_pct = '';

SELECT COUNT(*) FROM nairobi_network;

SELECT * FROM nairobi_network
WHERE 
    data_speed_mbps IS NULL OR data_speed_mbps = ''
    OR signal_strength_dbm IS NULL OR signal_strength_dbm = ''
    OR latency_ms IS NULL OR latency_ms = ''
    OR uptime_pct IS NULL OR uptime_pct = '';
    
-- ii) Checking duplicates
select tower_id,`area`,`timestamp`, data_speed_mbps, count(*)
from nairobi_network
group by tower_id,`area`,`timestamp`, data_speed_mbps
having count(*) > 1;

DELETE FROM nairobi_network
WHERE tower_id IN (
    SELECT tower_id FROM (
        SELECT tower_id
        FROM nairobi_network
        GROUP BY 
            tower_id,
            area,
            timestamp,
            data_speed_mbps
        HAVING COUNT(*) > 1
    ) AS duplicates
);
select *
from nairobi_network;
-- Fixing inconsistency in area
UPDATE nairobi_network
SET area = CONCAT(
    UPPER(SUBSTRING(LOWER(TRIM(area)), 1, 1)),
    SUBSTRING(LOWER(TRIM(area)), 2)
);
select distinct area,count(*) as count
from nairobi_network
group by  `area`
order by  `area`;


select *
from nairobi_network;

-- Fixing inconsistency in tower_type
select distinct tower_type,count(*) as count
from nairobi_network
group by tower_type
order by tower_type;
-- 4g
update nairobi_network
set tower_type = '4G'
WHERE tower_type like '%4%';
-- 3g
update nairobi_network
set tower_type = '3G'
WHERE tower_type like '%3%';
-- 2g
update nairobi_network
set tower_type = '3G'
WHERE tower_type like '%3%';
-- EDGE
update nairobi_network
set tower_type = '2G'
WHERE tower_type like '%2%';
update nairobi_network
set tower_type = '2G'
WHERE tower_type like '%EDGE%';

select distinct tower_type,count(*) as count
from nairobi_network
group by tower_type
order by tower_type;

select *
from nairobi_network;
-- Impossible values
select 
    MIN(data_speed_mbps) AS min_speed,
    MAX(data_speed_mbps) AS max_speed,
    MIN(latency_ms) AS min_latency,
    MAX(latency_ms) AS max_latency,
    MIN(uptime_pct) AS min_uptime,
    MAX(uptime_pct) AS max_uptime,
    MIN(dropped_calls) AS min_calls,
    MAX(dropped_calls) AS max_calls
from nairobi_network;

DELETE FROM nairobi_network
WHERE 
    data_speed_mbps < 0
    OR data_speed_mbps > 300
    OR latency_ms > 2000
    OR uptime_pct > 100
    OR dropped_calls > 100;
-- wrong timestamp

select count(*) as wrong
from nairobi_network
where timestamp not like '____-__-__%';

UPDATE nairobi_network
SET timestamp = STR_TO_DATE(timestamp, '%d/%m/%Y %H:%i')
WHERE timestamp NOT LIKE '____-__-__%';

SELECT COUNT(*) as still_wrong
FROM nairobi_network
WHERE timestamp NOT LIKE '____-__-__%';

select *
from nairobi_network;
-- Area with the great performance
select distinct area, round(avg(data_speed_mbps),2), round(avg(latency_ms),2), round(avg(uptime_pct),2)
from nairobi_network
group by area
order by round(avg(uptime_pct),2) desc;

-- Hour with the most dropped calles
SELECT 
    hour,
    SUM(dropped_calls) AS total_dropped_calls,
    ROUND(AVG(data_speed_mbps), 2) AS avg_speed,
    ROUND(AVG(latency_ms), 2) AS avg_latency
FROM nairobi_network
GROUP BY hour
ORDER BY total_dropped_calls DESC;
-- Tower with the best performance
select distinct tower_type, round(avg(data_speed_mbps),2) as speed
from nairobi_network
group by tower_type
order by speed desc;
-- worst performing tower
SELECT 
    tower_id,
    area,
    tower_type,
    ROUND(AVG(data_speed_mbps), 2) AS avg_speed,
    ROUND(AVG(latency_ms), 2) AS avg_latency,
    SUM(dropped_calls) AS total_dropped_calls,
    ROUND(AVG(uptime_pct), 2) AS avg_uptime
FROM nairobi_network
GROUP BY tower_id, area, tower_type
ORDER BY total_dropped_calls DESC, avg_speed ASC
LIMIT 10;

 -- Overall Network Health Score
SELECT
    area,
    tower_type,
    ROUND(AVG(data_speed_mbps), 2) AS avg_speed,
    ROUND(AVG(uptime_pct), 2) AS avg_uptime,
    SUM(dropped_calls) AS total_dropped_calls,
    CASE 
        WHEN AVG(data_speed_mbps) > 20 AND AVG(uptime_pct) > 97 THEN 'Good'
        WHEN AVG(data_speed_mbps) > 10 AND AVG(uptime_pct) > 93 THEN 'Average'
        ELSE 'Poor'
    END AS network_health
FROM nairobi_network
GROUP BY area, tower_type
ORDER BY network_health, avg_speed DESC;








/* GET UNIQUE countries */
SELECT country, count(1) FROM `checkin` GROUP BY country;

/* GET UNIQUE countries separate by comma */
SELECT UNIQUE country FROM checkin ORDER BY country;
SELECT GROUP_CONCAT(DISTINCT country ORDER BY country ASC) AS countries FROM checkin;


/* GET UNIQUE cities */
SELECT country, city, COUNT(arrival) AS visits 
FROM `checkin` 
GROUP BY city
ORDER BY visits DESC;

/* GET UNIQUE cities */
SELECT country, city, COUNT(arrival) AS visits, SUM(DATEDIFF(departure, arrival)) AS 'days', SUM(lived)
FROM `checkin`
GROUP BY city
ORDER BY days DESC;




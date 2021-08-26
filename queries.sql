/* GET UNIQUE countries */
SELECT country, count(1) FROM `checkin` GROUP BY country LIMIT 100

/* GET UNIQUE cities */
SELECT country, city, COUNT(arrival) AS visits 
FROM `checkin` 
GROUP BY city
ORDER BY visits DESC

/* GET UNIQUE cities */
SELECT country, city, COUNT(arrival) AS visits, SUM(DATEDIFF(departure, arrival)) AS 'days'
FROM `checkin`
GROUP BY city
ORDER BY days DESC




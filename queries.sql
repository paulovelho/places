/* GET UNIQUE countries */
SELECT country FROM `checkin` GROUP BY country

/* GET UNIQUE cities */
SELECT country, city, COUNT(arrival) AS visits 
FROM `checkin` 
GROUP BY city
ORDER BY visits DESC

/* GET UNIQUE cities */
SELECT country, city, COUNT(arrival) AS visits, DATEDIFF(departure, arrival) AS 'days'
FROM `checkin`
GROUP BY city
ORDER BY days DESC





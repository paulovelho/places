CREATE TABLE `checkin` ( 
	`arrival` DATETIME NOT NULL,
	`departure` DATETIME,
	`country` VARCHAR(255) NOT NULL,
	`city` VARCHAR(255) NOT NULL,
	`lived` tinyint(1) DEFAULT 0
) 

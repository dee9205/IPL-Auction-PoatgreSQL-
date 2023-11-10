CREATE TABLE Deliveries (id INT, inning INT, over INT, ball INT, batsman varchar, non_striker varchar, bowler varchar, batsman_runs INT,
			  extra_runs int, total_runs int, is_wicket int, dismissal_kind varchar, player_dismissed varchar, fielder varchar,
			  extras_type varchar, batting_team varchar, bowling_team varchar);
			  
COPY Deliveries (id, inning, over, ball, batsman, non_striker, bowler, batsman_runs, extra_runs, total_runs, is_wicket, 
			   dismissal_kind, player_dismissed, fielder, extras_type, batting_team, bowling_team) 
			   FROM 'E:\Data Science with python\SQL\Project\IPL Dataset\IPL Dataset\IPL_ball.csv' DELIMITER ',' CSV HEADER;
			   
SELECT * FROM Deliveries;

CREATE TABLE Matches (id int, city varchar, date varchar, player_of_match varchar, venue varchar, neutral_venue int,
						 team1 varchar, team2 varchar, toss_winner varchar, toss_decision varchar, winner varchar, 
						  result varchar, result_margin int, eliminator varchar, method varchar, umpire1 varchar, umpire2 varchar);
						  
COPY Matches (id, city, date, player_of_match, venue, neutral_venue, team1, team2, toss_winner, toss_decision, winner, 
		       result, result_margin, eliminator, method, umpire1, umpire2) FROM 
			   'E:\Data Science with python\SQL\Project\IPL Dataset\IPL Dataset\IPL_matches.csv' DELIMITER ',' CSV HEADER;
 			   
SELECT * FROM matches;
SELECT * FROM Deliveries;

/*1. BIDDING ON BATSMAN*/

-- Batsman Strike Rate
	   
SELECT *, ROUND(total_run*100/total_balls::numeric,2) AS Strike_rate FROM 
	(SELECT batsman, SUM(batsman_runs) AS total_run, COUNT(ball) AS total_balls 
	 FROM Deliveries WHERE extras_type <> 'wides' GROUP BY batsman) 
AS nt WHERE total_balls > '500' ORDER BY Strike_rate DESC LIMIT 10;
			   

-- Good Average Batsman

SELECT batsman, total_run, times_dismissed, seasons, ROUND(total_run/times_dismissed::numeric,2) AS Average FROM(
SELECT A.batsman, SUM(A.batsman_runs) AS total_run, SUM(A.is_wicket) AS times_dismissed, COUNT(DISTINCT B.year) AS seasons 
FROM Deliveries AS A JOIN
(SELECT ID, EXTRACT(YEAR FROM TO_DATE(date, 'DD-MM-YYYY')) AS year FROM matches) AS B
ON A.ID = B.ID GROUP BY A.batsman)
AS nt WHERE times_dismissed >1 AND seasons > 2 ORDER BY Average DESC LIMIT 10;


-- Hard Hitting players

SELECT batsman, total_Bound_runs,total_runs, Boundaries, ROUND(total_Bound_runs*100/total_runs::numeric,2) AS Boudary_percentage FROM
 	(SELECT A.batsman, SUM(A.batsman_runs) AS total_runs, 
			SUM(CASE WHEN A.batsman_runs = 4 OR A.batsman_runs = 6 THEN A.batsman_runs END) AS total_Bound_runs,
			COUNT(CASE WHEN A.batsman_runs = 4 OR A.batsman_runs = 6 THEN A.batsman_runs END) AS Boundaries,
			COUNT(DISTINCT B.Year) AS seasons
			FROM Deliveries AS A JOIN
	(SELECT ID, EXTRACT(YEAR FROM TO_DATE(date, 'DD-MM-YYYY')) AS year FROM matches) AS B
			ON A.ID = B.ID GROUP BY A.batsman)
AS nt WHERE seasons>2 GROUP BY nt.batsman, nt.Boundaries, nt.total_Bound_runs, nt.total_runs 
ORDER BY Boundaries DESC LIMIT 10;


/*2. BIDDING ON BOWLERS*/

--Bowler with Good Economy

SELECT Bowler, Conceded_runs, overs, ROUND(Conceded_runs/overs::numeric,2) AS Economy FROM
		(
		SELECT 	Bowler, SUM(total_runs) AS Conceded_runs, 
				COUNT(ball) AS total_ball, 
				ROUND(COUNT(ball)/6::numeric,2) AS overs 
		FROM Deliveries GROUP BY Bowler
		) AS nt 
WHERE total_ball >= 500 
GROUP BY Bowler, Conceded_runs, total_ball, overs 
ORDER BY Economy LIMIT 10;

--Bowler with Best Strike rate

SELECT *, ROUND(total_balls/total_wicket::numeric,2) AS Strike_Rate FROM
	(
	SELECT 	Bowler, 
			COUNT(ball) AS total_balls, 
			SUM(is_wicket) AS total_wicket
	FROM Deliveries GROUP BY Bowler
	) 
AS nt 
WHERE total_balls >= 500 
ORDER BY Strike_Rate ASC LIMIT 10;


/*All_rounders with the best batting as well as bowling strike rate*/

CREATE VIEW bowler_data AS 
SELECT 	bowler, 
		COUNT(ball) AS ball_bowled, 
		SUM(is_wicket) AS total_wicket 
FROM Deliveries 
GROUP BY bowler;


CREATE VIEW batsman_data AS 
SELECT 	batsman, 
		SUM(batsman_runs) AS tot_bats_runs, 
		COUNT(ball) AS ball_faced 
FROM Deliveries 
WHERE extras_type <> 'wides' 
GROUP BY batsman;

--3. All Rounders

SELECT 	A.bowler AS Players,
		B.tot_bats_runs*100/B.ball_faced AS Bat_strike_rate,
		ROUND(A.ball_bowled/A.total_wicket::numeric,2) AS ball_strike_rate
FROM bowler_data AS A
INNER JOIN batsman_data AS B 
ON A.bowler = B.batsman 
WHERE B.ball_faced >= 500 AND A.ball_bowled >=300
GROUP BY A.bowler, B.tot_bats_runs,B.ball_faced, A.ball_bowled, A.total_wicket
ORDER BY Bat_strike_rate DESC, ball_strike_rate  
LIMIT 10;

--4. Wicket Keeper

SELECT * FROM Wicket_keaper;

CREATE VIEW Wicket_keaper AS SELECT fielder AS wicket_keaper, COUNT(fielder) AS No_of_time_fielded FROM Deliveries 
WHERE fielder <> 'NA'
GROUP BY fielder ORDER BY No_of_time_fielded DESC
LIMIT 10;

SELECT 	A.*, 
		B.tot_bats_runs*100/B.ball_faced AS WK_bat_SR, 
		ROUND(C.ball_bowled/C.total_wicket::numeric,2) AS WK_ball_SR
FROM Wicket_keaper AS A
LEFT JOIN batsman_data AS B 
ON A.wicket_keaper = B.batsman
LEFT JOIN bowler_data AS C
ON A.wicket_keaper = C.bowler ORDER BY no_of_time_fielded DESC LIMIT 2;



--5. question
--1.
SELECT City, COUNT(city) AS No_of_match_hosted FROM matches GROUP BY city ORDER BY No_of_match_hosted DESC;


--2.
CREATE TABLE deliveries_v02 AS SELECT *, CASE WHEN total_runs >=4 THEN 'Boundary'
														  WHEN total_runs =0 THEN 'Dot'
														  ELSE 'Other'
														  END AS ball_result FROM deliveries;
														  
SELECT * FROM deliveries_v02;

--3.
SELECT ball_result, COUNT(ball_result) AS Total_count FROM deliveries_v02 WHERE ball_result <>'Other' GROUP BY ball_result;

--4.
SELECT batting_team, COUNT(ball_result) AS tot_no_of_Boundary FROM deliveries_v02 WHERE ball_result ='Boundary' 
GROUP BY batting_team ORDER BY tot_no_of_Boundary DESC;

--5.
SELECT bowling_team, COUNT(ball_result) AS tot_dot_balls FROM deliveries_v02 WHERE ball_result ='Dot' 
GROUP BY bowling_team ORDER BY tot_dot_balls DESC;


--6.
SELECT dismissal_kind, COUNT(dismissal_kind) AS No_of_dismissals FROM deliveries_v02 WHERE dismissal_kind <> 'NA' 
GROUP BY dismissal_kind ORDER BY No_of_dismissals DESC;

--7.
SELECT bowler, SUM(extra_runs) AS Extra_Runs FROM Deliveries GROUP BY bowler ORDER BY Extra_Runs DESC LIMIT 5;

--8.
CREATE TABLE deliveries_v03 AS 
SELECT A.*, B.venue AS venue, date AS match_date FROM deliveries_v02 AS A LEFT JOIN
matches AS B ON A.id = B.id;

SELECT * FROM deliveries_v03;

--9.
SELECT venue, SUM(total_runs) AS total_Runs FROM deliveries_v03 GROUP BY venue ORDER BY total_runs DESC;

--10.
SELECT venue, SUBSTRING(match_date FROM 7 FOR 4) AS Year, SUM(total_runs) AS total_runs 
FROM deliveries_v03 WHERE venue = 'Eden Gardens' GROUP BY year,venue ORDER BY total_runs DESC;


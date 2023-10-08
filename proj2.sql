
drop table teams;
drop table coaches_season;
drop table draft;
drop table players;
drop table player_rs_career;
drop table player_rs;


create table teams (tid varchar(30), location varchar(30), name varchar(30), league varchar(30), primary key (tid, league));

create table coaches_season (cid varchar(30), year int, yr_order int,
firstname varchar(30), lastname varchar(30), season_win int, season_loss int, playoff_win int, playoff_loss int, tid varchar(30), primary key (cid, year, yr_order));

create table draft (draft_year int, draft_round int, selection int, tid varchar(30), firstname varchar(30), lastname varchar(30), ilkid  varchar(30), draft_from varchar(100), league varchar(30));

create table players (ilkid varchar(30), firstname varchar(30), lastname varchar(30), position varchar(1), first_season int, last_season int, h_feet int, h_inches real, weight real, college varchar(100), birthday varchar(30), primary key (ilkid)); 

create table player_rs_career (ilkid varchar(30), firstname varchar(30), lastname varchar(30), league varchar(10), gp int, minutes int, pts int, dreb int, oreb int, reb int, asts int, stl int, blk int, turnover int, pf int, fga int, fgm int, fta int, ftm int, tpa int, tpm int);

create table player_rs (ilkid varchar(30), year int, firstname varchar(30), lastname varchar(30), tid varchar(30), league varchar(10), gp int, minutes int, pts int, dreb int, oreb int, reb int, asts int, stl int, blk int, turnover int, pf int, fga int, fgm int, fta int, ftm int, tpa int, tpm int, primary key(ilkid, year, tid));

\copy teams from '/home/matias/Documents/GitHub/sql_NBA_Queries/teams.txt' with delimiter ','
\copy coaches_season from '/home/matias/Documents/GitHub/sql_NBA_Queries/coaches_season.txt' with delimiter ','
\copy players from '/home/matias/Documents/GitHub/sql_NBA_Queries/players.txt' with delimiter ','
\copy player_rs from '/home/matias/Documents/GitHub/sql_NBA_Queries/player_rs.txt' with delimiter ','
\copy player_rs_career from '/home/matias/Documents/GitHub/sql_NBA_Queries/player_rs_career.txt' with delimiter ','
\copy draft from '/home/matias/Documents/GitHub/sql_NBA_Queries/draft.txt' with delimiter ','


-- 1 --------------------------------------------------------------------------------------
SELECT P.ilkid, P.firstname, P.lastname
FROM players P, player_rs PR
WHERE P.ilkid = PR.ilkid AND
PR.tid IN (SELECT tid FROM teams WHERE location = 'Miami') AND
P.ilkid NOT IN (SELECT PR2.ilkid FROM player_rs PR2 WHERE PR2.tid IN (SELECT tid FROM teams WHERE location = 'Dallas'));


-- 2 --------------------------------------------------------------------------------------
SELECT P.ilkid, P.lastname, P.firstname
FROM players P
WHERE P.first_season >= 2000
AND P.last_season <= 2004
ORDER BY P.lastname, P.firstname;


-- 3 -------------------------------------------------------------------------------------- 
WITH CollegeDrafts AS (
    SELECT P.college AS college_name, D.draft_year, COUNT(DISTINCT D.ilkid) AS num_drafts
    FROM players P, draft D
    WHERE P.firstname = D.firstname AND P.lastname = D.lastname
    GROUP BY P.college, D.draft_year
    HAVING COUNT(DISTINCT D.ilkid) > 0
),
CollegeSeasons AS (
    SELECT college_name, COUNT(DISTINCT draft_year) AS num_seasons
    FROM CollegeDrafts
    GROUP BY college_name
    HAVING COUNT(DISTINCT draft_year) >= 3
)
SELECT CS.college_name AS college, AVG(CD.num_drafts * 1.0 / CS.num_seasons) AS avg_drafts_per_season
FROM CollegeDrafts CD, CollegeSeasons CS
WHERE CD.college_name = CS.college_name
GROUP BY CS.college_name;
ORDER BY avg_drafts_per_season;



-- 4 --------------------------------------------------------------------------------------
WITH CoachTeamCount AS 
(
    SELECT CS.cid, CS.firstname, CS.lastname, COUNT(DISTINCT CS.TID) AS team_count
    FROM coaches_season CS
    WHERE CS.year BETWEEN 1985 AND 1990
    GROUP BY CS.cid, CS.firstname, CS.lastname
)

SELECT CT.cid, CT.firstname, CT.lastname
FROM CoachTeamCount CT
WHERE CT.team_count = (SELECT MAX(team_count) FROM CoachTeamCount);


--5 -------------------------------------------------------------------------------------- 
WITH CoachWinsCount AS
(
    SELECT cid, firstname, lastname, (season_win + playoff_win) AS total_wins
    FROM coaches_season
    WHERE yr_order = 1
)

SELECT cid, firstname, lastname, total_wins
FROM CoachWinsCount
WHERE total_wins = (SELECT MAX(total_wins) FROM CoachWinsCount);


-- 6 --------------------------------------------------------------------------------------
WITH CoachFirstYearWin AS
(
    SELECT cid, firstname, lastname, (season_win + playoff_win) AS first_year_win
    FROM coaches_season
    WHERE yr_order = 1
),

CoachSecondYearWin AS
(
    SELECT cid, firstname, lastname, (season_win + playoff_win) AS second_year_win
    FROM coaches_season
    WHERE yr_order = 2
),

CoachImprovement AS
(
    SELECT CFY.cid, CFY.firstname, CFY.lastname, 
        (CSY.second_year_win - CFY.first_year_win) AS improvement
    FROM CoachFirstYearWin CFY, CoachSecondYearWin CSY
    WHERE CFY.cid = CSY.cid
)

SELECT cid, firstname, lastname, improvement
FROM CoachImprovement
WHERE improvement = (SELECT MAX(improvement) FROM CoachImprovement);


-- 7 --------------------------------------------------------------------------------------
SELECT firstname, lastname, (h_feet * 30.48 + h_inches * 2.54) AS height_cm
FROM players
ORDER BY height_cm 
LIMIT 5;


-- 8 --------------------------------------------------------------------------------------
SELECT DISTINCT CS.cid, CS.firstname, CS.lastname
FROM coaches_season CS
WHERE NOT EXISTS (
    (SELECT DISTINCT league
    FROM teams)
    EXCEPT
    (SELECT DISTINCT T1.league
    FROM teams T1
    WHERE T1.tid = cs.tid)
);


-- 9 -------------------------------------------------------------------------------------- 
SELECT CS.cid, CS.firstname, CS.lastname
FROM coaches_season CS, teams T
WHERE CS.tid = T.tid
GROUP BY CS.cid, CS.firstname, CS.lastname
HAVING COUNT(DISTINCT T.league) =  (SELECT COUNT(DISTINCT league) FROM teams);


-- 10 ------------------------------------------------------------------------------------- 
WITH PlayersHeight AS 
(
    SELECT ilkid, firstname, lastname, 
    (h_feet * 30.48 + h_inches * 2.54) AS height_cm
    FROM players
),

TallestPlayers AS
(
    SELECT
        T.tid, T.name,
        P.firstname, P.lastname, P.height_cm,
        ROW_NUMBER() OVER (PARTITION BY T.tid ORDER BY P.height_cm DESC) AS RN
    FROM PlayersHeight P, player_rs PR, teams T
    WHERE P.ilkid = PR.ilkid AND PR.tid = T.tid AND PR.year = 2000
)

SELECT tid, name, firstname, lastname, height_cm
FROM TallestPlayers
WHERE RN = 1
ORDER BY name;


-- 11 -------------------------------------------------------------------------------------
SELECT firstname, lastname, pts
FROM player_rs_career
ORDER BY pts DESC
LIMIT 3;


-- 12 -------------------------------------------------------------------------------------
WITH Players_12s AS 
(
    SELECT ilkid, firstname, lastname 
    FROM players
    WHERE (last_season - first_season + 1) > 12
),

Players_12k AS 
(
    SELECT ilkid, firstname, lastname 
    FROM player_rs_career
    WHERE pts > 12000
)

SELECT firstname, lastname 
FROM (SELECT * FROM Players_12k UNION SELECT * FROM Players_12s) AS CombinedPlayers;

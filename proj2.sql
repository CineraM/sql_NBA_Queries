
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


-- 1
-- SELECT P.ilkid, P.firstname, P.lastname
-- FROM players P, player_rs PR
-- WHERE P.ilkid = PR.ilkid AND
-- PR.tid IN (SELECT tid FROM teams WHERE location = 'Miami') AND
-- P.ilkid NOT IN (SELECT PR2.ilkid FROM player_rs PR2 WHERE PR2.tid IN (SELECT tid FROM teams WHERE location = 'Dallas'));


-- 2
-- SELECT P.ilkid, P.lastname, P.firstname
-- FROM players P
-- WHERE P.first_season >= 2000
-- AND P.last_season <= 2004
-- ORDER BY P.lastname, P.firstname;


-- 3
-- skip for now!
-- SELECT p.college AS college_name, COUNT(DISTINCT d.draft_year) / COUNT(DISTINCT p.first_season) AS avg_drafts_per_season
-- FROM players p
-- JOIN draft d ON p.ilkid = d.ilkid
-- GROUP BY p.college
-- HAVING COUNT(DISTINCT d.draft_year) >= 3


-- 4
-- WITH CoachTeamCount AS 
-- (
--     SELECT CS.cid, CS.firstname, CS.lastname, COUNT(DISTINCT CS.TID) AS team_count
--     FROM coaches_season CS
--     WHERE CS.year BETWEEN 1985 AND 1990
--     GROUP BY CS.cid, CS.firstname, CS.lastname
-- )

-- SELECT CT.cid, CT.firstname, CT.lastname
-- FROM CoachTeamCount CT
-- WHERE CT.team_count = (SELECT MAX(team_count) FROM CoachTeamCount);


-- 7
-- SELECT firstname, lastname, (h_feet * 30.48 + h_inches * 2.54) AS height_cm
-- FROM players
-- ORDER BY height_cm
-- LIMIT 5;


-- 8 
SELECT DISTINCT cs.cid, cs.firstname, cs.lastname
FROM coaches_season cs
WHERE NOT EXISTS (
    SELECT DISTINCT t.league
    FROM teams t
    WHERE t.tid = cs.tid
)
ORDER BY cs.cid;




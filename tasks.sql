-- задача 1
SELECT DISTINCT processor, memory, graphics
FROM twitter.necessary_hardware;

-- задача 2
SELECT id, name, price, release_date, genres, description
FROM twitter.games as g
WHERE g.price>300 OR (g.release_date<'2019-01-01 00:00:00' and  countMatches(g.genres , ',')>=2);

-- задача 3
SELECT DISTINCT g.id, g.name, g.genres, g.description, g.price 
FROM twitter.games as g, 
	(select game_id
	from twitter.open_critic as oc
	where 
	oc.rating>95 and oc.top_critic =TRUE
	) as sub
where g.id = sub.game_id;

-- задача 4
SELECT week(t.timestamp) as week, 
count(distinct t.twitter_account_id) as cnt_unique_accounts, 
count(DISTINCT id) as cnt_unique_tweets, 
AVG(t.quantity_likes) as average_likes, 
AVG(t.quantity_retweets) as average_retweets
	
FROM twitter.tweets t 
GROUP BY week(t.timestamp)
--week, cnt_unique_accounts, cnt_unique_tweets, average_likes, average_retweets

-- задача 5
SELECT g.developer as,year(oc.date), quantile(oc.rating) as QQ

FROM twitter.open_critic oc, twitter.games g
where oc.game_id=g.id
GROUP BY g.developer,year(oc.date)
ORDER BY g.developer,year(oc.date);


-- задача 6

select  
g.id as id, 
g.name as game,
over1000.countaccs as count_accounts_with_1000_or_more_followers_per_game,
less1000.countaccs+over1000.countaccs as total_accounts_per_game,
over1000.countaccs/(less1000.countaccs+over1000.countaccs)*100 as percent_accounts_with_1000_or_more_followers

from twitter.twitter_accounts ta , 
twitter.games as g 

left join  

(SELECT tw.fk_game_id as gameID, count(tw.id) as countaccs
FROM twitter.twitter_accounts as tw
WHERE tw.followers>=1000
GROUP by tw.fk_game_id) as over1000 on g.id=over1000.gameID 

LEFT JOIN

(SELECT tw.fk_game_id as gameID, count(tw.id) as countaccs
FROM twitter.twitter_accounts as tw
WHERE tw.followers<1000
GROUP by tw.fk_game_id) as less1000 on g.id=less1000.gameID 

where over1000.countaccs+less1000.countaccs>0

-- Задание  7
with twc as (
select count(t.id) as tweetcounts, ta.fk_game_id as gameID
from twitter.tweets t , twitter.twitter_accounts ta 
where t.in_reply_to_user_id IS NOT NULL 
	and ta.id=t.twitter_account_id 
GROUP  BY ta.fk_game_id ),


rst as (
select 
sum(t.quantity_likes) as sumlikes, 
sum(t.quantity_retweets) as sumretw, 
sum(t.quantity_quotes) as sumqu, 
sum(t.quantity_replys) as sumrepl, 
ta.fk_game_id as gameID
from twitter.tweets t , twitter.twitter_accounts ta 
where ta.id=t.twitter_account_id 
GROUP  BY ta.fk_game_id )

select DISTINCT  g.id as id, 
g.name as name, 
g.price as price, 
g.release_date as release_date, 
ROUND(2.6*twc.tweetcounts+5.2*rst.sumretw+3.3*rst.sumlikes+7*rst.sumqu+4.2*rst.sumrepl,0) as hype_coefficient

from twitter.games g, twc, rst
where twc.gameID=g.id and rst.gameID=g.id
ORDER BY hype_coefficient DESC 
LIMIT 10


-- задание 8
--
-- 
SELECT id, rating
FROM twitter.open_critic oc  
ORDER BY rating DESC 
LIMIT 1 OFFSET 1;

--=============ДЗ2===========

--- задание 1 
with likesperaccount as (
SELECT sum(t.quantity_likes) as slikes,ta.id as ID
from twitter.tweets t , twitter.twitter_accounts ta 
where t.twitter_account_id=ta.id and year(t.timestamp)=2017
GROUP by ta.id
),

likespergame as 
(
SELECT g.id as ID, sum(ls.slikes) as sslikes
from likesperaccount ls, twitter.twitter_accounts ta , twitter.games g 
where la.ID=ta.id and ta.fk_game_id=g.id
GROUP by g.id

)


select 
g.name,
ta.name,
sum(lg.slikes)

from 
likesperaccount as la, twitter.twitter_accounts as ta, twitter.games as g, likespergame as lg

where la.ID=ta.id and ta.fk_game_id=g.id and lg.id=g.id
GROUP BY g.name, ta.name
ORDER BY g.name, ta.name




---- контрольная
select avg(oc.rating),top_critic 
from twitter.open_critic oc, twitter.social_networks sn 
where oc.game_id = sn.fk_game_id and sn.description ='linkTwitch'

group by top_critic 


-- дз2

--задание 1 готово
with totallikespergame as(
SELECT g.id as ID, sum(t.quantity_likes) as suma
FROM twitter.games g , twitter.twitter_accounts ta , twitter.tweets t 
WHERE t.twitter_account_id =ta.id 
	and ta.fk_game_id =g.id 
	and year(g.release_date)=2017 
	and year(t.`timestamp`)=2017 
GROUP BY g.id),

totalaccountlikes as (
select ta.id as tID,sum(t.quantity_likes) as suma
FROM twitter.tweets t , twitter.twitter_accounts ta 
WHERE t.twitter_account_id=ta.id
group by ta.id
)

select DISTINCT 
	g.id as id, 
	g.name as name, 
	g.developer as developer, 
	g.release_date as release_date,
	ta.id as twitter_account_id, 
	ta.name as twitter_account_name, 
	totallikespergame.suma as sum_likes, 
	totalaccountlikes.suma as total_likes, 
	


--g.id,totallikespergame.suma,
--totalaccountlikes.suma, 

	case 	when totalaccountlikes.suma/totallikespergame.suma > 1 then 100
			when totalaccountlikes.suma/totallikespergame.suma < 0 then 0
			else totalaccountlikes.suma/totallikespergame.suma*100 end as percent_of_total

FROM twitter.twitter_accounts ta, totallikespergame, twitter.games g, twitter.tweets t ,totalaccountlikes
where g.id=totallikespergame.ID and g.id=ta.fk_game_id and ta.id=totalaccountlikes.tID


-- задание 2 готово
with raiting85 as (select g.id as id,
	case when avg(oc.rating)>=85 then 1
	else 0 end as isupper

from twitter.games g , twitter.open_critic oc 
where oc.top_critic = TRUE and g.id=oc.game_id
GROUP BY g.id), 
gamesgenres as (
SELECT 
        arrayJoin(splitByChar(',', genres)) as genre,
        id
    FROM 
        twitter.games
)

select gamesgenres.genre as genre, sum(raiting85.isupper) as gamescount
from twitter.games g, raiting85 , gamesgenres
where gamesgenres.id=raiting85.id 
GROUP BY gamesgenres.genre
ORDER BY gamescount DESC
LIMIT 10

-- задание 3 готово
with gameslist as(
select *
FROM twitter.games g
where g.release_date <'2018-12-01 00:00:00' and g.release_date >='2018-11-01 00:00:00'),

accounts as (
select sn.fk_game_id , sn.description,count(sn.id) as count_social_network_accounts
FROM twitter.social_networks sn 
GROUP BY sn.fk_game_id , sn.description
ORDER BY sn.fk_game_id , sn.description)



SELECT gameslist.id, gameslist.name, substring( accounts.description,5), accounts.count_social_network_accounts
FROM gameslist, accounts
WHERE gameslist.id=accounts.fk_game_id

-- задание 4 готово
with rewieraverage as(
select (company,author) as comauth
,oc.comment
, LENGTH (`comment`) as lcomm
,AVG(lcomm)  OVER (PARTITION BY (company,author)
		order by (company,author), date 
		ROWS BETWEEN  3 PRECEDING AND 1 PRECEDING
		
		) as last3avgR
,date, game_id,oc.id
FROM twitter.open_critic oc 
order by (company,author), date), 

gameaverage as(
select g.id,oc.`date` 
, LENGTH (oc.`comment`) as lcomm
, AVG(lcomm) OVER (
				PARTITION BY g.id 
				ORDER BY g.id, oc.`date` 
				ROWS BETWEEN  3 PRECEDING AND 1 PRECEDING
) as last3avgG
FROM twitter.games g , twitter.open_critic oc 
WHERE oc.game_id =g.id
order by g.id, oc.`date` )

SELECT 
oc.company,
oc.author
--rewieraverage.comauth 
--,rewieraverage.date
, g.name as game_name
, rewieraverage.comment as comment
, rewieraverage.lcomm as current_comment_length
, rewieraverage.last3avgR as previous_3_comment_average_length_this_author
, gameaverage.last3avgG as previous_3_comment_average_length_this_game

FROM rewieraverage,gameaverage ,twitter.games g, twitter.open_critic oc 
WHERE rewieraverage.date= gameaverage.date and rewieraverage.game_id= gameaverage.id and rewieraverage.game_id=g.id and rewieraverage.id=oc.id

-- задание 5 
with topusers as (
select t.twitter_account_id ,count(t.id) as sumtwits 
FROM twitter.tweets t
WHERE t.timestamp <'2017-01-01 00:00:00' and t.timestamp>='2016-01-01 00:00:00'
GROUP BY t.twitter_account_id 
ORDER BY sumtwits DESC
LIMIT 10 )

select t.twitter_account_id, t.text, t.quantity_likes as quantity_likes
,sum(t.quantity_likes)
 OVER (
 PARTITION BY t.twitter_account_id 
 ORDER BY t.twitter_account_id , t.`timestamp` 
 ROWS BETWEEN  UNBOUNDED  PRECEDING AND CURRENT  ROW
 ) as running_sum_likes 

,
t.quantity_quotes as quantity_quotes
,sum(t.quantity_quotes) 
OVER (
 PARTITION BY t.twitter_account_id 
 ORDER BY t.twitter_account_id , t.`timestamp` 
 ROWS BETWEEN  UNBOUNDED  PRECEDING AND CURRENT  ROW
 )
as running_sum_quotes
,t.quantity_retweets as quantity_retweets
,sum(t.quantity_retweets) 
OVER (
 PARTITION BY t.twitter_account_id 
 ORDER BY t.twitter_account_id , t.`timestamp` 
 ROWS BETWEEN  UNBOUNDED  PRECEDING AND CURRENT  ROW
 )
as running_sum_retweets
,t.quantity_replys as quantity_replys
,sum(t.quantity_replys) 
OVER (
 PARTITION BY t.twitter_account_id 
 ORDER BY t.twitter_account_id , t.`timestamp` 
 ROWS BETWEEN  UNBOUNDED  PRECEDING AND CURRENT  ROW
 )
as running_sum_replys

from twitter.tweets t,topusers
where t.twitter_account_id =topusers.twitter_account_id and t.timestamp <'2017-01-01 00:00:00' and t.timestamp>='2016-01-01 00:00:00'
order by t.twitter_account_id , t.`timestamp` 
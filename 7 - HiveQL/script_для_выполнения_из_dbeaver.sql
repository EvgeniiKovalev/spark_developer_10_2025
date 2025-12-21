set hive.stats.autogather=true;
set hive.vectorized.execution.enabled=true;
set hive.vectorized.execution.reduce.enabled=true;
set hive.auto.convert.join=true;
set hive.auto.convert.join.noconditionaltask=true;
set hive.exec.compress.intermediate=true;

/*
 * используя hive в дистрибутиве hortonworks, прришел выводу, что идентификаторы д. быть в нижнем регистре, 
 * т.к. установил, что разные команды по разному записывают в словари системной бд hive по разному, 
 * то в нижнем регистре, то в том в котором создал пользователь -> отсюда вывод, всегда использовать нижний регистр. 
 * Иначе перестают работать команды по обслуживанию таблицы/вьюх (alter/drop сбор статы и т.д.)
 */

--show databases;
create database if not exists airline_db;
--describe database airline_db;

use airline_db;


--drop database airline_db cascade;



--airports
--drop table raw_airports;
create external table if not exists raw_airports (
    airport_id int,
    city string,
    state string,
    name string
)
comment 'Аэропорты'
row format delimited 
fields terminated by ',' 
stored as textfile
location '/user/maria_dev/data/airports'
tblproperties ("skip.header.line.count"="1");

--select * from raw_airports


--drop table airports;
create table if not exists airports (
    airport_id int not null comment 'id аэропорта',
    city string comment 'город аэропорта',
    state string comment 'штат аэропорта',
    name string comment 'название аэропорта'
)
comment 'Аэропорты'
clustered by (airport_id)
sorted by (airport_id)
into 4 buckets
stored as orc
tblproperties (
    "orc.bloom.filter.columns"="airport_id",
    "orc.compress"="SNAPPY"
);

insert overwrite table airports 
select * from raw_airports;



--drop table raw_flights;
create external table raw_flights (
    day_of_month int,
    day_of_week string,
    carrier string,
    origin_airport_id int,
    dest_airport_id int,
    dep_delay int,
    arr_delay int
)
row format delimited 
fields terminated by ',' 
stored as textfile
location '/user/maria_dev/data/flights'
tblproperties ("skip.header.line.count"="1");

--drop table flights;
create table if not exists flights (
    day_of_month int not null comment 'день месяца',
    day_of_week string not null comment 'день недели',
    origin_airport_id int not null comment 'аэропорт вылета',
    dest_airport_id int not null comment 'аэропорт прилета',
    dep_delay int comment 'задержка вылета',
    arr_delay int comment 'задержка прибытия'
)
comment 'Перелеты'
partitioned by (carrier string comment 'перевозчик')
clustered by (origin_airport_id)
sorted by (day_of_month)
into 16 buckets
stored as orc
tblproperties (
    "orc.compress"="SNAPPY",
    "orc.bloom.filter.columns"="origin_airport_id,dest_airport_id"
);

set hive.exec.dynamic.partition = true;
set hive.exec.dynamic.partition.mode = nonstrict;

insert into flights partition(carrier)
-- колонка партиционирования это метаданные(теперь будут создаваться папки
-- /warehouse/.../flights/carrier=xx/ 
-- где xx - это первозчик'
select 
    day_of_month,
    day_of_week,
    origin_airport_id,
    dest_airport_id,
    dep_delay,
    arr_delay,
    carrier -- д. быть последней
from raw_flights;


--select  * from flights
--describe flights;


--1. всего аэропортов и перелетов
--drop materialized view v_airports_flights;

create materialized view if not exists v_airports_flights
comment 'всего аэропортов и перелетов'
stored as parquet
as 
    select 'all quantity airports' as src, count(*) as qty from airports
    union 
    select 'all quantity fligths' as src, count(*) as qty from flights;


--alter materialized view v_airports_flights rebuild;
--select * from v_airports_flights
--show create table v_airports_flights - полный ddl
--describe v_airports_flights -- типы и комменты колонок

--2. количество перелетов по дням недели в разрезе перевозчиков
--

--create materialized view 

--drop materialized view  v_dayofweek_flights;
--отключаем сбор статы,т.к. иногда падает на мат. вью с group by
set hive.stats.autogather=false;
set hive.stats.column.autogather=false;
set hive.compute.query.using.stats=false;

set hive.stats.autogather=true;
set hive.stats.column.autogather=true;
set hive.compute.query.using.stats=true;

create materialized view if not exists v_dayofweek_flights
comment 'количество перелетов по дням недели в разрезе перевозчиков'
stored as orc
tblproperties ("orc.compress"="SNAPPY")
as 
select
    carrier,
    sum(case when day_of_week = 1 then 1 else 0 end) as mon_qty,
    sum(case when day_of_week = 2 then 1 else 0 end) as tue_qty,
    sum(case when day_of_week = 3 then 1 else 0 end) as wed_qty,
    sum(case when day_of_week = 4 then 1 else 0 end) as thu_qty,
    sum(case when day_of_week = 5 then 1 else 0 end) as fri_qty,
    sum(case when day_of_week = 6 then 1 else 0 end) as sat_qty,
    sum(case when day_of_week = 7 then 1 else 0 end) as sun_qty
from flights
group by carrier;


alter table v_dayofweek_flights change column  carrier carrier string comment 'перевозчик';
alter table v_dayofweek_flights change column  mon_qty mon_qty bigint comment'количество перелетов в понедельник';
alter table v_dayofweek_flights change column  tue_qty tue_qty bigint comment'количество перелетов в вторник';
alter table v_dayofweek_flights change column  wed_qty wed_qty bigint comment'количество перелетов в среду';
alter table v_dayofweek_flights change column  thu_qty thu_qty bigint comment'количество перелетов в четверг';
alter table v_dayofweek_flights change column  fri_qty fri_qty bigint comment'количество перелетов в пятницу';
alter table v_dayofweek_flights change column  sat_qty sat_qty bigint comment'количество перелетов в субботу';
alter table v_dayofweek_flights change column  sun_qty sun_qty bigint comment'количество перелетов в воскресенье';


--select * from v_dayofweek_flights
--show create table v_dayofweek_flights - полный ddl
--describe v_dayofweek_flights 


--3. популярность направлений перелетов
--drop materialized view v_popularity_destination
create materialized view if not exists v_popularity_destination 
comment 'количество перелетов по направлениям'
stored as orc
tblproperties ("orc.compress"="SNAPPY")
as
with route_stats as (
    select 
        origin_airport_id, 
        dest_airport_id, 
        count(*) as qty
    from flights
    group by 
        origin_airport_id, 
        dest_airport_id
)
select 
    t.qty,
    t.origin_airport_id as departure_id,
    dep.city as departure_city,
    dep.state as departure_state,
    dep.name as departure_air,
    t.dest_airport_id as arrival_id, 
    arr.city as arrival_city,
    arr.state as arrival_state,
    arr.name as arrival_air    
from route_stats t
    join airports dep on dep.airport_id = t.origin_airport_id
    join airports arr on arr.airport_id = t.dest_airport_id;

--select * from v_popularity_destination order by qty desc;
--describe v_popularity_destination;

alter table v_popularity_destination change column qty qty bigint comment 'количество перелетов';
alter table v_popularity_destination change column departure_id departure_id string comment 'id аэропорта вылета';
alter table v_popularity_destination change column departure_city departure_city string comment 'город аэропорта вылета';
alter table v_popularity_destination change column departure_state departure_state string comment 'штат аэропорта вылета';
alter table v_popularity_destination change column departure_air departure_air string comment 'название аэропорта вылета';

alter table v_popularity_destination change column arrival_id arrival_id string comment 'id аэропорта прибытия';
alter table v_popularity_destination change column arrival_city arrival_city string comment 'город аэропорта прибытия';
alter table v_popularity_destination change column arrival_state arrival_state string comment 'штат аэропорта прибытия';
alter table v_popularity_destination change column arrival_air arrival_air string comment 'название аэропорта прибытия';



--4. загруженность аэропортов перелетами
--drop materialized view v_airport_congestion;
create materialized view if not exists v_airport_congestion 
comment 'загруженность аэропортов перелетами'
stored as orc
tblproperties ("orc.compress"="SNAPPY")
as 
with depart_stats as (
    select 
        origin_airport_id as airport_id, 
        count(*) as cnt
    from flights
    group by origin_airport_id
),
arrival_stats as (
    select 
        dest_airport_id as airport_id, 
        count(*) as cnt
    from flights
    group by dest_airport_id
),
total_traffic as (
    select 
        airport_id, 
        sum(cnt) as qty
    from (
        select airport_id, cnt from depart_stats
        union all
        select airport_id, cnt from arrival_stats
    ) t
    group by airport_id
    having (qty > 0)
)
select
    traf.airport_id,
    air.city,
    air.state,
    air.name,
    traf.qty
from total_traffic traf
    join airports air on air.airport_id = traf.airport_id;

alter table v_airport_congestion change column airport_id airport_id int comment 'id аэропорта';
alter table v_airport_congestion change column city city string comment 'город аэропорта';
alter table v_airport_congestion change column state state string comment 'штат аэропорта';
alter table v_airport_congestion change column name name string comment 'название аэропорта';
alter table v_airport_congestion change column qty qty bigint comment 'количество перелетов аэропорта';

--select * from v_airport_congestion
--select count (*) from v_airport_congestion
--show create table v_airport_congestion
--describe v_airport_congestion

--5. перевозчики которые чаще других задерживают вылеты и прилеты
--drop materialized view v_carrier_delay_stats 
create materialized view if not exists v_carrier_delay_stats
comment 'перевозчики которые чаще других задерживают вылеты и прилеты(средневзвешенно)'
stored as orc
tblproperties ("orc.compress"="SNAPPY")
as 
select
    carrier,
    count(*) as total_flights,
    round((sum(case when dep_delay > 15 then 1 else 0 end) / count(*)) * 100, 2) as pct_delayed_15min,
    round(avg(case when dep_delay > 0 then dep_delay else 0 end), 2) as avg_dep_delay_weighted,
    round(avg(case when arr_delay > 0 then arr_delay else 0 end), 2) as avg_arr_delay_weighted
from flights
group by carrier;


alter table v_carrier_delay_stats change column carrier carrier string comment 'перевозчик';
alter table v_carrier_delay_stats change column total_flights total_flights string comment 'всего полетов';

alter table v_carrier_delay_stats change column pct_delayed_15min pct_delayed_15min double 
comment 'процент рейсов, которые опоздали больше чем на 15 минут';

alter table v_carrier_delay_stats change column avg_dep_delay_weighted avg_dep_delay_weighted double 
comment 'среднее время, на которое самолеты опаздывают с вылетом';

alter table v_carrier_delay_stats change column avg_arr_delay_weighted avg_arr_delay_weighted double 
comment 'среднее время опоздания по прилету';

--select * from v_carrier_delay_stats order by avg_dep_delay_weighted desc


--select * from v_carrier_delay_stats
--select count (*) from v_carrier_delay_stats
--show create table v_carrier_delay_stats
--describe v_carrier_delay_stats
    
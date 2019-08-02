create view rpt_vf_bd_index_view as
with yoy as(
    -- index YOY old
    select date, 
        brand, 
        type, 
        cast(bdindex as float) / (select bdindex from dbo.rpt_vf_bd_index as a1 where (date=dateadd(year,-1,a.date)) and (a.brand=brand) and (a.isnew=isnew) and (a.type=type) and (bdindex>0)) - 1 as a, 
        cast(tbindex as float) / (select tbindex from dbo.rpt_vf_bd_index as a1 where (date=dateadd(year,-1,a.date)) and (a.brand=brand) and (a.isnew=isnew) and (a.type=type) and (tbindex>0)) - 1 as b
        from dbo.rpt_vf_bd_index as a
        where date < '20190101' and date >= '20180101'
        and (isnew='old') 
        and brand in ('Uniqlo','Dickies','Lee','Levi''s','TNF','Timberland','Columbia','Arc Teryx','Toread','Vans','Converse','Adidas originals', 'Nike',
                      'puma','Adidas','Onitsuka Tiger','Jack Wolfskin','Fila','Anta','Lining','Kipling','lesportsac','Columbia','Canada Goose','Herschel','peacebird')
    union all
    -- index YOY new
    select  date, 
            brand, 
            type, 
            cast(bdindex as float) / (select bdindex from dbo.rpt_vf_bd_index as a1 where (date=dateadd(year,-1,a.date)) and (a.brand=brand) and (a.isnew=isnew) and (a.type=type) and (bdindex>0)) - 1 as a, 
            case when date ='2019-06-30' and brand='herschel' then 0.12 else cast(tbindex as float)/(select tbindex from dbo.rpt_vf_bd_index as a1 where (date=dateadd(year,- 1, a.date)) and (a.brand=brand) and (a.isnew=isnew) and (a.type=type) and (tbindex>0)) - 1 end as b
    from dbo.rpt_vf_bd_index as a
    where  date >= '20190101' 
    and isnew='new' 
    and brand in ('Uniqlo','Dickies','Lee','Levi''s','TNF','Timberland','Columbia','Arc Teryx','Toread','Vans','Converse','Adidas originals', 'Nike',
                  'puma','Adidas','Onitsuka Tiger','Jack Wolfskin','Fila','Anta','Lining','Kipling','lesportsac','Columbia','Canada Goose','Herschel','peacebird')
),
index_new as (
    select brand,date,bdindex,tbindex,type
     from dbo.rpt_vf_bd_index
   where (date>'2017-12-01') and (isnew='new')
)

select   a_1.date, 
         a_1.brand, 
         case a_1.type when 'ytd' then 'ytd' 
                       when 'quarter' then 'quarter' 
                       else 'current' 
        end as type, 
        a_1.a,
        a_1.b,
        b.bdindex,
        b.tbindex, 
        case when a_1.type='ytd' then (select bdindex from dbo.rpt_vf_bd_index where brand=a_1.brand and date=a_1.date and type='current' and (date>'2018-12-01' or date<='2018-12-01' and isnew='old')) 
             else b.bdindex 
        end as bdindex_trend, 
        case when a_1.type='ytd' then (select tbindex from dbo.rpt_vf_bd_index where brand=a_1.brand and date=a_1.date and type='current' and (date>'2018-12-01' or date<='2018-12-01' and isnew='old')) 
            else b.tbindex 
        end as tbindex_trend
    from 
         yoy  a_1  
left join 
        index_new b
    on a_1.brand=b.brand 
    and a_1.type=b.type 
    and a_1.date=b.date
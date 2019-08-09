ALTER PROCEDURE [dbo].[sp_rpt_vf_brandperform]
@acctdate date
/*
  name :sp_rpt_vf_brandperform
    依赖存储过程: --sp_vf_qbt_rawdatastore_ytd
                --sp_vf_ecomm_ytd
  target:  --rpt_vf_brandperform --当月数据 前台应用表
             --rpt_vf_brandperform_custom --自定义时间基础应用表
    author:clouddong
    createtime:20190108
    description:汇总品牌类型下每个品牌各个指标数据
*/
as
begin
--从品牌销售明细表按日期，品牌汇总数据




truncate table rpt_vf_brandperform_custom;
with rawstore as
(
    select
        case when t.brand='Urban Exploration' then 'The North Face'
             when t.brand='tnf' then 'The North Face'
             when t.brand='canadagoose' then 'Canada Goose'
             else t.brand
        end brand,
        sales,
        rsp,
        units
    from QBT_RawDatastore t
    where  ((t.brand='Uniqlo' and t.Industry!='女士内衣/男士内衣/家居服')
            or (t.brand='herschel' and t.Industry='箱包皮具/热销女包/男包')
            or t.brand not in ('Uniqlo','herschel'))
),
branddata as
(
    select
        date,
        case when t.brand='Urban Exploration' then 'The North Face'
             when t.brand='tnf' then 'The North Face'
             when t.brand='canadagoose' then 'Canada Goose'
             else t.brand
        end brand,
        sum(case when platform='Total' then sales else 0 end) totsale
    from
        QBT_brand_data
    group by
        date,
        case when t.brand='Urban Exploration' then 'The North Face'
             when t.brand='tnf' then 'The North Face'
             when t.brand='canadagoose' then 'Canada Goose'
             else t.brand
        end
),
industrydata as
(
    select
        date,
        sum(case when b.Industry='男装' and b.Platform='Tmall' then sales else 0 end) menapparel_fm,
        sum(case when b.Industry='女装' and b.Platform='Tmall' then sales else 0 end) womenapparel_fm,
        sum(case when b.Industry='户外' and category in ('户外鞋靴','户外服装') and b.Platform='Tmall'then sales else 0 end) outdoor_fm,
        sum(case when b.Industry in ('运动服','运动鞋') and b.Platform='Tmall' then sales else 0 end) shoesmarket_fm,
        sum(case when b.Industry='箱包' and b.Platform='Tmall' then sales else 0 end) bagmarket_fm,
        sum(case when b.Industry='箱包' and category ='旅行箱' and b.Platform='Tmall' then sales else 0 end) lxx_fm,
        sum(case when b.Industry='运动鞋'  and category ='帆布鞋' and b.Platform='Tmall' then sales else 0 end) fbshoes_fm,
        sum(case when b.Industry='运动鞋'  and category ='跑步鞋' and b.Platform='Tmall' then sales else 0 end) runshoes_fm
    from QBT_industry_data b
    group by
        date
)
insert into rpt_vf_brandperform_custom
(
    date,brand,brandtype,sales,totsale,[finalprice],[adjustprice],[units],[menapparel_fz],[menapparel_fm],[womenapparel_fz],[womenapparel_fm],[msoutdoor_fz],
    [mssportshoes_fz],[msbag_fz],[lxx_fz],[fbshoes_fz],[runshoes_fz],[msoutdoor_fm],[mssportshoes_fm],[msbag_fm],[lxx_fm],[fbshoes_fm],[runshoes_fm],[bagmarket_fm]
)
select
        a.date,
        a.brand,
        a.brandtype,
        a.sales,
        a1.totsale,
        a.sales,
        a.rsp,
        a.units,
        a.menapparel_fz,
        a.womenapparel_fz,
        a.outdoor_fz,
        a.shoesmarket_fz,
        a.bagmarket_fz,
        a.lxx_fz,
        a.fbshoes_fz,
        a.runshoes_fz,
        a2.menapparel_fm,
        a2.womenapparel_fm,
        a2.outdoor_fm msoutdoor_fm,
        a2.shoesmarket_fm mssportshoes_fm,
        a2.lxx_fm,
        a2.fbshoes_fm,
        a2.runshoes_fm,
        a2.bagmarket_fm
from
    (select t.date,
            t.brand brand,
            t1.brandtype1 brandtype,
            sum(t.sales) sales,
            sum(t.rsp) rsp,
            sum(t.units) units,
            sum(case when Industry='男装' then sales else 0 end) menapparel_fz,
            sum(case when Industry='女装/女士精品' then sales else 0 end) womenapparel_fz,
            sum(case when t1.brandtype='outdoor' and Industry='户外/登山/野营/旅行用品' and Category in ('户外鞋靴','户外服装') then sales else 0 end) outdoor_fz,
            sum(case when t1.brandtype='shoes/boots' and Industry in ('运动鞋new','运动服/休闲服装')  then sales else 0 end) shoesmarket_fz,
            sum(case when t1.brandtype='luggage and bags' and industry='箱包皮具/热销女包/男包' then  sales else 0 end) bagmarket_fz,
            sum(case when t1.brandtype='luggage and bags' and industry='箱包皮具/热销女包/男包' and category='旅行箱' then sales else 0 end) lxx_fz,
            sum(case when t1.brandtype='shoes/boots' and Industry='运动鞋new' and Category='帆布鞋' then sales else 0 end) fbshoes_fz,
            sum(case when t1.brandtype='shoes/boots' and Industry='运动鞋new' and Category='跑步鞋' then sales else 0 end) runshoes_fz
            -- sum(case when t1.brandtype='shoes/boots' and Industry='运动鞋new' and Category='板鞋/休闲鞋' then sales else 0 end) sneakernum,
            -- sum(case when t1.brandtype='luggage and bags' and industry='箱包皮具/热销女包/男包' and category='双肩背包' then sales else 0 end) backpacknum,
        from
            rawstore t,dim_vf_brandtype t1
        where t.brand=t1.brand1
        group by 
            t.date,
            t.brand,
            t1.brandtype1
    ) a,
    branddata a1,
    industrydata a2
where a.date=a1.date
  and a.brand=a1.brand
  and a.date=a2.date
  and a.brand=a2.brand;



with ecommdata as
(
select
        DATEADD(MM,DATEDIFF(MM,0,date),0) date,
        case when t.brand='Urban Exploration' then 'The North Face'
             when t.brand='tnf' then 'The North Face'
             when t.brand='canadagoose' then 'Canada Goose'
             else t.brand
        end brand,
        sum(sales) sales,
        sum(rsp) rsp,
        sum(units) units
    from [ExternalData].[dbo].[eComm_2017] t
    where  ((brand='Timberland' and E_commerce_platform in ('Tmall','Tmall FTW') and terminal='Total')
            or (brand!='Timberland' and E_commerce_platform='Tmall' and terminal='Total'))
    group by
        DATEADD(MM,DATEDIFF(MM,0,date),0),
        case when t.brand='Urban Exploration' then 'The North Face'
             when t.brand='tnf' then 'The North Face'
             when t.brand='canadagoose' then 'Canada Goose'
             else t.brand
        end
)
update rpt_vf_brandperform_custom
set sales=t1.sales,
    finalprice=t1.sales,
    adjustprice=t1.rsp,
    units=t1.units
from  ecommdata t1
where rpt_vf_brandperform_custom.date=t1.date
  and rpt_vf_brandperform_custom.brand=t1.brand;


--更新brandrn字段
update rpt_vf_brandperform_custom
set brandrn=b.brandrn
from rpt_vf_brandperform_custom a join
    (select date,brand,brandtype,row_number()over(partition by date,brandtype order by sales desc,brand) as brandrn from rpt_vf_brandperform_custom) b
on  a.date=b.date
and a.brand=b.brand



delete from rpt_vf_brandperform where date=@acctdate ;
with temp as
(
select
        date,
        brand,
        sales,
        sales/(select sales from [rpt_vf_brandperform_custom] where brand=a.brand and dateadd(yy,-1,a.date)=date)-1 sales_yoy,
        (select sum(sales) FROM [rpt_vf_brandperform_custom] where brand=a.brand and year(a.date)=year(date) and date<=a.date) sales_ytd
from [rpt_vf_brandperform_custom] a
 )
insert into rpt_vf_brandperform
(
    date,brand,brandtype,sales,sales_yoy,salesytd,salesytd_yoy,flagdivtotal,avgdiscnt,[asp],[menapparel],[womenapparel],
    [marketshareoutdoor],[marketsharesportshoes],[bagmarketshare],[mk_lxx],[mk_fbshoes],[mk_runshoes],[Frequency]
)
select
    a.date,
    a.brand,
    a.brandtype,
    a.sales,
    a1.sales_yoy,
    a1.salesytd,
    a1.sales_ytd/(select sales_ytd from temp where brand=a.brand and dateadd(yy,-1,a.date)=date)-1 salesytd_yoy,
    a.sales/a.totsale flagdivtotal,
    1-a.sales/a.adjustprice avgdiscnt,
    a.sales/a.units asp,
    a.menapparel_fz/a.menapparel_fm menapparel,
    a.womenapparel_fz/a.womenapparel_fm womenapparel,
    a.outdoor_fz/a2.msoutdoor_fm marketshareoutdoor,
    a.shoesmarket_fz/a2.mssportshoes_fm marketsharesportshoes,
    a.bagmarket_fz/a2.bagmarket_fm bagmarketshare,
    a.lxx_fz/a2.lxx_fm mk_lxx,
    a.fbshoes_fz/a2.fbshoes_fm mk_fbshoes,
    a.runshoes_fz/a2.runshoes_fm mk_runshoes,
    'M' as [Frequency]
from
    rpt_vf_brandperform_custom a,temp a1
where a.date=a1.date
  and a.brand=a1.brand



delete from [ExternalData].[dbo].[rpt_vf_brandperform] where type='YTD';
with temp as
(
select
        date,
        brand,
        brandtype,
        sales,
        sales/(select sales from [rpt_vf_brandperform_custom] where brand=a.brand and dateadd(yy,-1,a.date)=date)-1 sales_yoy,
        (select sum(sales) FROM [rpt_vf_brandperform_custom] where brand=a.brand and year(a.date)=year(date) and date<=a.date) sales_ytd,
        (select sum(totsale) FROM [rpt_vf_brandperform_custom] where brand=a.brand and year(a.date)=year(date) and date<=a.date) totsale_ytd,
        (select sum(adjustprice) FROM [rpt_vf_brandperform_custom] where brand=a.brand and year(a.date)=year(date) and date<=a.date) rsp_ytd,
        (select sum(units) FROM [rpt_vf_brandperform_custom] where brand=a.brand and year(a.date)=year(date) and date<=a.date) units_ytd,
        (select sum(menapparel_fz) FROM [rpt_vf_brandperform_custom] where brand=a.brand and year(a.date)=year(date) and date<=a.date) menapparel_fz_ytd,
        (select sum(menapparel_fm) FROM [rpt_vf_brandperform_custom] where brand=a.brand and year(a.date)=year(date) and date<=a.date) menapparel_fm_ytd,
        (select sum(womenapparel_fz) FROM [rpt_vf_brandperform_custom] where brand=a.brand and year(a.date)=year(date) and date<=a.date) womenapparel_fz_ytd,
        (select sum(womenapparel_fm) FROM [rpt_vf_brandperform_custom] where brand=a.brand and year(a.date)=year(date) and date<=a.date) womenapparel_fm_ytd,
        (select sum(msoutdoor_fz) FROM [rpt_vf_brandperform_custom] where brand=a.brand and year(a.date)=year(date) and date<=a.date) msoutdoor_fz_ytd,
        (select sum(msoutdoor_fm) FROM [rpt_vf_brandperform_custom] where brand=a.brand and year(a.date)=year(date) and date<=a.date) msoutdoor_fm_ytd,
        (select sum(mssportshoes_fz) FROM [rpt_vf_brandperform_custom] where brand=a.brand and year(a.date)=year(date) and date<=a.date) mssportshoes_fz_ytd,
        (select sum(mssportshoes_fm) FROM [rpt_vf_brandperform_custom] where brand=a.brand and year(a.date)=year(date) and date<=a.date) mssportshoes_fm_ytd,
        (select sum(msbag_fz) FROM [rpt_vf_brandperform_custom] where brand=a.brand and year(a.date)=year(date) and date<=a.date) msbag_fz_ytd,
        (select sum(msbag_fm) FROM [rpt_vf_brandperform_custom] where brand=a.brand and year(a.date)=year(date) and date<=a.date) msbag_fm_ytd
from [rpt_vf_brandperform_custom] a
 )
insert into [ExternalData].[dbo].[rpt_vf_brandperform]
(
Frequency,type,date,brand,brandtype,sales,sales_yoy,salesytd,salesytd_yoy,flagdivtotal,avgdiscnt,asp,
menapparel,womenapparel,marketshareoutdoor,marketsharesportshoes,bagmarketshare
)
select 'M'as Frequency,
      'YTD' type,
       date,
       brand,
       brandtype,
       sales,
       sales_yoy,
       sales_ytd,
       sales_ytd/(select sales_ytd from temp where brand=a.brand and dateadd(yy,-1,a.date)=date)-1 salesytd_yoy,
       sales_ytd/totsale_ytd flagdivtotal,
       1-sales_ytd/rsp_ytd avgdiscnt,
       sales_ytd/units_ytd asp,
       menapparel_fz_ytd/menapparel_fm_ytd menapparel,
       womenapparel_fz_ytd/womenapparel_fm_ytd womenapparel,
       msoutdoor_fz_ytd/msoutdoor_fm_ytd marketshareoutdoor,
       mssportshoes_fz_ytd/mssportshoes_fm_ytd marketsharesportshoes,
       msbag_fz_ytd/msbag_fm_ytd bagmarketshare
 from temp a;


-- delete from rpt_vf_brandperform where date=@acctdate ;
-- insert into rpt_vf_brandperform
-- (
--     date,brand,brandtype,sales,sales_yoy,salesytd,salesytd_yoy,flagdivtotal,avgdiscnt,[asp],[menapparel],[womenapparel],
--     [marketshareoutdoor],[marketsharesportshoes],[bagmarketshare],[mk_lxx],[mk_fbshoes],[mk_runshoes],[Frequency]
-- )
-- select
--     a.date,
--     a.brand,
--     a.brandtype,
--     a.sales,
--     a.sales_yoy,
--     a.salesytd,
--     a.salesytd_yoy,
--     case when a1.totsale is null then null else a.sales/a1.totsale end as flagdivtotal,
--     a.avgdiscnt,
--     a.asp,
--     a.menapparel_fz/a2.menapparel_fm menapparel,
--     a.womenapparel_fz/a2.womenapparel_fm womenapparel,
--     a.outdoor_fz/a2.outdoor_fm marketshareoutdoor,
--     a.shoesmarket_fz/a2.shoesmarket_fm marketsharesportshoes,
--     a.bagmarket_fz/a2.bagmarket_fm bagmarketshare,
--     a.lxx_fz/a2.lxx_fm mk_lxx,
--     a.fbshoes_fz/a2.fbshoes_fm mk_fbshoes,
--     a.runshoes_fz/a2.runshoes_fm mk_runshoes,
--     'M' as [Frequency]
-- from
--     (select @acctdate date,
--             t.brand brand,
--             t1.brandtype,
--             sum(case when t.date=@acctdate then t.sales else 0 end) sales,
--             round(sum(case when t.date=@acctdate then t.sales else 0 end)/sum(case when t.date=dateadd(yy,-1,@acctdate) then  t.sales else 0 end),6)-1 sales_yoy ,
--             sum(case when t.date>=datename(year,@acctdate) and t.date<=@acctdate then t.sales else 0 end) salesytd,
--             round(sum(case when t.date>=datename(year,@acctdate) and t.date<=@acctdate then t.sales else 0 end)/sum(case when t.date>=datename(year,dateadd(yy,-1,@acctdate)) and t.date<=dateadd(yy,-1,@acctdate)  then  t.sales else 0 end),6)-1 salesytd_yoy ,
--             --case when t3.totsale is null then null else sum(t.sales)/t2.totsale end as flagdivtotal,
--             1-round(sum(case when t.date=@acctdate then t.sales else 0 end)/sum(case when t.date=@acctdate then t.rsp else 0 end),6) avgdiscnt,
--             sum(case when t.date=@acctdate then t.sales else 0 end)/sum(case when t.date=@acctdate then t.units else 0 end) asp,
--             sum(case when t.date=@acctdate and Industry='男装' then sales else 0 end) menapparel_fz,
--             sum(case when t.date=@acctdate and Industry='女装/女士精品' then sales else 0 end) womenapparel_fz,
--             sum(case when t.date=@acctdate and t1.brandtype='outdoor' and Industry='户外/登山/野营/旅行用品' and Category in ('户外鞋靴','户外服装') then sales else 0 end) outdoor_fz,
--             sum(case when t.date=@acctdate and t1.brandtype='shoes/boots' and Industry in ('运动鞋new','运动服/休闲服装')  then sales else 0 end) shoesmarket_fz,
--             sum(case when t.date=@acctdate and t1.brandtype='luggage and bags' and industry='箱包皮具/热销女包/男包' then  sales else 0 end) bagmarket_fz,
--             sum(case when t.date=@acctdate and t1.brandtype='luggage and bags' and industry='箱包皮具/热销女包/男包' and category='旅行箱' then sales else 0 end) lxx_fz,
--             sum(case when t.date=@acctdate and t1.brandtype='shoes/boots' and Industry='运动鞋new' and Category='帆布鞋' then sales else 0 end) fbshoes_fz,
--             sum(case when t.date=@acctdate and t1.brandtype='shoes/boots' and Industry='运动鞋new' and Category='跑步鞋' then sales else 0 end) runshoes_fz
--             -- sum(case when t1.brandtype='shoes/boots' and Industry='运动鞋new' and Category='板鞋/休闲鞋' then sales else 0 end) sneakernum,
--             -- sum(case when t1.brandtype='luggage and bags' and industry='箱包皮具/热销女包/男包' and category='双肩背包' then sales else 0 end) backpacknum,
--         from
--             rawstore t,dim_vf_brandtype t1
--         where t.brand=t1.brand1
--         group by
--             t.brand,
--             t1.brandtype
--     ) a,
--     branddata a1,
--     industrydata a2
-- where a.date=a1.date
--   and a.brand=a1.brand
--   and a.date=a2.date
--   and a.brand=a2.brand;

-- with ecommdata as
-- (
--     select
--             @acctdate date,
--             brand,
--             sum(case when t.date=@acctdate then t.sales else 0 end) sales,
--             round(sum(case when t.date=@acctdate then t.sales else 0 end)/sum(case when t.date=dateadd(yy,-1,@acctdate) then  t.sales else 0 end),6)-1 sales_yoy,
--             sum(case when t.date>=datename(year,@acctdate) and t.date<=@acctdate then t.sales else 0 end) salesytd,
--             round(sum(case when t.date>=datename(year,@acctdate) and t.date<=@acctdate then t.sales else 0 end)/sum(case when t.date>=datename(year,dateadd(yy,-1,@acctdate)) and t.date<=dateadd(yy,-1,@acctdate)  then  t.sales else 0 end),6)-1 salesytd_yoy ,
--             1-round(sum(case when t.date=@acctdate then t.sales else 0 end)/sum(case when t.date=@acctdate then t.rsp else 0 end),4) avgdiscnt,
--             round(sum(case when t.date=@acctdate then t.sales else 0 end)/sum(case when t.date=@acctdate then t.units else 0 end),4) asp,
--             sum(case when t.date=@acctdate then t.rsp else 0 end) rsp,
--             sum(case when t.date=@acctdate then t.units else 0 end) units
--     from
--         (select
--                 DATEADD(MM,DATEDIFF(MM,0,date),0) date,
--                 case when brand='Urban Exploration' then 'TNF' else brand end brand,
--                 sum(case when date>=@acctdate and date<dateadd(mm,1,@acctdate) then demand_usd else 0 end) sales,
--                 sum(case when date>=datename(year,@acctdate) and date<dateadd(mm,1,@acctdate) then demand_usd else 0 end) sales_ytd,
--                 sum(rsp) rsp,
--                 sum(units) units
--         from [ExternalData].[dbo].[eComm_2017]
--         where (brand='Timberland' and E_commerce_platform in ('Tmall','Tmall FTW') and terminal='Total')
--             or (brand!='Timberland' and E_commerce_platform='Tmall' and terminal='Total')
--         group by
--             DATEADD(MM,DATEDIFF(MM,0,date),0),
--             case when brand='Urban Exploration' then 'TNF' else brand end) t
--     group by brand
-- )
-- update rpt_vf_brandperform
-- set
--     sales=t1.sales,
--     sales_yoy=t1.sales_yoy,
--     salesytd=t1.salesytd,
--     salesytd_yoy=t1.salesytd_yoy,
--     avgdiscnt=t1.avgdiscnt,
--     asp=t1.asp
-- from
--     ecommdata t1
-- where  rpt_vf_brandperform.date=t1.date
--   and  rpt_vf_brandperform.brand=t1.brand;




-- --当月品牌销售指标原始值 --用于前台自定义时间区间指标计算
-- delete from rpt_vf_brandperform_custom where date=@acctdate ;
-- insert into rpt_vf_brandperform_custom
-- (
--     date,brand,brandtype,sales,totsale,[finalprice],[adjustprice],[units],[menapparel_fz],[menapparel_fm],[womenapparel_fz],[womenapparel_fm],[msoutdoor_fz],
--     [mssportshoes_fz],[msbag_fz],[lxx_fz],[fbshoes_fz],[runshoes_fz],[msoutdoor_fm],[mssportshoes_fm],[msbag_fm],[lxx_fm],[fbshoes_fm],[runshoes_fm]
-- )
-- select
--         t.date,
--         case when t.brand='tnf' then 'The North Face' when t.brand='canadagoose' then 'Canada Goose' else t.brand end brand,
--         t.brandtype,
--         t.sales,
--         t2.totsale,
--         t1.sales,
--         t1.rsp,
--         t1.units,
--         t1.menapparel menapparel_fz,
--         (select sum(sales) from  QBT_industry_data b where t.date=b.date  and b.Industry='男装' and b.Platform='Tmall') menapparel_fm,
--         t1.womenapparel womenapparel_fz,
--         (select sum(sales) from  QBT_industry_data b where t.date=b.date  and b.Industry='女装' and b.Platform='Tmall') womenapparel_fm,
--         t.outdoornum,
--         t.shoesmarketnum,
--         t.bagmarketnum,
--         t.lxxnum lxx_fz,
--         t.fbshoesnum fbshoes_fz,
--         t.runshoesnum runshoes_fz,
--         (select sum(sales) from  QBT_industry_data b where t.date=b.date  and b.Industry='户外' and category in ('户外鞋靴','户外服装') and b.Platform='Tmall' ) msoutdoor_fm,
--         (select sum(sales) from  QBT_industry_data b where  t.date=b.date  and b.Industry in ('运动服','运动鞋') and b.Platform='Tmall' ) mssportshoes_fm,
--         (select sum(sales) from  QBT_industry_data b where t.date=b.date   and b.Industry='箱包' and b.Platform='Tmall' ) mssportshoes_fm,
--         (select sum(sales) from  QBT_industry_data b where t.date=b.date  and b.Industry='箱包' and category ='旅行箱' and b.Platform='Tmall' ) lxx_fm,
--         (select sum(sales) from  QBT_industry_data b where  t.date=b.date  and b.Industry='运动鞋'  and category ='帆布鞋' and b.Platform='Tmall' ) fbshoes_fm,
--         (select sum(sales) from  QBT_industry_data b where t.date=b.date  and b.Industry='运动鞋'  and category ='跑步鞋' and b.Platform='Tmall' ) runshoes_fm
--      from
--           #rpt_vf_brandperform_t2    t
-- join
--      branddata t2
-- on t.date=t2.date
-- and t.brand=t2.brand
--  join
-- (select date,
--        case when brand='Urban Exploration' then 'TNF'
--                      else brand
--                 end brand,
--              sum(case when brand='Uniqlo' and Industry='女士内衣/男士内衣/家居服' then 0 when brand='herschel' and Industry<>'箱包皮具/热销女包/男包'  then   0 else rsp end) rsp,
--              sum(case when brand='Uniqlo' and Industry='女士内衣/男士内衣/家居服' then 0 when brand='herschel' and Industry<>'箱包皮具/热销女包/男包'  then   0 else sales end) sales,
--              sum(case when brand='Uniqlo' and Industry='女士内衣/男士内衣/家居服' then 0 when brand='herschel' and Industry<>'箱包皮具/热销女包/男包'  then   0 else units  end) units,
--              sum(case when Industry='男装' then sales else 0 end) menapparel,
--              sum(case when Industry='女装/女士精品' then sales else 0 end) womenapparel
--             from QBT_RawDatastore a
--             where a.date=@acctdate
--         group by date,
--             case when brand='Urban Exploration' then 'TNF'
--                      else brand
--                 end) t1
-- on t.date=t1.date
-- and t.brand=t1.brand;

-- --更新VF自有品牌销售指标原始值
-- update rpt_vf_brandperform_custom
-- set sales=t1.sales,
--       finalprice=t1.sales,
--         adjustprice=t1.rsp,
--         units=t1.units
-- from   #rpt_vf_brandperform_t3 t1
-- where rpt_vf_brandperform_custom.date=t1.date
--     and rpt_vf_brandperform_custom.brand=case when t1.brand='tnf' then 'The North Face' else t1.brand end ;;

-- --更新品牌类型
-- update rpt_vf_brandperform_custom
-- set brandtype=t1.brandtype1
-- from   dim_vf_brandtype t1
-- where  rpt_vf_brandperform_custom.brand=t1.brand;


-- --更新brandrn字段
-- update rpt_vf_brandperform_custom set brandrn=b.brandrn
-- from rpt_vf_brandperform_custom a join
-- (select date,brand,brandtype,row_number()over(partition by date,brandtype order by sales desc,brand) as brandrn from rpt_vf_brandperform_custom)b
-- on a.date=b.date and a.brand=b.brand

-- delete from [ExternalData].[dbo].[rpt_vf_brandperform] where type='YTD';
--  with temp as
--  (select date,brand,brandtype,sales,
--  sales/(select sales from [rpt_vf_brandperform_custom] where brand=a.brand and dateadd(yy,-1,a.date)=date)-1 as sales_yoy,
--  (select sum(sales) FROM [rpt_vf_brandperform_custom] where brand=a.brand and year(a.date)=year(date) and date<=a.date) as sales_ytd,
--  (select sum(totsale) FROM [rpt_vf_brandperform_custom] where brand=a.brand and year(a.date)=year(date) and date<=a.date) as totsale_ytd,
--  (select sum(adjustprice) FROM [rpt_vf_brandperform_custom] where brand=a.brand and year(a.date)=year(date) and date<=a.date) as rsp_ytd,
--  (select sum(units) FROM [rpt_vf_brandperform_custom] where brand=a.brand and year(a.date)=year(date) and date<=a.date) as units_ytd,
--  (select sum(menapparel_fz) FROM [rpt_vf_brandperform_custom] where brand=a.brand and year(a.date)=year(date) and date<=a.date) as menapparel_fz_ytd,
-- (select sum(menapparel_fm) FROM [rpt_vf_brandperform_custom] where brand=a.brand and year(a.date)=year(date) and date<=a.date) as menapparel_fm_ytd,
-- (select sum(womenapparel_fz) FROM [rpt_vf_brandperform_custom] where brand=a.brand and year(a.date)=year(date) and date<=a.date) as womenapparel_fz_ytd,
--  (select sum(womenapparel_fm) FROM [rpt_vf_brandperform_custom] where brand=a.brand and year(a.date)=year(date) and date<=a.date) as womenapparel_fm_ytd,
--   (select sum(msoutdoor_fz) FROM [rpt_vf_brandperform_custom] where brand=a.brand and year(a.date)=year(date) and date<=a.date) as msoutdoor_fz_ytd,
-- (select sum(msoutdoor_fm) FROM [rpt_vf_brandperform_custom] where brand=a.brand and year(a.date)=year(date) and date<=a.date) as msoutdoor_fm_ytd,
-- (select sum(mssportshoes_fz) FROM [rpt_vf_brandperform_custom] where brand=a.brand and year(a.date)=year(date) and date<=a.date) as mssportshoes_fz_ytd,
--  (select sum(mssportshoes_fm) FROM [rpt_vf_brandperform_custom] where brand=a.brand and year(a.date)=year(date) and date<=a.date) as mssportshoes_fm_ytd,
--  (select sum(msbag_fz) FROM [rpt_vf_brandperform_custom] where brand=a.brand and year(a.date)=year(date) and date<=a.date) as msbag_fz_ytd,
--  (select sum(msbag_fm) FROM [rpt_vf_brandperform_custom] where brand=a.brand and year(a.date)=year(date) and date<=a.date) as msbag_fm_ytd
--  from [rpt_vf_brandperform_custom] a)
-- insert into [ExternalData].[dbo].[rpt_vf_brandperform](Frequency,type,date,brand,brandtype,sales,sales_yoy,salesytd,salesytd_yoy,flagdivtotal,avgdiscnt,asp,
-- menapparel,womenapparel,marketshareoutdoor,marketsharesportshoes,bagmarketshare)
--  select 'M'as Frequency,'YTD' as type, date,brand,brandtype,sales,sales_yoy,sales_ytd,
--  sales_ytd/(select sales_ytd from temp where brand=a.brand and dateadd(yy,-1,a.date)=date)-1 as salesytd_yoy,
--  sales_ytd/totsale_ytd as flagdivtotal,1-sales_ytd/rsp_ytd as avgdiscnt,sales_ytd/units_ytd as asp,
--  menapparel_fz_ytd/menapparel_fm_ytd as menapparel,womenapparel_fz_ytd/womenapparel_fm_ytd as womenapparel,
--  msoutdoor_fz_ytd/msoutdoor_fm_ytd as marketshareoutdoor,mssportshoes_fz_ytd/mssportshoes_fm_ytd as marketsharesportshoes,
--  msbag_fz_ytd/msbag_fm_ytd as bagmarketshare
--  from temp a

end

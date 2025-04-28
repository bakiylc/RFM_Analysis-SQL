/*
Veri Seti Hazýrlýðý : 

1--- Flo verisine SQL databaseden ulaþýn.
Select * from FLO

2--- Ýlk 10 gözlem'i getirin.
Select TOP 10 * from FLO

3---Deðiþken isimleri
	a-- SELECT  * FROM FLO.INFORMATION_SCHEMA.COLUMNS


	b-- SELECT COLUMN_NAME AS DEGISKEN_ISIMLERI
		FROM FLO.INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = 'FLO'

4--- Boyut
SELECT COUNT(*) AS SATIR_SAYISI,
    (SELECT
        COUNT(COLUMN_NAME) AS DEGISKEN_ISIMLERI
    FROM FLO.INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'FLO') KOLON_SAYISI
FROM FLO

5--- Boþ deðerleri gözden geçirin.
Select * From FLO Where master_id IS NULL
Select * From FLO Where order_channel IS NULL
Select * From FLO Where last_order_channel IS NULL
Select * From FLO Where first_order_date IS NULL
Select * From FLO Where last_order_date IS NULL
Select * From FLO Where last_order_date_online IS NULL
Select * From FLO Where last_order_date_offline IS NULL
Select * From FLO Where order_num_total_ever_online IS NULL
Select * From FLO Where order_num_total_ever_offline IS NULL
Select * From FLO Where customer_value_total_ever_offline IS NULL
Select * From FLO Where customer_value_total_ever_online IS NULL
Select * From FLO Where interested_in_categories_12 IS NULL
Select * From FLO Where store_type IS NULL

6--- Deðiþken tipleri incelenmesi
SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM FLO.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'FLO'

7--- Kullandýðýmýz Tablo'nun Kopyasýný Oluþturma (Yedek amaçlý)
Select *  INTO FLO2 FROM FLO 

-- WHERE 1 = 0 Þartýný eklersek eðer tabloyu içinde veri olmadan sadece yapýsal olarak kopyalar.

8---Omichannel müþterilerin hem online'dan hemde offline platformlardan alýþveriþ yaptýðýný ifade etmekdir. 
	Herbir müþterinin toplam alýþveriþ sayýsý ve harcamasý için yeni deðiþkenler oluþturun.

ALTER TABLE flo ADD order_num_total AS (order_num_total_ever_online + order_num_total_ever_offline);
SELECT * FROM flo
ALTER TABLE flo ADD customer_value_total AS (customer_value_total_ever_offline + customer_value_total_ever_online);
SELECT * FROM flo

9--- Alýþveriþ kanallarýndaki müþteri sayýsýnýn, ortalama alýnan ürün sayýsýnýn ve ortalama harcamalarýn daðýlýmýna bakýnýz.
SELECT
    order_channel,
    COUNT(Master_id) AS COUNT_MASTER_ID,
    ROUND(AVG(order_num_total),0) AS AVG_ORDER_NUM_TOTAL,
    ROUND(AVG(customer_value_total),0) AVG_CUSTOMER_NUM_TOTAL
FROM FLO
GROUP BY order_channel

10--- En fazla kazancý getiren ilk 10 müþteriyi sýralayýnýz
SELECT TOP 10 * FROM flo ORDER BY customer_value_total DESC;


RFM analizi müþterilerin davranýþlarýný üç temel metrik üzerinden deðerlendirir:

Recency (Yakýnlýk): Müþterinin en son ne zaman alýþveriþ yaptýðýný gösterir. (Müþterilerin en son alýþveriþ tarihlerinin yakýn olmasý, iþletme ile ilgilerini koruduklarýný gösterir.)
Frequency (Sýklýk): Müþterinin belirli bir zaman diliminde ne sýklýkta alýþveriþ yaptýðýný belirtir. (Daha sýk alýþveriþ yapan müþteriler, iþletmeye daha baðlýdýr.)
Monetary (Parasal Deðer): Müþterinin toplamda ne kadar harcama yaptýðýný ifade eder. (Daha fazla harcama yapan müþteriler, iþletme için daha deðerlidir.)

## RFM Metriklerini Hesaplayalým. ##

-- # Veri setindeki en son alýþveriþin yapýldýðý tarihten 2 gün sonrasýný analiz tarihi olarak alýnacaktýr.
-- 2021-05-30 max tarihtir.
--- En son yapýlan alýþveriþ tarihini hesaplayalým:

SELECT MAX(last_order_date) AS SON_ALISVERIS_TARIHI FROM FLO

-- analysis_date = (2021,6,1)
-- customer_id, recency, frequnecy ve monetary deðerlerinin yer aldýðý yeni bir RFM adýnda tablo oluþturunuz.

SELECT master_id AS CUSTOMER_ID,
       DATEDIFF(DAY, last_order_date, '20210601') AS RECENCY,
     order_num_total AS FREQUENCY,
     customer_value_total AS MONETARY,
     NULL RECENCY_SCORE,
     NULL FREQUENCY_SCORE,
     NULL MONETARY_SCORE
INTO RFM
FROM flo

-- Recency, Frequency ve Monetary deðerlerinin incelenmesi
Select * From RFM

--RF ve RFM Skorlarýnýn Hesaplanmasý (Calculating RF and RFM Scores)
--RECENCY_SCORE Oluþturulmasý
UPDATE RFM SET RECENCY_SCORE =
    (SELECT SCORE FROM
        (SELECT
            A.*,
            NTILE(5) over (ORDER BY RECENCY DESC) SCORE
        FROM RFM AS A
    ) T
    WHERE T.CUSTOMER_ID = RFM.Customer_ID )
    
	
--FREQUENCY_SCORE Oluþturulmasý
UPDATE RFM SET FREQUENCY_SCORE =
    (SELECT SCORE FROM
        (SELECT
            A.*,
            NTILE(5) over (ORDER BY FREQUENCY) AS SCORE
        FROM RFM AS A )T
    WHERE T.CUSTOMER_ID = RFM.CUSTOMER_ID)

--MONETARY_SCORE Oluþturulmasý
UPDATE RFM SET MONETARY_SCORE =
    (SELECT SCORE FROM
        (SELECT
            A.*,
            NTILE(5) over (ORDER BY MONETARY) AS SCORE
    FROM RFM AS A )T
    WHERE T.CUSTOMER_ID = RFM.CUSTOMER_ID)

--Oluþan skorlarýn incelenmesi
select * from RFM

-- # RECENCY_SCORE ve FREQUENCY_SCORE’u tek bir deðiþken olarak ifade edilmesi ve RF_SCORE olarak kaydedilmesi
Alter Table RFM ADD RF_SCORE as (Convert(Varchar,Recency_Score) + Convert(Varchar,Frequency_Score))

-- # RECENCY_SCORE ve FREQUENCY_SCORE ve MONETARY_SCORE'u tek bir deðiþken olarak ifade edilmesi ve RFM_SCORE olarak kaydedilmesi
Alter Table RFM ADD RFM_SCORE as (Convert(Varchar,Recency_Score) + Convert(Varchar,Frequency_Score)+Convert(Varchar,Monetary_Score))

## RFM Metriklerinin Daha Anlaþýlýr Olmasý Ýçin Segmentasyon Yapalým ##

-- SEGMENT adýnda yeni bir kolon oluþturunuz.
ALTER TABLE RFM ADD SEGMENT VARCHAR(50)

-- Hibernating sýnýfýnýn oluþturulmasý
UPDATE RFM SET SEGMENT='Hibernating' 
WHERE RECENCY_SCORE LIKE '[1-2]%' AND FREQUENCY_SCORE LIKE '[1-2]%'

--at Risk sýnýfýnýn oluþturulmasý
UPDATE RFM SET SEGMENT='At Risk' 
WHERE RECENCY_SCORE LIKE'[1-2]%' AND FREQUENCY_SCORE LIKE '[3-4]%'

-- Can't Loose sýnýfýnýn oluþturulmasý
UPDATE RFM SET SEGMENT ='cant_loose'
WHERE RECENCY_SCORE LIKE '[1-2]%' AND FREQUENCY_SCORE LIKE '[5]%'

-- About to Sleep sýnýfýnýn oluþturulmasý
UPDATE RFM SET SEGMENT ='about_to_sleep'
WHERE RECENCY_SCORE LIKE '[3]%' AND FREQUENCY_SCORE LIKE '[1-2]%'

-- Need Attention sýnýfýnýn oluþturulmasý
UPDATE RFM SET SEGMENT ='need_attention'
WHERE RECENCY_SCORE LIKE '[3]%' AND FREQUENCY_SCORE LIKE '[3]%'

-- Loyal Customers sýnýfýnýn oluþturulmasý
UPDATE RFM SET SEGMENT ='loyal_customers'
WHERE RECENCY_SCORE LIKE '[3-4]%' AND FREQUENCY_SCORE LIKE '[4-5]%'

-- Promising sýnýfýnýn oluþturulmasý
UPDATE RFM SET SEGMENT ='promising'
WHERE RECENCY_SCORE LIKE '[4]%' AND FREQUENCY_SCORE LIKE '[1]%'

-- New Customers sýnýfýnýn oluþturulmasý
UPDATE RFM SET SEGMENT ='new_customers'
WHERE RECENCY_SCORE LIKE '[5]%' AND FREQUENCY_SCORE LIKE '[1]%'

-- Potential Loyalist sýnýfýnýn oluþturulmasý
UPDATE RFM SET SEGMENT ='potential_loyalists'
WHERE RECENCY_SCORE LIKE '[4-5]%' AND FREQUENCY_SCORE LIKE '[2-3]%'

-- Champions sýnýfýnýn oluþturulmasý
UPDATE RFM SET SEGMENT ='champions'
WHERE RECENCY_SCORE LIKE '[5]%' AND FREQUENCY_SCORE LIKE '[4-5]%'

## Elde Ettiðimiz RFM Tablosundaki Verilere Göre Analizler Yapalým.##

# 1. Segmentlerin recency, frequnecy ve monetary ortalamalarýný inceleyiniz.
SELECT SEGMENT,
       COUNT(RECENCY) AS COUNT_RECENCY,
     AVG(RECENCY) AS AVG_RECENCY,
     COUNT(FREQUENCY) AS COUNT_FREQUENCY,
     ROUND(AVG(FREQUENCY),3) AS AVG_FREQUENCY,
     COUNT(MONETARY) AS COUNT_MONETARY,
     ROUND(AVG(MONETARY),3) AS AVG_MONETARY
FROM RFM
GROUP BY SEGMENT

2. RFM analizi yardýmý ile 2 case için ilgili profildeki müþterileri bulunuz.

# a. FLO bünyesine yeni bir kadýn ayakkabý markasý dahil ediyor. Dahil ettiði markanýn ürün fiyatlarý genel müþteri tercihlerinin üstünde. Bu nedenle markanýn
# tanýtýmý ve ürün satýþlarý için ilgilenecek profildeki müþterilerle özel olarak iletiþime geçilmek isteniliyor. Bu müþterilerin sadýk, ortalama 250 TL üzeri ve
# kadýn kategorisinden alýþveriþ yapan kiþiler olmasý planlandý. Müþterilerin id numaralarýný getiriniz.

Select R.CUSTOMER_ID,F.interested_in_categories_12 
From RFM R 
INNER JOIN FLO F ON R.CUSTOMER_ID = F.master_id
WHERE (F.customer_value_total / F.order_num_total) > 250 
AND 
F.interested_in_categories_12 LIKE '%KADIN%' 
AND 
R.SEGMENT IN ('champions', 'loyal_customers')

# b. Erkek ve Çoçuk ürünlerinde %40'a yakýn indirim planlanmaktadýr. Bu indirimle ilgili kategorilerle ilgilenen geçmiþte iyi müþterilerden olan ama uzun süredir
# alýþveriþ yapmayan ve yeni gelen müþteriler özel olarak hedef alýnmak isteniliyor. Uygun profildeki müþterilerin id'lerini getiriniz.

SELECT R.Customer_ID, F.interested_in_categories_12
FROM RFM R 
INNER JOIN FLO F ON R.Customer_ID = F.Master_id
WHERE 
    R.SEGMENT IN ('cant_loose', 'hibernating', 'new_customers')
    AND (
        F.interested_in_categories_12 LIKE '%ERKEK%' 
        OR F.interested_in_categories_12 LIKE '%COCUK%'
    )
ORDER BY 2;

*/










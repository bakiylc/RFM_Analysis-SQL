/*
Veri Seti Haz�rl��� : 

1--- Flo verisine SQL databaseden ula��n.
Select * from FLO

2--- �lk 10 g�zlem'i getirin.
Select TOP 10 * from FLO

3---De�i�ken isimleri
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

5--- Bo� de�erleri g�zden ge�irin.
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

6--- De�i�ken tipleri incelenmesi
SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM FLO.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'FLO'

7--- Kulland���m�z Tablo'nun Kopyas�n� Olu�turma (Yedek ama�l�)
Select *  INTO FLO2 FROM FLO 

-- WHERE 1 = 0 �art�n� eklersek e�er tabloyu i�inde veri olmadan sadece yap�sal olarak kopyalar.

8---Omichannel m��terilerin hem online'dan hemde offline platformlardan al��veri� yapt���n� ifade etmekdir. 
	Herbir m��terinin toplam al��veri� say�s� ve harcamas� i�in yeni de�i�kenler olu�turun.

ALTER TABLE flo ADD order_num_total AS (order_num_total_ever_online + order_num_total_ever_offline);
SELECT * FROM flo
ALTER TABLE flo ADD customer_value_total AS (customer_value_total_ever_offline + customer_value_total_ever_online);
SELECT * FROM flo

9--- Al��veri� kanallar�ndaki m��teri say�s�n�n, ortalama al�nan �r�n say�s�n�n ve ortalama harcamalar�n da��l�m�na bak�n�z.
SELECT
    order_channel,
    COUNT(Master_id) AS COUNT_MASTER_ID,
    ROUND(AVG(order_num_total),0) AS AVG_ORDER_NUM_TOTAL,
    ROUND(AVG(customer_value_total),0) AVG_CUSTOMER_NUM_TOTAL
FROM FLO
GROUP BY order_channel

10--- En fazla kazanc� getiren ilk 10 m��teriyi s�ralay�n�z
SELECT TOP 10 * FROM flo ORDER BY customer_value_total DESC;


RFM analizi m��terilerin davran��lar�n� �� temel metrik �zerinden de�erlendirir:

Recency (Yak�nl�k): M��terinin en son ne zaman al��veri� yapt���n� g�sterir. (M��terilerin en son al��veri� tarihlerinin yak�n olmas�, i�letme ile ilgilerini koruduklar�n� g�sterir.)
Frequency (S�kl�k): M��terinin belirli bir zaman diliminde ne s�kl�kta al��veri� yapt���n� belirtir. (Daha s�k al��veri� yapan m��teriler, i�letmeye daha ba�l�d�r.)
Monetary (Parasal De�er): M��terinin toplamda ne kadar harcama yapt���n� ifade eder. (Daha fazla harcama yapan m��teriler, i�letme i�in daha de�erlidir.)

## RFM Metriklerini Hesaplayal�m. ##

-- # Veri setindeki en son al��veri�in yap�ld��� tarihten 2 g�n sonras�n� analiz tarihi olarak al�nacakt�r.
-- 2021-05-30 max tarihtir.
--- En son yap�lan al��veri� tarihini hesaplayal�m:

SELECT MAX(last_order_date) AS SON_ALISVERIS_TARIHI FROM FLO

-- analysis_date = (2021,6,1)
-- customer_id, recency, frequnecy ve monetary de�erlerinin yer ald��� yeni bir RFM ad�nda tablo olu�turunuz.

SELECT master_id AS CUSTOMER_ID,
       DATEDIFF(DAY, last_order_date, '20210601') AS RECENCY,
     order_num_total AS FREQUENCY,
     customer_value_total AS MONETARY,
     NULL RECENCY_SCORE,
     NULL FREQUENCY_SCORE,
     NULL MONETARY_SCORE
INTO RFM
FROM flo

-- Recency, Frequency ve Monetary de�erlerinin incelenmesi
Select * From RFM

--RF ve RFM Skorlar�n�n Hesaplanmas� (Calculating RF and RFM Scores)
--RECENCY_SCORE Olu�turulmas�
UPDATE RFM SET RECENCY_SCORE =
    (SELECT SCORE FROM
        (SELECT
            A.*,
            NTILE(5) over (ORDER BY RECENCY DESC) SCORE
        FROM RFM AS A
    ) T
    WHERE T.CUSTOMER_ID = RFM.Customer_ID )
    
	
--FREQUENCY_SCORE Olu�turulmas�
UPDATE RFM SET FREQUENCY_SCORE =
    (SELECT SCORE FROM
        (SELECT
            A.*,
            NTILE(5) over (ORDER BY FREQUENCY) AS SCORE
        FROM RFM AS A )T
    WHERE T.CUSTOMER_ID = RFM.CUSTOMER_ID)

--MONETARY_SCORE Olu�turulmas�
UPDATE RFM SET MONETARY_SCORE =
    (SELECT SCORE FROM
        (SELECT
            A.*,
            NTILE(5) over (ORDER BY MONETARY) AS SCORE
    FROM RFM AS A )T
    WHERE T.CUSTOMER_ID = RFM.CUSTOMER_ID)

--Olu�an skorlar�n incelenmesi
select * from RFM

-- # RECENCY_SCORE ve FREQUENCY_SCORE�u tek bir de�i�ken olarak ifade edilmesi ve RF_SCORE olarak kaydedilmesi
Alter Table RFM ADD RF_SCORE as (Convert(Varchar,Recency_Score) + Convert(Varchar,Frequency_Score))

-- # RECENCY_SCORE ve FREQUENCY_SCORE ve MONETARY_SCORE'u tek bir de�i�ken olarak ifade edilmesi ve RFM_SCORE olarak kaydedilmesi
Alter Table RFM ADD RFM_SCORE as (Convert(Varchar,Recency_Score) + Convert(Varchar,Frequency_Score)+Convert(Varchar,Monetary_Score))

## RFM Metriklerinin Daha Anla��l�r Olmas� ��in Segmentasyon Yapal�m ##

-- SEGMENT ad�nda yeni bir kolon olu�turunuz.
ALTER TABLE RFM ADD SEGMENT VARCHAR(50)

-- Hibernating s�n�f�n�n olu�turulmas�
UPDATE RFM SET SEGMENT='Hibernating' 
WHERE RECENCY_SCORE LIKE '[1-2]%' AND FREQUENCY_SCORE LIKE '[1-2]%'

--at Risk s�n�f�n�n olu�turulmas�
UPDATE RFM SET SEGMENT='At Risk' 
WHERE RECENCY_SCORE LIKE'[1-2]%' AND FREQUENCY_SCORE LIKE '[3-4]%'

-- Can't Loose s�n�f�n�n olu�turulmas�
UPDATE RFM SET SEGMENT ='cant_loose'
WHERE RECENCY_SCORE LIKE '[1-2]%' AND FREQUENCY_SCORE LIKE '[5]%'

-- About to Sleep s�n�f�n�n olu�turulmas�
UPDATE RFM SET SEGMENT ='about_to_sleep'
WHERE RECENCY_SCORE LIKE '[3]%' AND FREQUENCY_SCORE LIKE '[1-2]%'

-- Need Attention s�n�f�n�n olu�turulmas�
UPDATE RFM SET SEGMENT ='need_attention'
WHERE RECENCY_SCORE LIKE '[3]%' AND FREQUENCY_SCORE LIKE '[3]%'

-- Loyal Customers s�n�f�n�n olu�turulmas�
UPDATE RFM SET SEGMENT ='loyal_customers'
WHERE RECENCY_SCORE LIKE '[3-4]%' AND FREQUENCY_SCORE LIKE '[4-5]%'

-- Promising s�n�f�n�n olu�turulmas�
UPDATE RFM SET SEGMENT ='promising'
WHERE RECENCY_SCORE LIKE '[4]%' AND FREQUENCY_SCORE LIKE '[1]%'

-- New Customers s�n�f�n�n olu�turulmas�
UPDATE RFM SET SEGMENT ='new_customers'
WHERE RECENCY_SCORE LIKE '[5]%' AND FREQUENCY_SCORE LIKE '[1]%'

-- Potential Loyalist s�n�f�n�n olu�turulmas�
UPDATE RFM SET SEGMENT ='potential_loyalists'
WHERE RECENCY_SCORE LIKE '[4-5]%' AND FREQUENCY_SCORE LIKE '[2-3]%'

-- Champions s�n�f�n�n olu�turulmas�
UPDATE RFM SET SEGMENT ='champions'
WHERE RECENCY_SCORE LIKE '[5]%' AND FREQUENCY_SCORE LIKE '[4-5]%'

## Elde Etti�imiz RFM Tablosundaki Verilere G�re Analizler Yapal�m.##

# 1. Segmentlerin recency, frequnecy ve monetary ortalamalar�n� inceleyiniz.
SELECT SEGMENT,
       COUNT(RECENCY) AS COUNT_RECENCY,
     AVG(RECENCY) AS AVG_RECENCY,
     COUNT(FREQUENCY) AS COUNT_FREQUENCY,
     ROUND(AVG(FREQUENCY),3) AS AVG_FREQUENCY,
     COUNT(MONETARY) AS COUNT_MONETARY,
     ROUND(AVG(MONETARY),3) AS AVG_MONETARY
FROM RFM
GROUP BY SEGMENT

2. RFM analizi yard�m� ile 2 case i�in ilgili profildeki m��terileri bulunuz.

# a. FLO b�nyesine yeni bir kad�n ayakkab� markas� dahil ediyor. Dahil etti�i markan�n �r�n fiyatlar� genel m��teri tercihlerinin �st�nde. Bu nedenle markan�n
# tan�t�m� ve �r�n sat��lar� i�in ilgilenecek profildeki m��terilerle �zel olarak ileti�ime ge�ilmek isteniliyor. Bu m��terilerin sad�k, ortalama 250 TL �zeri ve
# kad�n kategorisinden al��veri� yapan ki�iler olmas� planland�. M��terilerin id numaralar�n� getiriniz.

Select R.CUSTOMER_ID,F.interested_in_categories_12 
From RFM R 
INNER JOIN FLO F ON R.CUSTOMER_ID = F.master_id
WHERE (F.customer_value_total / F.order_num_total) > 250 
AND 
F.interested_in_categories_12 LIKE '%KADIN%' 
AND 
R.SEGMENT IN ('champions', 'loyal_customers')

# b. Erkek ve �o�uk �r�nlerinde %40'a yak�n indirim planlanmaktad�r. Bu indirimle ilgili kategorilerle ilgilenen ge�mi�te iyi m��terilerden olan ama uzun s�redir
# al��veri� yapmayan ve yeni gelen m��teriler �zel olarak hedef al�nmak isteniliyor. Uygun profildeki m��terilerin id'lerini getiriniz.

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










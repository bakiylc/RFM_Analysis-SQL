# RFM ile Müşteri Segmentasyonu (Customer Segmentation with RFM)
*******************************

### Iş Problemi (Business Problem)
- Bir parakende şirketi müşterilerini segmentlere ayırıp bu segmentlere göre pazarlama stratejileri belirlemek istiyor.
- Buradan yola çıkarak müşterilerin davranışlarını tanımlayacağız ve bu davranışlara göre gruplar oluşturacağız.

### Veri Seti Hikayesi
- Veri seti son alışverişlerini 2020 - 2021 yıllarında OmniChannel(hem online hem offline) olarak yapan müşterilerin geçmiş alışveriş davranışlarından elde edilen bilgilerden oluşmaktadır.
**********************************
### 20.000 gözlem, 13 değişken

- master_id: Eşsiz müşteri numarası
- order_channel : Alışveriş yapılan platforma ait hangi kanalın kullanıldığı (Android, ios, Desktop, Mobile, Offline)
- last_order_channel : En son alışverişin yapıldığı kanal
- first_order_date : Müşterinin yaptığı ilk alışveriş tarihi
- last_order_date : Müşterinin yaptığı son alışveriş tarihi
- last_order_date_online : Muşterinin online platformda yaptığı son alışveriş tarihi
- last_order_date_offline : Muşterinin offline platformda yaptığı son alışveriş tarihi
- order_num_total_ever_online : Müşterinin online platformda yaptığı toplam alışveriş sayısı
- order_num_total_ever_offline : Müşterinin offline'da yaptığı toplam alışveriş sayısı
- customer_value_total_ever_offline : Müşterinin offline alışverişlerinde ödediği toplam ücret
- customer_value_total_ever_online : Müşterinin online alışverişlerinde ödediği toplam ücret
- interested_in_categories_12 : Müşterinin son 12 ayda alışveriş yaptığı kategorilerin listesi
- store_type : 3 farklı companyi ifade eder. A company'sinden alışveriş yapan kişi B'dende yaptı ise A,B şeklinde yazılmıştır.

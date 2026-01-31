/* =====================================================
   NovaStore E-Ticaret Veri Yönetim Sistemi
   ===================================================== 
*/
/*
   =====================================================
   Kullanýlan ekstra özellikler (case study dýþýnda):
   - IsDeleted (soft delete): Customers ve Products tablolarýnda;
     kayýt silinmez, iþaretlenir; raporlarda WHERE IsDeleted = 0.
   - ON DELETE CASCADE: OrderDetails -> Orders FK'sýnda; sipariþ
     silinince detay satýrlarý da otomatik silinir.
   - trg_StockControl: OrderDetails INSERT sonrasý stok kontrolü
     ve stok düþürme; yetersiz stokta hata + ROLLBACK.
   ===================================================== 
*/

--------------------------------------------------------
-- BÖLÜM 1: VERÝ TABANI OLUÞTURMA
-- Yapýlan iþ: Yeni veritabaný oluþturulur ve aktif edilir.
-- GO ile batch sonlandýrýlýr; USE sonrasý da GO
-- gerekir ki sonraki CREATE TABLE ayný veritabanýnda çalýþsýn.
--------------------------------------------------------
CREATE DATABASE NovaStoreDB;
GO

USE NovaStoreDB;
GO

--------------------------------------------------------
-- A. Categories Tablosu (Kategoriler)
-- Yapýlan iþ: Ürün kategorilerini tutan ana tablo.
-- IDENTITY(1,1) otomatik artan PK; FK baðýmlý
-- tablolar (Products) oluþturulmadan önce mutlaka bu tablo
-- olmalý (referans bütünlüðü).
--------------------------------------------------------
CREATE TABLE Categories (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName VARCHAR(50) NOT NULL
);

--------------------------------------------------------
-- B. Customers Tablosu (Müþteriler)
-- Yapýlan iþ: Müþteri bilgileri; Email UNIQUE ile tekrarsýz.
-- IsDeleted = soft delete; kayýt silinmez, sadece
-- iþaretlenir, raporlarda WHERE IsDeleted = 0 ile filtre edilir.
--------------------------------------------------------
CREATE TABLE Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FullName VARCHAR(50),
    City VARCHAR(20),
    Email VARCHAR(100) UNIQUE,
    IsDeleted BIT DEFAULT 0
);

--------------------------------------------------------
-- C. Products Tablosu (Ürünler)
-- Yapýlan iþ: Ürün bilgileri; CategoryID ile Categories'e baðlý.
-- Stock DEFAULT 0; FK tanýmý CONSTRAINT adý ile
-- verilirse sonradan ALTER ile yönetmek kolaylaþýr.
--------------------------------------------------------
CREATE TABLE Products (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName VARCHAR(100) NOT NULL,
    Price DECIMAL(10,2),
    Stock INT DEFAULT 0,
    CategoryID INT,
    IsDeleted BIT DEFAULT 0,
    CONSTRAINT FK_Products_Categories
        FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID)
);

--------------------------------------------------------
-- D. Orders Tablosu (Sipariþler)
-- Yapýlan iþ: Sipariþ baþlýðý; CustomerID ile müþteriye baðlý.
-- OrderDate DEFAULT GETDATE() ile sipariþ aný
-- otomatik yazýlýr; TotalAmount uygulama veya trigger ile
-- OrderDetails'tan hesaplanabilir.
--------------------------------------------------------
CREATE TABLE Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT,
    OrderDate DATETIME DEFAULT GETDATE(),
    TotalAmount DECIMAL(10,2),
    CONSTRAINT FK_Orders_Customers
        FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

--------------------------------------------------------
-- E. OrderDetails Tablosu (Sipariþ Detaylarý - Ara Tablo)
-- Yapýlan iþ: Bir sipariþte hangi ürünten kaç adet; Orders
-- ile Products arasýnda çoktan-çoða iliþki kurar.
-- ON DELETE CASCADE ile sipariþ silinince
-- detaylarý da silinir; orphan kayýt kalmaz.
--------------------------------------------------------
CREATE TABLE OrderDetails (
    DetailID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT,
    ProductID INT,
    Quantity INT,
    CONSTRAINT FK_OrderDetails_Orders
        FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
        ON DELETE CASCADE,
    CONSTRAINT FK_OrderDetails_Products
        FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

--------------------------------------------------------
-- BÖLÜM 2: VERÝ GÝRÝÞÝ (INSERT)
-- Yapýlan iþ: Test ve raporlama için örnek veri eklenir.
-- Sýra önemli; önce Categories/Customers (FK
-- referansý yok), sonra Products/Orders, en son OrderDetails.
--------------------------------------------------------

-- Görev 1: Kategoriler (5 adet)
-- CategoryID IDENTITY olduðu için yazýlmaz; 1'den baþlar.
INSERT INTO Categories (CategoryName) VALUES
('Elektronik'),
('Giyim'),
('Kitap'),
('Kozmetik'),
('Ev ve Yaþam');

-- Görev 2: Ürünler (en az 10-12; CategoryID 1-5 kategorilere karþýlýk)
-- Stock sütununu yazmasaydýk DEFAULT 0 uygulanýrdý; 
-- burada her ürün için stok miktarýný elle yazdýk.
INSERT INTO Products (ProductName, Price, Stock, CategoryID) VALUES
('Laptop', 35000, 15, 1),
('Kulaklýk', 1500, 40, 1),
('T-Shirt', 500, 25, 2),
('Kot Pantolon', 1200, 10, 2),
('Roman Kitap', 200, 50, 3),
('Kiþisel Geliþim Kitabý', 180, 18, 3),
('Parfüm', 900, 12, 4),
('Cilt Kremi', 300, 35, 4),
('Mutfak Seti', 2500, 8, 5),
('Masa Lambasý', 700, 22, 5);

-- Görev 3: Müþteriler (5-6 adet)
-- Email UNIQUE; ayný e-posta ikinci kez eklenemez.
INSERT INTO Customers (FullName, City, Email) VALUES
('Ahmet Yýlmaz', 'Ýstanbul', 'ahmet@gmail.com'),
('Ayþe Demir', 'Ankara', 'ayse@gmail.com'),
('Mehmet Kaya', 'Ýzmir', 'mehmet@gmail.com'),
('Elif Çetin', 'Bursa', 'elif@gmail.com'),
('Can Aydýn', 'Antalya', 'can@gmail.com');

-- Görev 4: Sipariþler (en az 8-10; CustomerID 1-5)
-- OrderDate isterseniz DEFAULT býrakýlabilir; burada farklý tarihler verdik.
INSERT INTO Orders (CustomerID, OrderDate, TotalAmount) VALUES
(1, '2026-01-01', 36500),
(2, '2026-01-03', 1700),
(3, '2026-01-05', 200),
(1, '2026-01-10', 900),
(4, '2026-01-12', 300),
(5, '2026-01-15', 2500),
(2, '2026-01-18', 1200),
(3, '2026-01-20', 700);

-- Sipariþ Detaylarý (her sipariþe en az bir satýr)
-- OrderID, ProductID mevcut sipariþ ve ürün ID'leriyle eþleþmeli.
INSERT INTO OrderDetails (OrderID, ProductID, Quantity) VALUES
(1, 1, 1),
(1, 2, 1),
(2, 2, 1),
(3, 5, 1),
(4, 7, 1),
(5, 8, 1),
(6, 9, 1),
(7, 4, 1),
(8, 10, 1);

--------------------------------------------------------
-- BÖLÜM 3: SORGULAMA VE ANALÝZ (DQL - SELECT, JOIN, GROUP BY)
-- Yapýlan iþ: Yönetim raporlarý için örnek sorgular.
-- Alias (c, o, p) kullanmak okunabilirliði artýrýr.
--------------------------------------------------------

-- 1. Stok miktarý 20'den az olan ürünler
-- Yapýlan iþ: 20'den az stoklu ürünler listelenir; stok AZALAN sýrada.
-- IsDeleted = 0 ile silinmiþ iþaretli kayýtlar gelmez.
SELECT ProductName, Stock
FROM Products
WHERE Stock < 20 AND IsDeleted = 0
ORDER BY Stock DESC;

-- 2. Müþteri - Sipariþ bilgileri (hangi müþteri, hangi tarihte, ne kadar)
-- Yapýlan iþ: INNER JOIN ile sadece sipariþi olan müþteriler gelir.
-- Sipariþi olmayan müþteri gelmez.
SELECT c.FullName, c.City, o.OrderDate, o.TotalAmount
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE c.IsDeleted = 0;

-- 3. Belirli bir müþterinin aldýðý ürünler (isim, fiyat, kategori)
-- Yapýlan iþ: 5 tablo zincirleme JOIN; Customer -> Orders -> OrderDetails -> Products -> Categories.
-- FullName ile filtrelendi.
SELECT c.FullName, p.ProductName, p.Price, cat.CategoryName
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
JOIN Categories cat ON p.CategoryID = cat.CategoryID
WHERE c.FullName = 'Ahmet Yýlmaz';

-- 4. Kategori bazýnda ürün sayýsý (örn: Elektronik - 2 ürün)
-- Yapýlan iþ: LEFT JOIN ile ürünü olmayan kategoriler de 0 sayýyla gelir.
-- COUNT(p.ProductID) kullan; COUNT(*) ürünü olmayan kategoride 1 döner.
SELECT cat.CategoryName, COUNT(p.ProductID) AS UrunSayisi
FROM Categories cat
LEFT JOIN Products p ON cat.CategoryID = p.CategoryID
GROUP BY cat.CategoryName;

-- 5. Müþteri bazlý toplam ciro (en çok harcayan en üstte)
-- Yapýlan iþ: SUM + GROUP BY ile müþteri baþýna toplam; ORDER BY ile sýralama.
-- SELECT'ta olup aggregate olmayan her sütun GROUP BY'da olmalý.
SELECT c.FullName, SUM(o.TotalAmount) AS ToplamCiro
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.FullName
ORDER BY ToplamCiro DESC;

-- 6. Sipariþlerin üzerinden geçen gün sayýsý (bugüne göre)
-- Yapýlan iþ: DATEDIFF(DAY, baþlangýç, bitiþ) ile gün farký; GETDATE() bugün.
-- Parametre sýrasý (OrderDate, GETDATE()); ters yazýlýrsa negatif deðer çýkar.
SELECT OrderID, OrderDate,
DATEDIFF(DAY, OrderDate, GETDATE()) AS GecenGun
FROM Orders;
GO

--------------------------------------------------------
-- BÖLÜM 4: VIEW OLUÞTURMA
-- Yapýlan iþ: Müþteri adý, sipariþ tarihi, ürün adý, adet tek sorguda;
-- uzun JOIN'leri her seferinde yazmamak için VIEW saklanýr.
-- CREATE VIEW batch'in ilk ifadesi olmalý; bu yüzden üstte GO var.
--------------------------------------------------------
CREATE VIEW vw_SiparisOzet AS
SELECT
    c.FullName,
    o.OrderDate,
    p.ProductName,
    od.Quantity
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID;
GO

--------------------------------------------------------
-- Ekstra: TRIGGER (STOK KONTROLÜ)
-- Yapýlan iþ: OrderDetails'a INSERT olunca (1) stok yeterli mi kontrol;
-- yetersizse hata verip geri al, (2) yeterliyse stoku düþür.
-- "inserted" sanal tablosu trigger içinde yeni eklenen
-- satýrlarý tutar; CREATE TRIGGER batch'in ilk ifadesi olmalý (üstte GO).
--------------------------------------------------------
CREATE TRIGGER trg_StockControl
ON OrderDetails
AFTER INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Products p ON i.ProductID = p.ProductID
        WHERE p.Stock < i.Quantity
    )
    BEGIN
        RAISERROR ('Yetersiz stok!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    UPDATE p
    SET p.Stock = p.Stock - i.Quantity
    FROM Products p
    JOIN inserted i ON p.ProductID = i.ProductID;
END;

--------------------------------------------------------
-- BÖLÜM 4: BACKUP (YEDEKLEME)
-- Yapýlan iþ: NovaStoreDB veritabanýnýn tam yedeði C:\Yedek\ altýna alýnýr.
-- C:\Yedek\ klasörü sunucuda mevcut olmalý; yoksa
-- önce oluþturulmalý veya farklý bir yol (örn. proje klasörü) kullanýlabilir.
--------------------------------------------------------
BACKUP DATABASE NovaStoreDB
TO DISK = 'C:\Yedek\NovaStoreDB.bak';
GO
#创建图书表
CREATE TABLE labcheck.book (
  ID CHAR(8) NOT NULL,
  name VARCHAR(10) NOT NULL,
  author VARCHAR(10) NULL,
  price FLOAT UNSIGNED NULL DEFAULT 0,
  status INT UNSIGNED NULL DEFAULT 0 CHECK(status >=0 and status <=2),
  borrow_Times INT UNSIGNED NULL DEFAULT 0,
  reserve_Times INT UNSIGNED NULL DEFAULT 0,
  PRIMARY KEY (ID));

#创建读者表
CREATE TABLE labcheck.reader (
  ID CHAR(8) NOT NULL,
  name VARCHAR(10) NULL,
  age INT UNSIGNED NULL DEFAULT 0,
  address VARCHAR(20) NULL,
  PRIMARY KEY (ID));
  
#创建借阅表
CREATE TABLE labcheck.borrow (
  book_ID CHAR(8) NOT NULL,
  reader_ID CHAR(8) NOT NULL,
  borrow_Date DATE NOT NULL,
  return_Date DATE NULL DEFAULT NULL,
  PRIMARY KEY (book_ID, reader_ID, borrow_Date),
  INDEX readerid_idx (reader_ID ASC) VISIBLE,
  CONSTRAINT bookid
    FOREIGN KEY (book_ID)
    REFERENCES labcheck.book (ID)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT readerid
    FOREIGN KEY (reader_ID)
    REFERENCES labcheck.reader (ID)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);
DROP TRIGGER IF EXISTS labcheck.Borrow_BEFORE_INSERT;

DELIMITER $$
USE labcheck$$
CREATE DEFINER = CURRENT_USER TRIGGER labcheck.Borrow_BEFORE_INSERT BEFORE INSERT ON Borrow FOR EACH ROW
BEGIN
	update book set borrow_Times = borrow_Times +1 where book.id = new.book_ID;
END$$
DELIMITER ;

#创建预约表
CREATE TABLE labcheck.reserve (
  book_ID CHAR(8) NOT NULL,
  reader_ID CHAR(8) NOT NULL,
  reserve_Date DATE NOT NULL,
  take_Date DATE NULL,
  PRIMARY KEY (book_ID, reader_ID, reserve_Date));
DROP TRIGGER IF EXISTS labcheck.reserve_BEFORE_INSERT;

DELIMITER $$
USE labcheck$$
CREATE DEFINER = CURRENT_USER TRIGGER labcheck.reserve_BEFORE_INSERT BEFORE INSERT ON reserve FOR EACH ROW
BEGIN
	update book set reserve_Times = reserve_Times +1 where book.id = new.book_ID;
END$$
DELIMITER ;

#查询rose借过的书ID,书名,借期
select borrow.book_ID ,book.name ,borrow.borrow_Date FROM borrow ,book ,reader where (borrow.book_ID = book.ID) and borrow.reader_ID = reader.ID and reader.name = "Rose";

#查询没有借过书也没有预约过图书的读者
select distinct reader.ID , reader.name 
	FROM reader,borrow , reserve
    WHERE reader.ID not IN (select distinct reader_ID FROM borrow) and 
   reader.ID not IN (select distinct reader_ID FROM reserve);

#查询最多借阅的读者
select author from book group by author order by sum(borrow_Times) desc limit 1;

#查询目前借阅未还的书名中包含“MySQL”的的图书号和书名
select book.ID,book.name FROM book,borrow WHERE borrow.return_Date is null and borrow.book_ID = book.ID and book.name LIKE '%MySQL%';

#查询借阅图书数目超过 10 本的读者姓名
select reader.name from reader where reader.ID in (select reader_ID from borrow group by reader_ID having COUNT(*)> 2)


#select ID,name FROM book where author  like "John" ;

#查询没有借阅过任何一本 John 所著的图书的读者号和姓名
select reader.ID FROM reader WHERE reader.ID not IN (
	select distinct reader.ID FROM reader,borrow,book WHERE reader.id = borrow.reader_ID and borrow.book_ID  IN (select ID FROM book where author like "John" )
);

#查询 2022 年借阅图书数目排名前 10 名的读者号、姓名以及借阅图书数
select reader_ID,reader.name,COUNT(*) as borrow_TIME  from borrow,reader WHERE borrow.reader_ID = reader.ID and borrow_Date between "2022-01-01" and "2022-12-31" group by borrow.reader_ID order by COUNT(*) DESC LIMIT 10;

#创建读者借书视图
CREATE VIEW readerView(reader_ID,reader_Name,book_ID,book_Name,borrow_Date) AS
	select reader.ID,reader.name,book.ID,book.name,borrow.borrow_Date 
		From reader,book,borrow where reader.ID = borrow.reader_ID and book.ID = borrow.book_ID;

#查询最近一年所有读者的读者号以及所借阅的不同图书数
SELECT reader_ID,count(distinct book_ID)as borrow_count From readerview where borrow_Date >= date_sub(Date(now()),interval 1 year) group by reader_ID;
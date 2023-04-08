#select lab1.borrow.book_ID ,lab1.book.name ,lab1.borrow.borrow_Date FROM lab1.borrow ,lab1.book ,lab1.reader where (lab1.borrow.book_ID = lab1.book.ID) and lab1.borrow.reader_ID = lab1.reader.ID and lab1.reader.name = "Rose";


#select distinct lab1.reader.ID , lab1.reader.name 
#	FROM lab1.reader,lab1.borrow , lab1.reserve
#    WHERE lab1.reader.ID not IN (select distinct reader_ID FROM lab1.borrow) and 
#   lab1.reader.ID not IN (select distinct reader_ID FROM lab1.reserve);

#select book.author FROM lab1.book WHERE book.borrow_Times IN (SELECT max(book.borrow_Times) FROM book )  ;

#select book.ID,book.name FROM book,borrow WHERE borrow.return_Date is null and borrow.book_ID = book.ID and book.name LIKE '%MySQL%';

#select reader.name from reader where reader.ID in (select reader_ID from borrow group by reader_ID having COUNT(*)> 2)

#select ID,name FROM book where author  like "John" ;


#select reader.ID FROM reader WHERE reader.ID not IN (
#	select distinct reader.ID FROM reader,borrow,book WHERE reader.id = borrow.reader_ID and borrow.book_ID  IN (select ID FROM book where author like "John" )
#)

#select reader_ID,reader.name,COUNT(*) as borrow_TIME  from borrow,reader WHERE borrow.reader_ID = reader.ID group by borrow.reader_ID order by COUNT(*) DESC LIMIT 10;


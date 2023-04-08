SELECT * FROM reader_view;
SELECT * FROM reader_view WHERE borrow_time >= date_sub(curdate(),interval 1 year) ;
SELECT reader_id , count(distinct borrowed_books) as borrowed_numbers FROM reader_view WHERE borrow_time >= date_sub(curdate(),interval 1 year) GROUP BY reader_view.reader_ID
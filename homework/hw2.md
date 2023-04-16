1. 有两个关系（基本表）: S(A,B,C,D)和T(C,D,E,F),写出与下列关系代数查询等价的SQL表达式：

   1. $\sigma_{A=10}(S)$
   2. $\pi_{A,B}(S)$
   3. $S\Join {T}$
   4. $S\Join_{S.C=T.C}T$
   5. $S\Join_{A<E}T$
   6. $\pi_{C,D}(S)\times T$

   答案：

   ```mysql
   #1
   select * from S where S.A = 10;
   #2
   select A,B from S ;
   #3
   SELECT * FROM S natural join T;
   
   #4
   select * from S inner join T on S.C = T.C;
   #5
   select * from S,T where S.A < T.E;
   #6
   SELECT * FROM (select book_ID,reader_ID from borrow) AS P , book;
   ```

2. 基本表和视图的区别和联系是什么？

   区别：

   1. 基本表实际上储存了数据，而视图仅仅是一个虚拟的表，并没有储存任何数据，不占用物理空间，只保留了查询出来的结果
   2. 可以通过基本表访问并修改原始数据，而通过视图只能查看数据
   3. 基本表是一个独立的单位，而视图是一张或数张基本表通过查询和其他操作得到的，他不是独立的。

   联系：

   1. 基本表储存了原始数据，视图是由基本表通过查询和计算得到的，他的结构和数据都来源于基本表

3. 相关子查询和不相关子查询的区别是什么？请各举一个例子

   相关子查询的结果依赖父查询的结果，而无关子查询不依赖

   ```mysql
   #相关子查询
   SELECT *
   FROM stu
   WHERE not exists (SELECT * FROM course WHERE not exists(select *from sc where sno = stu.sno and cno = course.cno));
   
   
   #不相关子查询
   SELECT *
   FROM stu
   WHERE id IN (SELECT id FROM class WHERE cname = "database");
   
   ```

   
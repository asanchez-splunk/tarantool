#!/usr/bin/env ./tcltestrunner.lua

# 2001 September 15
#
# The author disclaims copyright to this source code.  In place of
# a legal notice, here is a blessing:
#
#    May you do good and not evil.
#    May you find forgiveness for yourself and forgive others.
#    May you share freely, never taking more than you give.
#
#***********************************************************************
# This file implements regression tests for SQLite library.  The
# focus of this file is testing aggregate functions and the
# GROUP BY and HAVING clauses of SELECT statements.
#
# $Id: select5.test,v 1.20 2008/08/21 14:15:59 drh Exp $

set testdir [file dirname $argv0]
source $testdir/tester.tcl

# Build some test data
#
execsql {
  DROP TABLE IF EXISTS t1;
  CREATE TABLE t1(x int primary key, y int);
  BEGIN;
}
for {set i 1} {$i<32} {incr i} {
  for {set j 0} {(1<<$j)<$i} {incr j} {}
  execsql "INSERT INTO t1 VALUES([expr {32-$i}],[expr {10-$j}])"
}
execsql {
  COMMIT
}

do_test select5-1.0 {
  execsql {SELECT DISTINCT y FROM t1 ORDER BY y}
} {5 6 7 8 9 10}

# Sort by an aggregate function.
#
do_test select5-1.1 {
  execsql {SELECT y, count(*) FROM t1 GROUP BY y ORDER BY y}
} {5 15 6 8 7 4 8 2 9 1 10 1}
do_test select5-1.2 {
  execsql {SELECT y, count(*) FROM t1 GROUP BY y ORDER BY count(*), y}
} {9 1 10 1 8 2 7 4 6 8 5 15}
do_test select5-1.3 {
  execsql {SELECT count(*), y FROM t1 GROUP BY y ORDER BY count(*), y}
} {1 9 1 10 2 8 4 7 8 6 15 5}

# Some error messages associated with aggregates and GROUP BY
#
do_test select5-2.1.1 {
  catchsql {
    SELECT y, count(*) FROM t1 GROUP BY z ORDER BY y
  }
} {1 {no such column: z}}
do_test select5-2.1.2 {
  catchsql {
    SELECT y, count(*) FROM t1 GROUP BY temp.t1.y ORDER BY y
  }
} {1 {no such column: temp.t1.y}}
do_test select5-2.2 {
  set v [catch {execsql {
    SELECT y, count(*) FROM t1 GROUP BY z(y) ORDER BY y
  }} msg]
  lappend v $msg
} {1 {no such function: z}}
do_test select5-2.3 {
  set v [catch {execsql {
    SELECT y, count(*) FROM t1 GROUP BY y HAVING count(*)<3 ORDER BY y
  }} msg]
  lappend v $msg
} {0 {8 2 9 1 10 1}}
do_test select5-2.4 {
  set v [catch {execsql {
    SELECT y, count(*) FROM t1 GROUP BY y HAVING z(y)<3 ORDER BY y
  }} msg]
  lappend v $msg
} {1 {no such function: z}}
do_test select5-2.5 {
  set v [catch {execsql {
    SELECT y, count(*) FROM t1 GROUP BY y HAVING count(*)<z ORDER BY y
  }} msg]
  lappend v $msg
} {1 {no such column: z}}

# Get the Agg function to rehash in vdbe.c
#
do_test select5-3.1 {
  execsql {
    SELECT x, count(*), avg(y) FROM t1 GROUP BY x HAVING x<4 ORDER BY x
  }
} {1 1 5.0 2 1 5.0 3 1 5.0}

# Run various aggregate functions when the count is zero.
#
do_test select5-4.1 {
  execsql {
    SELECT avg(x) FROM t1 WHERE x>100
  }
} {{}}
do_test select5-4.2 {
  execsql {
    SELECT count(x) FROM t1 WHERE x>100
  }
} {0}
do_test select5-4.3 {
  execsql {
    SELECT min(x) FROM t1 WHERE x>100
  }
} {{}}
do_test select5-4.4 {
  execsql {
    SELECT max(x) FROM t1 WHERE x>100
  }
} {{}}
do_test select5-4.5 {
  execsql {
    SELECT sum(x) FROM t1 WHERE x>100
  }
} {{}}

# Some tests for queries with a GROUP BY clause but no aggregate functions.
#
# Note: The query in test cases 5.1 through 5.5 are not legal SQL. So if the 
# implementation changes in the future and it returns different results,
# this is not such a big deal.
#
do_test select5-5.1 {
  execsql {
    DROP TABLE IF EXISTS t2;
    CREATE TABLE t2(id int primary key, a, b, c);
    INSERT INTO t2 VALUES(0, 1, 2, 3);
    INSERT INTO t2 VALUES(1, 1, 4, 5);
    INSERT INTO t2 VALUES(2, 6, 4, 7);
    CREATE INDEX t2_idx ON t2(a);
  } 
} {}
do_test select5-5.2 {
  execsql {
    SELECT a FROM t2 GROUP BY a;
  } 
} {1 6}
do_test select5-5.3 {
  execsql {
    SELECT a FROM t2 WHERE a>2 GROUP BY a;
  } 
} {6}
do_test select5-5.4 {
  execsql {
    SELECT a, b FROM t2 GROUP BY a, b;
  } 
} {1 2 1 4 6 4}
do_test select5-5.5 {
  execsql {
    SELECT a, b FROM t2 GROUP BY a;
  } 
} {1 4 6 4}

# Test rendering of columns for the GROUP BY clause.
#
do_test select5-5.11 {
  execsql {
    SELECT max(c), b*a, b, a FROM t2 GROUP BY b*a, b, a
  }
} {3 2 2 1 5 4 4 1 7 24 4 6}

# NULL compare equal to each other for the purposes of processing
# the GROUP BY clause.
#
do_test select5-6.1 {
  execsql {
    DROP TABLE IF EXISTS t3;
    CREATE TABLE t3(x primary key,y);
    INSERT INTO t3 VALUES(1,NULL);
    INSERT INTO t3 VALUES(2,NULL);
    INSERT INTO t3 VALUES(3,4);
    SELECT count(x), y FROM t3 GROUP BY y ORDER BY 1
  }
} {1 4 2 {}}
do_test select5-6.2 {
  execsql {
    DROP TABLE IF EXISTS t4;
    CREATE TABLE t4(id int primary key, x,y,z);
    INSERT INTO t4 VALUES(0,1,2,NULL);
    INSERT INTO t4 VALUES(1,2,3,NULL);
    INSERT INTO t4 VALUES(2,3,NULL,5);
    INSERT INTO t4 VALUES(3,4,NULL,6);
    INSERT INTO t4 VALUES(4,4,NULL,6);
    INSERT INTO t4 VALUES(5,5,NULL,NULL);
    INSERT INTO t4 VALUES(6,5,NULL,NULL);
    INSERT INTO t4 VALUES(7,6,7,8);
    SELECT max(x), count(x), y, z FROM t4 GROUP BY y, z ORDER BY 1
  }
} {1 1 2 {} 2 1 3 {} 3 1 {} 5 4 2 {} 6 5 2 {} {} 6 1 7 8}

do_test select5-7.2 {
  execsql {
    SELECT count(*), count(x) as cnt FROM t4 GROUP BY y ORDER BY cnt;
  }
} {1 1 1 1 1 1 5 5}

# See ticket #3324.
#
do_test select5-8.1 {
  execsql {
    DROP TABLE IF EXISTS t8a;
    DROP TABLE IF EXISTS t8b;
    CREATE TABLE t8a(id int primary key,a,b);
    CREATE TABLE t8b(rowid int primary key, x);
    INSERT INTO t8a VALUES(0, 'one', 1);
    INSERT INTO t8a VALUES(1, 'one', 2);
    INSERT INTO t8a VALUES(2, 'two', 3);
    INSERT INTO t8a VALUES(3, 'one', NULL);
    INSERT INTO t8b(rowid,x) VALUES(1,111);
    INSERT INTO t8b(rowid,x) VALUES(2,222);
    INSERT INTO t8b(rowid,x) VALUES(3,333);
    SELECT a, count(b) FROM t8a, t8b WHERE b=t8b.rowid GROUP BY a ORDER BY a;
  }
} {one 2 two 1}
do_test select5-8.2 {
  execsql {
    SELECT a, count(b) FROM t8a, t8b WHERE b=+t8b.rowid GROUP BY a ORDER BY a;
  }
} {one 2 two 1}
do_test select5-8.3 {
  execsql {
    SELECT t8a.a, count(t8a.b) FROM t8a, t8b WHERE t8a.b=t8b.rowid
     GROUP BY 1 ORDER BY 1;
  }
} {one 2 two 1}
do_test select5-8.4 {
  execsql {
    SELECT a, count(*) FROM t8a, t8b WHERE b=+t8b.rowid GROUP BY a ORDER BY a;
  }
} {one 2 two 1}

# MUST_WORK_TEST

# do_test select5-8.5 {
#   execsql {
#     SELECT a, count(b) FROM t8a, t8b WHERE b<x GROUP BY a ORDER BY a;
#   }
# } {one 6 two 3}
do_test select5-8.6 {
  execsql {
    SELECT a, count(t8a.b) FROM t8a, t8b WHERE b=t8b.rowid 
     GROUP BY a ORDER BY 2;
  }
} {two 1 one 2}
do_test select5-8.7 {
  execsql {
    SELECT a, count(b) FROM t8a, t8b GROUP BY a ORDER BY 2;
  }
} {two 3 one 6}
do_test select5-8.8 {
  execsql {
    SELECT a, count(*) FROM t8a, t8b GROUP BY a ORDER BY 2;
  }
} {two 3 one 9}



 
finish_test

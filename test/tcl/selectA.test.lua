#!/usr/bin/env ./tcltestrunner.lua

# 2008 June 24
#
# The author disclaims copyright to this source code.  In place of
# a legal notice, here is a blessing:
#
#    May you do good and not evil.
#    May you find forgiveness for yourself and forgive others.
#    May you share freely, never taking more than you give.
#
#***********************************************************************
# This file implements regression tests for SQLite library. 
#
# The focus of this file is testing the compound-SELECT merge
# optimization.  Or, in other words, making sure that all
# possible combinations of UNION, UNION ALL, EXCEPT, and
# INTERSECT work together with an ORDER BY clause (with or w/o
# explicit sort order and explicit collating secquites) and
# with and without optional LIMIT and OFFSET clauses.
#
# $Id: selectA.test,v 1.6 2008/08/21 14:24:29 drh Exp $

set testdir [file dirname $argv0]
source $testdir/tester.tcl
set testprefix selectA

ifcapable !compound {
  finish_test
  return
}

# MUST_WORK_TEST

# do_test selectA-1.0 {
#   execsql {
#     CREATE TABLE t1(a,b,c COLLATE NOCASE);
#     INSERT INTO t1 VALUES(1,'a','a');
#     INSERT INTO t1 VALUES(9.9, 'b', 'B');
#     INSERT INTO t1 VALUES(NULL, 'C', 'c');
#     INSERT INTO t1 VALUES('hello', 'd', 'D');
#     INSERT INTO t1 VALUES(x'616263', 'e', 'e');
#     SELECT * FROM t1;
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e}
# do_test selectA-1.1 {
#   execsql {
#     CREATE TABLE t2(x,y,z COLLATE NOCASE);
#     INSERT INTO t2 VALUES(NULL,'U','u');
#     INSERT INTO t2 VALUES('mad', 'Z', 'z');
#     INSERT INTO t2 VALUES(x'68617265', 'm', 'M');
#     INSERT INTO t2 VALUES(5.2e6, 'X', 'x');
#     INSERT INTO t2 VALUES(-23, 'Y', 'y');
#     SELECT * FROM t2;
#   }
# } {{} U u mad Z z hare m M 5200000.0 X x -23 Y y}
# do_test selectA-1.2 {
#   execsql {
#     CREATE TABLE t3(a,b,c COLLATE NOCASE);
#     INSERT INTO t3 SELECT * FROM t1;
#     INSERT INTO t3 SELECT * FROM t2;
#     INSERT INTO t3 SELECT * FROM t1;
#     INSERT INTO t3 SELECT * FROM t2;
#     INSERT INTO t3 SELECT * FROM t1;
#     INSERT INTO t3 SELECT * FROM t2;
#     SELECT count(*) FROM t3;
#   }
# } {30}

# do_test selectA-2.1 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION ALL SELECT x,y,z FROM t2
#     ORDER BY a,b,c
#   }
# } {{} C c {} U u -23 Y y 1 a a 9.9 b B 5200000.0 X x hello d D mad Z z abc e e hare m M}
# do_test selectA-2.1.1 {   # Ticket #3314
#   execsql {
#     SELECT t1.a, t1.b, t1.c FROM t1 UNION ALL SELECT x,y,z FROM t2
#     ORDER BY a,b,c
#   }
# } {{} C c {} U u -23 Y y 1 a a 9.9 b B 5200000.0 X x hello d D mad Z z abc e e hare m M}
# do_test selectA-2.1.2 {   # Ticket #3314
#   execsql {
#     SELECT a,b,c FROM t1 UNION ALL SELECT x,y,z FROM t2
#     ORDER BY t1.a, t1.b, t1.c
#   }
# } {{} C c {} U u -23 Y y 1 a a 9.9 b B 5200000.0 X x hello d D mad Z z abc e e hare m M}
# do_test selectA-2.2 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION ALL SELECT x,y,z FROM t2
#     ORDER BY a DESC,b,c
#   }
# } {hare m M abc e e mad Z z hello d D 5200000.0 X x 9.9 b B 1 a a -23 Y y {} C c {} U u}
# do_test selectA-2.3 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION ALL SELECT x,y,z FROM t2
#     ORDER BY a,c,b
#   }
# } {{} C c {} U u -23 Y y 1 a a 9.9 b B 5200000.0 X x hello d D mad Z z abc e e hare m M}
# do_test selectA-2.4 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION ALL SELECT x,y,z FROM t2
#     ORDER BY b,a,c
#   }
# } {{} C c {} U u 5200000.0 X x -23 Y y mad Z z 1 a a 9.9 b B hello d D abc e e hare m M}
# do_test selectA-2.5 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION ALL SELECT x,y,z FROM t2
#     ORDER BY b COLLATE NOCASE,a,c
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-2.6 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION ALL SELECT x,y,z FROM t2
#     ORDER BY b COLLATE NOCASE DESC,a,c
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u hare m M abc e e hello d D {} C c 9.9 b B 1 a a}
# do_test selectA-2.7 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION ALL SELECT x,y,z FROM t2
#     ORDER BY c,b,a
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-2.8 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION ALL SELECT x,y,z FROM t2
#     ORDER BY c,a,b
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-2.9 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION ALL SELECT x,y,z FROM t2
#     ORDER BY c DESC,a,b
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u hare m M abc e e hello d D {} C c 9.9 b B 1 a a}
# do_test selectA-2.10 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION ALL SELECT x,y,z FROM t2
#     ORDER BY c COLLATE BINARY DESC,a,b
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u abc e e {} C c 1 a a hare m M hello d D 9.9 b B}
# do_test selectA-2.11 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION ALL SELECT a,b,c FROM t1
#     ORDER BY a,b,c
#   }
# } {{} C c {} U u -23 Y y 1 a a 9.9 b B 5200000.0 X x hello d D mad Z z abc e e hare m M}
# do_test selectA-2.12 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION ALL SELECT a,b,c FROM t1
#     ORDER BY a DESC,b,c
#   }
# } {hare m M abc e e mad Z z hello d D 5200000.0 X x 9.9 b B 1 a a -23 Y y {} C c {} U u}
# do_test selectA-2.13 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION ALL SELECT a,b,c FROM t1
#     ORDER BY a,c,b
#   }
# } {{} C c {} U u -23 Y y 1 a a 9.9 b B 5200000.0 X x hello d D mad Z z abc e e hare m M}
# do_test selectA-2.14 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION ALL SELECT a,b,c FROM t1
#     ORDER BY b,a,c
#   }
# } {{} C c {} U u 5200000.0 X x -23 Y y mad Z z 1 a a 9.9 b B hello d D abc e e hare m M}
# do_test selectA-2.15 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION ALL SELECT a,b,c FROM t1
#     ORDER BY b COLLATE NOCASE,a,c
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-2.16 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION ALL SELECT a,b,c FROM t1
#     ORDER BY b COLLATE NOCASE DESC,a,c
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u hare m M abc e e hello d D {} C c 9.9 b B 1 a a}
# do_test selectA-2.17 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION ALL SELECT a,b,c FROM t1
#     ORDER BY c,b,a
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-2.18 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION ALL SELECT a,b,c FROM t1
#     ORDER BY c,a,b
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-2.19 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION ALL SELECT a,b,c FROM t1
#     ORDER BY c DESC,a,b
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u hare m M abc e e hello d D {} C c 9.9 b B 1 a a}
# do_test selectA-2.20 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION ALL SELECT a,b,c FROM t1
#     ORDER BY c COLLATE BINARY DESC,a,b
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u abc e e {} C c 1 a a hare m M hello d D 9.9 b B}
# do_test selectA-2.21 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION SELECT x,y,z FROM t2
#     ORDER BY a,b,c
#   }
# } {{} C c {} U u -23 Y y 1 a a 9.9 b B 5200000.0 X x hello d D mad Z z abc e e hare m M}
# do_test selectA-2.22 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION SELECT x,y,z FROM t2
#     ORDER BY a DESC,b,c
#   }
# } {hare m M abc e e mad Z z hello d D 5200000.0 X x 9.9 b B 1 a a -23 Y y {} C c {} U u}
# do_test selectA-2.23 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION SELECT x,y,z FROM t2
#     ORDER BY a,c,b
#   }
# } {{} C c {} U u -23 Y y 1 a a 9.9 b B 5200000.0 X x hello d D mad Z z abc e e hare m M}
# do_test selectA-2.24 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION SELECT x,y,z FROM t2
#     ORDER BY b,a,c
#   }
# } {{} C c {} U u 5200000.0 X x -23 Y y mad Z z 1 a a 9.9 b B hello d D abc e e hare m M}
# do_test selectA-2.25 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION SELECT x,y,z FROM t2
#     ORDER BY b COLLATE NOCASE,a,c
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-2.26 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION SELECT x,y,z FROM t2
#     ORDER BY b COLLATE NOCASE DESC,a,c
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u hare m M abc e e hello d D {} C c 9.9 b B 1 a a}
# do_test selectA-2.27 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION SELECT x,y,z FROM t2
#     ORDER BY c,b,a
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-2.28 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION SELECT x,y,z FROM t2
#     ORDER BY c,a,b
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-2.29 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION SELECT x,y,z FROM t2
#     ORDER BY c DESC,a,b
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u hare m M abc e e hello d D {} C c 9.9 b B 1 a a}
# do_test selectA-2.30 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION SELECT x,y,z FROM t2
#     ORDER BY c COLLATE BINARY DESC,a,b
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u abc e e {} C c 1 a a hare m M hello d D 9.9 b B}
# do_test selectA-2.31 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t1
#     ORDER BY a,b,c
#   }
# } {{} C c {} U u -23 Y y 1 a a 9.9 b B 5200000.0 X x hello d D mad Z z abc e e hare m M}
# do_test selectA-2.32 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t1
#     ORDER BY a DESC,b,c
#   }
# } {hare m M abc e e mad Z z hello d D 5200000.0 X x 9.9 b B 1 a a -23 Y y {} C c {} U u}
# do_test selectA-2.33 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t1
#     ORDER BY a,c,b
#   }
# } {{} C c {} U u -23 Y y 1 a a 9.9 b B 5200000.0 X x hello d D mad Z z abc e e hare m M}
# do_test selectA-2.34 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t1
#     ORDER BY b,a,c
#   }
# } {{} C c {} U u 5200000.0 X x -23 Y y mad Z z 1 a a 9.9 b B hello d D abc e e hare m M}
# do_test selectA-2.35 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t1
#     ORDER BY y COLLATE NOCASE,x,z
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-2.36 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t1
#     ORDER BY y COLLATE NOCASE DESC,x,z
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u hare m M abc e e hello d D {} C c 9.9 b B 1 a a}
# do_test selectA-2.37 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t1
#     ORDER BY c,b,a
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-2.38 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t1
#     ORDER BY c,a,b
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-2.39 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t1
#     ORDER BY c DESC,a,b
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u hare m M abc e e hello d D {} C c 9.9 b B 1 a a}
# do_test selectA-2.40 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t1
#     ORDER BY z COLLATE BINARY DESC,x,y
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u abc e e {} C c 1 a a hare m M hello d D 9.9 b B}
# do_test selectA-2.41 {
#   execsql {
#     SELECT a,b,c FROM t1 EXCEPT SELECT a,b,c FROM t1 WHERE b>='d'
#     ORDER BY a,b,c
#   }
# } {{} C c 1 a a 9.9 b B}
# do_test selectA-2.42 {
#   execsql {
#     SELECT a,b,c FROM t1 INTERSECT SELECT a,b,c FROM t1 WHERE b>='d'
#     ORDER BY a,b,c
#   }
# } {hello d D abc e e}
# do_test selectA-2.43 {
#   execsql {
#     SELECT a,b,c FROM t1 WHERE b>='d' INTERSECT SELECT a,b,c FROM t1
#     ORDER BY a,b,c
#   }
# } {hello d D abc e e}
# do_test selectA-2.44 {
#   execsql {
#     SELECT a,b,c FROM t1 EXCEPT SELECT a,b,c FROM t1 WHERE b<'d'
#     ORDER BY a,b,c
#   }
# } {hello d D abc e e}
# do_test selectA-2.45 {
#   execsql {
#     SELECT a,b,c FROM t1 INTERSECT SELECT a,b,c FROM t1 WHERE b<'d'
#     ORDER BY a,b,c
#   }
# } {{} C c 1 a a 9.9 b B}
# do_test selectA-2.46 {
#   execsql {
#     SELECT a,b,c FROM t1 WHERE b<'d' INTERSECT SELECT a,b,c FROM t1
#     ORDER BY a,b,c
#   }
# } {{} C c 1 a a 9.9 b B}
# do_test selectA-2.47 {
#   execsql {
#     SELECT a,b,c FROM t1 EXCEPT SELECT a,b,c FROM t1 WHERE b>='d'
#     ORDER BY a DESC
#   }
# } {9.9 b B 1 a a {} C c}
# do_test selectA-2.48 {
#   execsql {
#     SELECT a,b,c FROM t1 INTERSECT SELECT a,b,c FROM t1 WHERE b>='d'
#     ORDER BY a DESC
#   }
# } {abc e e hello d D}
# do_test selectA-2.49 {
#   execsql {
#     SELECT a,b,c FROM t1 WHERE b>='d' INTERSECT SELECT a,b,c FROM t1
#     ORDER BY a DESC
#   }
# } {abc e e hello d D}
# do_test selectA-2.50 {
#   execsql {
#     SELECT a,b,c FROM t1 EXCEPT SELECT a,b,c FROM t1 WHERE b<'d'
#     ORDER BY a DESC
#   }
# } {abc e e hello d D}
# do_test selectA-2.51 {
#   execsql {
#     SELECT a,b,c FROM t1 INTERSECT SELECT a,b,c FROM t1 WHERE b<'d'
#     ORDER BY a DESC
#   }
# } {9.9 b B 1 a a {} C c}
# do_test selectA-2.52 {
#   execsql {
#     SELECT a,b,c FROM t1 WHERE b<'d' INTERSECT SELECT a,b,c FROM t1
#     ORDER BY a DESC
#   }
# } {9.9 b B 1 a a {} C c}
# do_test selectA-2.53 {
#   execsql {
#     SELECT a,b,c FROM t1 EXCEPT SELECT a,b,c FROM t1 WHERE b>='d'
#     ORDER BY b, a DESC
#   }
# } {{} C c 1 a a 9.9 b B}
# do_test selectA-2.54 {
#   execsql {
#     SELECT a,b,c FROM t1 INTERSECT SELECT a,b,c FROM t1 WHERE b>='d'
#     ORDER BY b
#   }
# } {hello d D abc e e}
# do_test selectA-2.55 {
#   execsql {
#     SELECT a,b,c FROM t1 WHERE b>='d' INTERSECT SELECT a,b,c FROM t1
#     ORDER BY b DESC, c
#   }
# } {abc e e hello d D}
# do_test selectA-2.56 {
#   execsql {
#     SELECT a,b,c FROM t1 EXCEPT SELECT a,b,c FROM t1 WHERE b<'d'
#     ORDER BY b, c DESC, a
#   }
# } {hello d D abc e e}
# do_test selectA-2.57 {
#   execsql {
#     SELECT a,b,c FROM t1 INTERSECT SELECT a,b,c FROM t1 WHERE b<'d'
#     ORDER BY b COLLATE NOCASE
#   }
# } {1 a a 9.9 b B {} C c}
# do_test selectA-2.58 {
#   execsql {
#     SELECT a,b,c FROM t1 WHERE b<'d' INTERSECT SELECT a,b,c FROM t1
#     ORDER BY b
#   }
# } {{} C c 1 a a 9.9 b B}
# do_test selectA-2.59 {
#   execsql {
#     SELECT a,b,c FROM t1 EXCEPT SELECT a,b,c FROM t1 WHERE b>='d'
#     ORDER BY c, a DESC
#   }
# } {1 a a 9.9 b B {} C c}
# do_test selectA-2.60 {
#   execsql {
#     SELECT a,b,c FROM t1 INTERSECT SELECT a,b,c FROM t1 WHERE b>='d'
#     ORDER BY c
#   }
# } {hello d D abc e e}
# do_test selectA-2.61 {
#   execsql {
#     SELECT a,b,c FROM t1 WHERE b>='d' INTERSECT SELECT a,b,c FROM t1
#     ORDER BY c COLLATE BINARY, b DESC, c, a, b, c, a, b, c
#   }
# } {hello d D abc e e}
# do_test selectA-2.62 {
#   execsql {
#     SELECT a,b,c FROM t1 EXCEPT SELECT a,b,c FROM t1 WHERE b<'d'
#     ORDER BY c DESC, a
#   }
# } {abc e e hello d D}
# do_test selectA-2.63 {
#   execsql {
#     SELECT a,b,c FROM t1 INTERSECT SELECT a,b,c FROM t1 WHERE b<'d'
#     ORDER BY c COLLATE NOCASE
#   }
# } {1 a a 9.9 b B {} C c}
# do_test selectA-2.64 {
#   execsql {
#     SELECT a,b,c FROM t1 WHERE b<'d' INTERSECT SELECT a,b,c FROM t1
#     ORDER BY c
#   }
# } {1 a a 9.9 b B {} C c}
# do_test selectA-2.65 {
#   execsql {
#     SELECT a,b,c FROM t3 INTERSECT SELECT a,b,c FROM t1 WHERE b<'d'
#     ORDER BY c COLLATE NOCASE
#   }
# } {1 a a 9.9 b B {} C c}
# do_test selectA-2.66 {
#   execsql {
#     SELECT a,b,c FROM t1 WHERE b<'d' INTERSECT SELECT a,b,c FROM t3
#     ORDER BY c
#   }
# } {1 a a 9.9 b B {} C c}
# do_test selectA-2.67 {
#   execsql {
#     SELECT a,b,c FROM t1 EXCEPT SELECT a,b,c FROM t3 WHERE b<'d'
#     ORDER BY c DESC, a
#   }
# } {abc e e hello d D}
# do_test selectA-2.68 {
#   execsql {
#     SELECT a,b,c FROM t1 EXCEPT SELECT a,b,c FROM t1 WHERE b<'d'
#     INTERSECT SELECT a,b,c FROM t3
#     EXCEPT SELECT b,c,a FROM t3
#     ORDER BY c DESC, a
#   }
# } {abc e e hello d D}
# do_test selectA-2.69 {
#   execsql {
#     SELECT a,b,c FROM t1 INTERSECT SELECT a,b,c FROM t1 WHERE b<'d'
#     INTERSECT SELECT a,b,c FROM t3
#     EXCEPT SELECT b,c,a FROM t3
#     ORDER BY c COLLATE NOCASE
#   }
# } {1 a a 9.9 b B {} C c}
# do_test selectA-2.70 {
#   execsql {
#     SELECT a,b,c FROM t1 WHERE b<'d' INTERSECT SELECT a,b,c FROM t1
#     INTERSECT SELECT a,b,c FROM t3
#     EXCEPT SELECT b,c,a FROM t3
#     ORDER BY c
#   }
# } {1 a a 9.9 b B {} C c}
# do_test selectA-2.71 {
#   execsql {
#     SELECT a,b,c FROM t1 WHERE b<'d'
#     INTERSECT SELECT a,b,c FROM t1
#     INTERSECT SELECT a,b,c FROM t3
#     EXCEPT SELECT b,c,a FROM t3
#     INTERSECT SELECT a,b,c FROM t1
#     EXCEPT SELECT x,y,z FROM t2
#     INTERSECT SELECT a,b,c FROM t3
#     EXCEPT SELECT y,x,z FROM t2
#     INTERSECT SELECT a,b,c FROM t1
#     EXCEPT SELECT c,b,a FROM t3
#     ORDER BY c
#   }
# } {1 a a 9.9 b B {} C c}
# do_test selectA-2.72 {
#   execsql {
#     SELECT a,b,c FROM t3 UNION SELECT x,y,z FROM t2
#     ORDER BY a,b,c
#   }
# } {{} C c {} U u -23 Y y 1 a a 9.9 b B 5200000.0 X x hello d D mad Z z abc e e hare m M}
# do_test selectA-2.73 {
#   execsql {
#     SELECT a,b,c FROM t3 UNION SELECT x,y,z FROM t2
#     ORDER BY a DESC,b,c
#   }
# } {hare m M abc e e mad Z z hello d D 5200000.0 X x 9.9 b B 1 a a -23 Y y {} C c {} U u}
# do_test selectA-2.74 {
#   execsql {
#     SELECT a,b,c FROM t3 UNION SELECT x,y,z FROM t2
#     ORDER BY a,c,b
#   }
# } {{} C c {} U u -23 Y y 1 a a 9.9 b B 5200000.0 X x hello d D mad Z z abc e e hare m M}
# do_test selectA-2.75 {
#   execsql {
#     SELECT a,b,c FROM t3 UNION SELECT x,y,z FROM t2
#     ORDER BY b,a,c
#   }
# } {{} C c {} U u 5200000.0 X x -23 Y y mad Z z 1 a a 9.9 b B hello d D abc e e hare m M}
# do_test selectA-2.76 {
#   execsql {
#     SELECT a,b,c FROM t3 UNION SELECT x,y,z FROM t2
#     ORDER BY b COLLATE NOCASE,a,c
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-2.77 {
#   execsql {
#     SELECT a,b,c FROM t3 UNION SELECT x,y,z FROM t2
#     ORDER BY b COLLATE NOCASE DESC,a,c
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u hare m M abc e e hello d D {} C c 9.9 b B 1 a a}
# do_test selectA-2.78 {
#   execsql {
#     SELECT a,b,c FROM t3 UNION SELECT x,y,z FROM t2
#     ORDER BY c,b,a
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-2.79 {
#   execsql {
#     SELECT a,b,c FROM t3 UNION SELECT x,y,z FROM t2
#     ORDER BY c,a,b
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-2.80 {
#   execsql {
#     SELECT a,b,c FROM t3 UNION SELECT x,y,z FROM t2
#     ORDER BY c DESC,a,b
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u hare m M abc e e hello d D {} C c 9.9 b B 1 a a}
# do_test selectA-2.81 {
#   execsql {
#     SELECT a,b,c FROM t3 UNION SELECT x,y,z FROM t2
#     ORDER BY c COLLATE BINARY DESC,a,b
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u abc e e {} C c 1 a a hare m M hello d D 9.9 b B}
# do_test selectA-2.82 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t3
#     ORDER BY a,b,c
#   }
# } {{} C c {} U u -23 Y y 1 a a 9.9 b B 5200000.0 X x hello d D mad Z z abc e e hare m M}
# do_test selectA-2.83 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t3
#     ORDER BY a DESC,b,c
#   }
# } {hare m M abc e e mad Z z hello d D 5200000.0 X x 9.9 b B 1 a a -23 Y y {} C c {} U u}
# do_test selectA-2.84 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t3
#     ORDER BY a,c,b
#   }
# } {{} C c {} U u -23 Y y 1 a a 9.9 b B 5200000.0 X x hello d D mad Z z abc e e hare m M}
# do_test selectA-2.85 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t3
#     ORDER BY b,a,c
#   }
# } {{} C c {} U u 5200000.0 X x -23 Y y mad Z z 1 a a 9.9 b B hello d D abc e e hare m M}
# do_test selectA-2.86 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t3
#     ORDER BY y COLLATE NOCASE,x,z
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-2.87 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t3
#     ORDER BY y COLLATE NOCASE DESC,x,z
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u hare m M abc e e hello d D {} C c 9.9 b B 1 a a}
# do_test selectA-2.88 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t3
#     ORDER BY c,b,a
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-2.89 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t3
#     ORDER BY c,a,b
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-2.90 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t3
#     ORDER BY c DESC,a,b
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u hare m M abc e e hello d D {} C c 9.9 b B 1 a a}
# do_test selectA-2.91 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t3
#     ORDER BY z COLLATE BINARY DESC,x,y
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u abc e e {} C c 1 a a hare m M hello d D 9.9 b B}
# do_test selectA-2.92 {
#   execsql {
#     SELECT x,y,z FROM t2
#     INTERSECT SELECT a,b,c FROM t3
#     EXCEPT SELECT c,b,a FROM t1
#     UNION SELECT a,b,c FROM t3
#     INTERSECT SELECT a,b,c FROM t3
#     EXCEPT SELECT c,b,a FROM t1
#     UNION SELECT a,b,c FROM t3
#     ORDER BY y COLLATE NOCASE DESC,x,z
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u hare m M abc e e hello d D {} C c 9.9 b B 1 a a}
# do_test selectA-2.93 {
#   execsql {
#     SELECT upper((SELECT c FROM t1 UNION SELECT z FROM t2 ORDER BY 1));
#   }
# } {A}
# do_test selectA-2.94 {
#   execsql {
#     SELECT lower((SELECT c FROM t1 UNION ALL SELECT z FROM t2 ORDER BY 1));
#   }
# } {a}
# do_test selectA-2.95 {
#   execsql {
#     SELECT lower((SELECT c FROM t1 INTERSECT SELECT z FROM t2 ORDER BY 1));
#   }
# } {{}}
# do_test selectA-2.96 {
#   execsql {
#     SELECT lower((SELECT z FROM t2 EXCEPT SELECT c FROM t1 ORDER BY 1));
#   }
# } {m}


# do_test selectA-3.0 {
#   execsql {
#     CREATE UNIQUE INDEX t1a ON t1(a);
#     CREATE UNIQUE INDEX t1b ON t1(b);
#     CREATE UNIQUE INDEX t1c ON t1(c);
#     CREATE UNIQUE INDEX t2x ON t2(x);
#     CREATE UNIQUE INDEX t2y ON t2(y);
#     CREATE UNIQUE INDEX t2z ON t2(z);
#     SELECT name FROM sqlite_master WHERE type='index'
#   }
# } {t1a t1b t1c t2x t2y t2z}
# do_test selectA-3.1 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION ALL SELECT x,y,z FROM t2
#     ORDER BY a,b,c
#   }
# } {{} C c {} U u -23 Y y 1 a a 9.9 b B 5200000.0 X x hello d D mad Z z abc e e hare m M}
# do_test selectA-3.1.1 {  # Ticket #3314
#   execsql {
#     SELECT t1.a,b,t1.c FROM t1 UNION ALL SELECT x,y,z FROM t2
#     ORDER BY a,t1.b,t1.c
#   }
# } {{} C c {} U u -23 Y y 1 a a 9.9 b B 5200000.0 X x hello d D mad Z z abc e e hare m M}
# do_test selectA-3.2 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION ALL SELECT x,y,z FROM t2
#     ORDER BY a DESC,b,c
#   }
# } {hare m M abc e e mad Z z hello d D 5200000.0 X x 9.9 b B 1 a a -23 Y y {} C c {} U u}
# do_test selectA-3.3 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION ALL SELECT x,y,z FROM t2
#     ORDER BY a,c,b
#   }
# } {{} C c {} U u -23 Y y 1 a a 9.9 b B 5200000.0 X x hello d D mad Z z abc e e hare m M}
# do_test selectA-3.4 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION ALL SELECT x,y,z FROM t2
#     ORDER BY b,a,c
#   }
# } {{} C c {} U u 5200000.0 X x -23 Y y mad Z z 1 a a 9.9 b B hello d D abc e e hare m M}
# do_test selectA-3.5 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION ALL SELECT x,y,z FROM t2
#     ORDER BY b COLLATE NOCASE,a,c
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-3.6 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION ALL SELECT x,y,z FROM t2
#     ORDER BY b COLLATE NOCASE DESC,a,c
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u hare m M abc e e hello d D {} C c 9.9 b B 1 a a}
# do_test selectA-3.7 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION ALL SELECT x,y,z FROM t2
#     ORDER BY c,b,a
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-3.8 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION ALL SELECT x,y,z FROM t2
#     ORDER BY c,a,b
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-3.9 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION ALL SELECT x,y,z FROM t2
#     ORDER BY c DESC,a,b
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u hare m M abc e e hello d D {} C c 9.9 b B 1 a a}
# do_test selectA-3.10 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION ALL SELECT x,y,z FROM t2
#     ORDER BY c COLLATE BINARY DESC,a,b
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u abc e e {} C c 1 a a hare m M hello d D 9.9 b B}
# do_test selectA-3.11 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION ALL SELECT a,b,c FROM t1
#     ORDER BY a,b,c
#   }
# } {{} C c {} U u -23 Y y 1 a a 9.9 b B 5200000.0 X x hello d D mad Z z abc e e hare m M}
# do_test selectA-3.12 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION ALL SELECT a,b,c FROM t1
#     ORDER BY a DESC,b,c
#   }
# } {hare m M abc e e mad Z z hello d D 5200000.0 X x 9.9 b B 1 a a -23 Y y {} C c {} U u}
# do_test selectA-3.13 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION ALL SELECT a,b,c FROM t1
#     ORDER BY a,c,b
#   }
# } {{} C c {} U u -23 Y y 1 a a 9.9 b B 5200000.0 X x hello d D mad Z z abc e e hare m M}
# do_test selectA-3.14 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION ALL SELECT a,b,c FROM t1
#     ORDER BY b,a,c
#   }
# } {{} C c {} U u 5200000.0 X x -23 Y y mad Z z 1 a a 9.9 b B hello d D abc e e hare m M}
# do_test selectA-3.15 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION ALL SELECT a,b,c FROM t1
#     ORDER BY b COLLATE NOCASE,a,c
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-3.16 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION ALL SELECT a,b,c FROM t1
#     ORDER BY b COLLATE NOCASE DESC,a,c
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u hare m M abc e e hello d D {} C c 9.9 b B 1 a a}
# do_test selectA-3.17 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION ALL SELECT a,b,c FROM t1
#     ORDER BY c,b,a
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-3.18 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION ALL SELECT a,b,c FROM t1
#     ORDER BY c,a,b
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-3.19 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION ALL SELECT a,b,c FROM t1
#     ORDER BY c DESC,a,b
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u hare m M abc e e hello d D {} C c 9.9 b B 1 a a}
# do_test selectA-3.20 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION ALL SELECT a,b,c FROM t1
#     ORDER BY c COLLATE BINARY DESC,a,b
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u abc e e {} C c 1 a a hare m M hello d D 9.9 b B}
# do_test selectA-3.21 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION SELECT x,y,z FROM t2
#     ORDER BY a,b,c
#   }
# } {{} C c {} U u -23 Y y 1 a a 9.9 b B 5200000.0 X x hello d D mad Z z abc e e hare m M}
# do_test selectA-3.22 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION SELECT x,y,z FROM t2
#     ORDER BY a DESC,b,c
#   }
# } {hare m M abc e e mad Z z hello d D 5200000.0 X x 9.9 b B 1 a a -23 Y y {} C c {} U u}
# do_test selectA-3.23 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION SELECT x,y,z FROM t2
#     ORDER BY a,c,b
#   }
# } {{} C c {} U u -23 Y y 1 a a 9.9 b B 5200000.0 X x hello d D mad Z z abc e e hare m M}
# do_test selectA-3.24 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION SELECT x,y,z FROM t2
#     ORDER BY b,a,c
#   }
# } {{} C c {} U u 5200000.0 X x -23 Y y mad Z z 1 a a 9.9 b B hello d D abc e e hare m M}
# do_test selectA-3.25 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION SELECT x,y,z FROM t2
#     ORDER BY b COLLATE NOCASE,a,c
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-3.26 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION SELECT x,y,z FROM t2
#     ORDER BY b COLLATE NOCASE DESC,a,c
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u hare m M abc e e hello d D {} C c 9.9 b B 1 a a}
# do_test selectA-3.27 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION SELECT x,y,z FROM t2
#     ORDER BY c,b,a
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-3.28 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION SELECT x,y,z FROM t2
#     ORDER BY c,a,b
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-3.29 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION SELECT x,y,z FROM t2
#     ORDER BY c DESC,a,b
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u hare m M abc e e hello d D {} C c 9.9 b B 1 a a}
# do_test selectA-3.30 {
#   execsql {
#     SELECT a,b,c FROM t1 UNION SELECT x,y,z FROM t2
#     ORDER BY c COLLATE BINARY DESC,a,b
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u abc e e {} C c 1 a a hare m M hello d D 9.9 b B}
# do_test selectA-3.31 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t1
#     ORDER BY a,b,c
#   }
# } {{} C c {} U u -23 Y y 1 a a 9.9 b B 5200000.0 X x hello d D mad Z z abc e e hare m M}
# do_test selectA-3.32 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t1
#     ORDER BY a DESC,b,c
#   }
# } {hare m M abc e e mad Z z hello d D 5200000.0 X x 9.9 b B 1 a a -23 Y y {} C c {} U u}
# do_test selectA-3.33 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t1
#     ORDER BY a,c,b
#   }
# } {{} C c {} U u -23 Y y 1 a a 9.9 b B 5200000.0 X x hello d D mad Z z abc e e hare m M}
# do_test selectA-3.34 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t1
#     ORDER BY b,a,c
#   }
# } {{} C c {} U u 5200000.0 X x -23 Y y mad Z z 1 a a 9.9 b B hello d D abc e e hare m M}
# do_test selectA-3.35 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t1
#     ORDER BY y COLLATE NOCASE,x,z
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-3.36 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t1
#     ORDER BY y COLLATE NOCASE DESC,x,z
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u hare m M abc e e hello d D {} C c 9.9 b B 1 a a}
# do_test selectA-3.37 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t1
#     ORDER BY c,b,a
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-3.38 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t1
#     ORDER BY c,a,b
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-3.39 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t1
#     ORDER BY c DESC,a,b
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u hare m M abc e e hello d D {} C c 9.9 b B 1 a a}
# do_test selectA-3.40 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t1
#     ORDER BY z COLLATE BINARY DESC,x,y
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u abc e e {} C c 1 a a hare m M hello d D 9.9 b B}
# do_test selectA-3.41 {
#   execsql {
#     SELECT a,b,c FROM t1 EXCEPT SELECT a,b,c FROM t1 WHERE b>='d'
#     ORDER BY a,b,c
#   }
# } {{} C c 1 a a 9.9 b B}
# do_test selectA-3.42 {
#   execsql {
#     SELECT a,b,c FROM t1 INTERSECT SELECT a,b,c FROM t1 WHERE b>='d'
#     ORDER BY a,b,c
#   }
# } {hello d D abc e e}
# do_test selectA-3.43 {
#   execsql {
#     SELECT a,b,c FROM t1 WHERE b>='d' INTERSECT SELECT a,b,c FROM t1
#     ORDER BY a,b,c
#   }
# } {hello d D abc e e}
# do_test selectA-3.44 {
#   execsql {
#     SELECT a,b,c FROM t1 EXCEPT SELECT a,b,c FROM t1 WHERE b<'d'
#     ORDER BY a,b,c
#   }
# } {hello d D abc e e}
# do_test selectA-3.45 {
#   execsql {
#     SELECT a,b,c FROM t1 INTERSECT SELECT a,b,c FROM t1 WHERE b<'d'
#     ORDER BY a,b,c
#   }
# } {{} C c 1 a a 9.9 b B}
# do_test selectA-3.46 {
#   execsql {
#     SELECT a,b,c FROM t1 WHERE b<'d' INTERSECT SELECT a,b,c FROM t1
#     ORDER BY a,b,c
#   }
# } {{} C c 1 a a 9.9 b B}
# do_test selectA-3.47 {
#   execsql {
#     SELECT a,b,c FROM t1 EXCEPT SELECT a,b,c FROM t1 WHERE b>='d'
#     ORDER BY a DESC
#   }
# } {9.9 b B 1 a a {} C c}
# do_test selectA-3.48 {
#   execsql {
#     SELECT a,b,c FROM t1 INTERSECT SELECT a,b,c FROM t1 WHERE b>='d'
#     ORDER BY a DESC
#   }
# } {abc e e hello d D}
# do_test selectA-3.49 {
#   execsql {
#     SELECT a,b,c FROM t1 WHERE b>='d' INTERSECT SELECT a,b,c FROM t1
#     ORDER BY a DESC
#   }
# } {abc e e hello d D}
# do_test selectA-3.50 {
#   execsql {
#     SELECT a,b,c FROM t1 EXCEPT SELECT a,b,c FROM t1 WHERE b<'d'
#     ORDER BY a DESC
#   }
# } {abc e e hello d D}
# do_test selectA-3.51 {
#   execsql {
#     SELECT a,b,c FROM t1 INTERSECT SELECT a,b,c FROM t1 WHERE b<'d'
#     ORDER BY a DESC
#   }
# } {9.9 b B 1 a a {} C c}
# do_test selectA-3.52 {
#   execsql {
#     SELECT a,b,c FROM t1 WHERE b<'d' INTERSECT SELECT a,b,c FROM t1
#     ORDER BY a DESC
#   }
# } {9.9 b B 1 a a {} C c}
# do_test selectA-3.53 {
#   execsql {
#     SELECT a,b,c FROM t1 EXCEPT SELECT a,b,c FROM t1 WHERE b>='d'
#     ORDER BY b, a DESC
#   }
# } {{} C c 1 a a 9.9 b B}
# do_test selectA-3.54 {
#   execsql {
#     SELECT a,b,c FROM t1 INTERSECT SELECT a,b,c FROM t1 WHERE b>='d'
#     ORDER BY b
#   }
# } {hello d D abc e e}
# do_test selectA-3.55 {
#   execsql {
#     SELECT a,b,c FROM t1 WHERE b>='d' INTERSECT SELECT a,b,c FROM t1
#     ORDER BY b DESC, c
#   }
# } {abc e e hello d D}
# do_test selectA-3.56 {
#   execsql {
#     SELECT a,b,c FROM t1 EXCEPT SELECT a,b,c FROM t1 WHERE b<'d'
#     ORDER BY b, c DESC, a
#   }
# } {hello d D abc e e}
# do_test selectA-3.57 {
#   execsql {
#     SELECT a,b,c FROM t1 INTERSECT SELECT a,b,c FROM t1 WHERE b<'d'
#     ORDER BY b COLLATE NOCASE
#   }
# } {1 a a 9.9 b B {} C c}
# do_test selectA-3.58 {
#   execsql {
#     SELECT a,b,c FROM t1 WHERE b<'d' INTERSECT SELECT a,b,c FROM t1
#     ORDER BY b
#   }
# } {{} C c 1 a a 9.9 b B}
# do_test selectA-3.59 {
#   execsql {
#     SELECT a,b,c FROM t1 EXCEPT SELECT a,b,c FROM t1 WHERE b>='d'
#     ORDER BY c, a DESC
#   }
# } {1 a a 9.9 b B {} C c}
# do_test selectA-3.60 {
#   execsql {
#     SELECT a,b,c FROM t1 INTERSECT SELECT a,b,c FROM t1 WHERE b>='d'
#     ORDER BY c
#   }
# } {hello d D abc e e}
# do_test selectA-3.61 {
#   execsql {
#     SELECT a,b,c FROM t1 WHERE b>='d' INTERSECT SELECT a,b,c FROM t1
#     ORDER BY c COLLATE BINARY, b DESC, c, a, b, c, a, b, c
#   }
# } {hello d D abc e e}
# do_test selectA-3.62 {
#   execsql {
#     SELECT a,b,c FROM t1 EXCEPT SELECT a,b,c FROM t1 WHERE b<'d'
#     ORDER BY c DESC, a
#   }
# } {abc e e hello d D}
# do_test selectA-3.63 {
#   execsql {
#     SELECT a,b,c FROM t1 INTERSECT SELECT a,b,c FROM t1 WHERE b<'d'
#     ORDER BY c COLLATE NOCASE
#   }
# } {1 a a 9.9 b B {} C c}
# do_test selectA-3.64 {
#   execsql {
#     SELECT a,b,c FROM t1 WHERE b<'d' INTERSECT SELECT a,b,c FROM t1
#     ORDER BY c
#   }
# } {1 a a 9.9 b B {} C c}
# do_test selectA-3.65 {
#   execsql {
#     SELECT a,b,c FROM t3 INTERSECT SELECT a,b,c FROM t1 WHERE b<'d'
#     ORDER BY c COLLATE NOCASE
#   }
# } {1 a a 9.9 b B {} C c}
# do_test selectA-3.66 {
#   execsql {
#     SELECT a,b,c FROM t1 WHERE b<'d' INTERSECT SELECT a,b,c FROM t3
#     ORDER BY c
#   }
# } {1 a a 9.9 b B {} C c}
# do_test selectA-3.67 {
#   execsql {
#     SELECT a,b,c FROM t1 EXCEPT SELECT a,b,c FROM t3 WHERE b<'d'
#     ORDER BY c DESC, a
#   }
# } {abc e e hello d D}
# do_test selectA-3.68 {
#   execsql {
#     SELECT a,b,c FROM t1 EXCEPT SELECT a,b,c FROM t1 WHERE b<'d'
#     INTERSECT SELECT a,b,c FROM t3
#     EXCEPT SELECT b,c,a FROM t3
#     ORDER BY c DESC, a
#   }
# } {abc e e hello d D}
# do_test selectA-3.69 {
#   execsql {
#     SELECT a,b,c FROM t1 INTERSECT SELECT a,b,c FROM t1 WHERE b<'d'
#     INTERSECT SELECT a,b,c FROM t3
#     EXCEPT SELECT b,c,a FROM t3
#     ORDER BY c COLLATE NOCASE
#   }
# } {1 a a 9.9 b B {} C c}
# do_test selectA-3.70 {
#   execsql {
#     SELECT a,b,c FROM t1 WHERE b<'d' INTERSECT SELECT a,b,c FROM t1
#     INTERSECT SELECT a,b,c FROM t3
#     EXCEPT SELECT b,c,a FROM t3
#     ORDER BY c
#   }
# } {1 a a 9.9 b B {} C c}
# do_test selectA-3.71 {
#   execsql {
#     SELECT a,b,c FROM t1 WHERE b<'d'
#     INTERSECT SELECT a,b,c FROM t1
#     INTERSECT SELECT a,b,c FROM t3
#     EXCEPT SELECT b,c,a FROM t3
#     INTERSECT SELECT a,b,c FROM t1
#     EXCEPT SELECT x,y,z FROM t2
#     INTERSECT SELECT a,b,c FROM t3
#     EXCEPT SELECT y,x,z FROM t2
#     INTERSECT SELECT a,b,c FROM t1
#     EXCEPT SELECT c,b,a FROM t3
#     ORDER BY c
#   }
# } {1 a a 9.9 b B {} C c}
# do_test selectA-3.72 {
#   execsql {
#     SELECT a,b,c FROM t3 UNION SELECT x,y,z FROM t2
#     ORDER BY a,b,c
#   }
# } {{} C c {} U u -23 Y y 1 a a 9.9 b B 5200000.0 X x hello d D mad Z z abc e e hare m M}
# do_test selectA-3.73 {
#   execsql {
#     SELECT a,b,c FROM t3 UNION SELECT x,y,z FROM t2
#     ORDER BY a DESC,b,c
#   }
# } {hare m M abc e e mad Z z hello d D 5200000.0 X x 9.9 b B 1 a a -23 Y y {} C c {} U u}
# do_test selectA-3.74 {
#   execsql {
#     SELECT a,b,c FROM t3 UNION SELECT x,y,z FROM t2
#     ORDER BY a,c,b
#   }
# } {{} C c {} U u -23 Y y 1 a a 9.9 b B 5200000.0 X x hello d D mad Z z abc e e hare m M}
# do_test selectA-3.75 {
#   execsql {
#     SELECT a,b,c FROM t3 UNION SELECT x,y,z FROM t2
#     ORDER BY b,a,c
#   }
# } {{} C c {} U u 5200000.0 X x -23 Y y mad Z z 1 a a 9.9 b B hello d D abc e e hare m M}
# do_test selectA-3.76 {
#   execsql {
#     SELECT a,b,c FROM t3 UNION SELECT x,y,z FROM t2
#     ORDER BY b COLLATE NOCASE,a,c
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-3.77 {
#   execsql {
#     SELECT a,b,c FROM t3 UNION SELECT x,y,z FROM t2
#     ORDER BY b COLLATE NOCASE DESC,a,c
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u hare m M abc e e hello d D {} C c 9.9 b B 1 a a}
# do_test selectA-3.78 {
#   execsql {
#     SELECT a,b,c FROM t3 UNION SELECT x,y,z FROM t2
#     ORDER BY c,b,a
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-3.79 {
#   execsql {
#     SELECT a,b,c FROM t3 UNION SELECT x,y,z FROM t2
#     ORDER BY c,a,b
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-3.80 {
#   execsql {
#     SELECT a,b,c FROM t3 UNION SELECT x,y,z FROM t2
#     ORDER BY c DESC,a,b
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u hare m M abc e e hello d D {} C c 9.9 b B 1 a a}
# do_test selectA-3.81 {
#   execsql {
#     SELECT a,b,c FROM t3 UNION SELECT x,y,z FROM t2
#     ORDER BY c COLLATE BINARY DESC,a,b
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u abc e e {} C c 1 a a hare m M hello d D 9.9 b B}
# do_test selectA-3.82 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t3
#     ORDER BY a,b,c
#   }
# } {{} C c {} U u -23 Y y 1 a a 9.9 b B 5200000.0 X x hello d D mad Z z abc e e hare m M}
# do_test selectA-3.83 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t3
#     ORDER BY a DESC,b,c
#   }
# } {hare m M abc e e mad Z z hello d D 5200000.0 X x 9.9 b B 1 a a -23 Y y {} C c {} U u}
# do_test selectA-3.84 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t3
#     ORDER BY a,c,b
#   }
# } {{} C c {} U u -23 Y y 1 a a 9.9 b B 5200000.0 X x hello d D mad Z z abc e e hare m M}
# do_test selectA-3.85 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t3
#     ORDER BY b,a,c
#   }
# } {{} C c {} U u 5200000.0 X x -23 Y y mad Z z 1 a a 9.9 b B hello d D abc e e hare m M}
# do_test selectA-3.86 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t3
#     ORDER BY y COLLATE NOCASE,x,z
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-3.87 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t3
#     ORDER BY y COLLATE NOCASE DESC,x,z
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u hare m M abc e e hello d D {} C c 9.9 b B 1 a a}
# do_test selectA-3.88 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t3
#     ORDER BY c,b,a
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-3.89 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t3
#     ORDER BY c,a,b
#   }
# } {1 a a 9.9 b B {} C c hello d D abc e e hare m M {} U u 5200000.0 X x -23 Y y mad Z z}
# do_test selectA-3.90 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t3
#     ORDER BY c DESC,a,b
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u hare m M abc e e hello d D {} C c 9.9 b B 1 a a}
# do_test selectA-3.91 {
#   execsql {
#     SELECT x,y,z FROM t2 UNION SELECT a,b,c FROM t3
#     ORDER BY z COLLATE BINARY DESC,x,y
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u abc e e {} C c 1 a a hare m M hello d D 9.9 b B}
# do_test selectA-3.92 {
#   execsql {
#     SELECT x,y,z FROM t2
#     INTERSECT SELECT a,b,c FROM t3
#     EXCEPT SELECT c,b,a FROM t1
#     UNION SELECT a,b,c FROM t3
#     INTERSECT SELECT a,b,c FROM t3
#     EXCEPT SELECT c,b,a FROM t1
#     UNION SELECT a,b,c FROM t3
#     ORDER BY y COLLATE NOCASE DESC,x,z
#   }
# } {mad Z z -23 Y y 5200000.0 X x {} U u hare m M abc e e hello d D {} C c 9.9 b B 1 a a}
# do_test selectA-3.93 {
#   execsql {
#     SELECT upper((SELECT c FROM t1 UNION SELECT z FROM t2 ORDER BY 1));
#   }
# } {A}
# do_test selectA-3.94 {
#   execsql {
#     SELECT lower((SELECT c FROM t1 UNION ALL SELECT z FROM t2 ORDER BY 1));
#   }
# } {a}
# do_test selectA-3.95 {
#   execsql {
#     SELECT lower((SELECT c FROM t1 INTERSECT SELECT z FROM t2 ORDER BY 1));
#   }
# } {{}}
# do_test selectA-3.96 {
#   execsql {
#     SELECT lower((SELECT z FROM t2 EXCEPT SELECT c FROM t1 ORDER BY 1));
#   }
# } {m}
# do_test selectA-3.97 {
#   execsql {
#     SELECT upper((SELECT x FROM (
#       SELECT x,y,z FROM t2
#       INTERSECT SELECT a,b,c FROM t3
#       EXCEPT SELECT c,b,a FROM t1
#       UNION SELECT a,b,c FROM t3
#       INTERSECT SELECT a,b,c FROM t3
#       EXCEPT SELECT c,b,a FROM t1
#       UNION SELECT a,b,c FROM t3
#       ORDER BY y COLLATE NOCASE DESC,x,z)))
#   }
# } {MAD}
# do_execsql_test selectA-3.98 {
#   WITH RECURSIVE
#     xyz(n) AS (
#       SELECT upper((SELECT x FROM (
#         SELECT x,y,z FROM t2
#         INTERSECT SELECT a,b,c FROM t3
#         EXCEPT SELECT c,b,a FROM t1
#         UNION SELECT a,b,c FROM t3
#         INTERSECT SELECT a,b,c FROM t3
#         EXCEPT SELECT c,b,a FROM t1
#         UNION SELECT a,b,c FROM t3
#         ORDER BY y COLLATE NOCASE DESC,x,z)))
#       UNION ALL
#       SELECT n || '+' FROM xyz WHERE length(n)<5
#     )
#   SELECT n FROM xyz ORDER BY +n;
# } {MAD MAD+ MAD++}

#-------------------------------------------------------------------------
# At one point the following code exposed a temp register reuse problem.
#

# MUST_WORK_TEST

proc f {args} { return 1 }
db func f f

do_execsql_test 4.1.1 {
  DROP TABLE IF EXISTS t4;
  DROP TABLE IF EXISTS t5;
  CREATE TABLE t4(id int primary key, a int, b);
  CREATE TABLE t5(id int primary key, c int, d);

  INSERT INTO t5 VALUES(0, 1, 'x');
  INSERT INTO t5 VALUES(1, 2, 'x');
  INSERT INTO t4 VALUES(0, 3, 'x');
  INSERT INTO t4 VALUES(1, 4, 'x');

  CREATE INDEX i1 ON t4(a);
  CREATE INDEX i2 ON t5(c);
}

do_eqp_test 4.1.2 {
  SELECT c, d FROM t5 
  UNION ALL
  SELECT a, b FROM t4 WHERE f()==f()
  ORDER BY 1,2
} {
  1 0 0 {SCAN TABLE t5 USING COVERING INDEX 532_1_i2} 
  1 0 0 {USE TEMP B-TREE FOR RIGHT PART OF ORDER BY}
  2 0 0 {SCAN TABLE t4 USING COVERING INDEX 527_1_i1} 
  2 0 0 {USE TEMP B-TREE FOR RIGHT PART OF ORDER BY}
  0 0 0 {COMPOUND SUBQUERIES 1 AND 2 (UNION ALL)}
}

do_execsql_test 4.1.3 {
  SELECT c, d FROM t5 
  UNION ALL
  SELECT a, b FROM t4 WHERE f()==f()
  ORDER BY 1,2
} {
  1 x 2 x 3 x 4 x
}

do_execsql_test 4.2.1 {
  DROP TABLE IF EXISTS t6;
  DROP TABLE IF EXISTS t7;
  CREATE TABLE t6(id int primary key, a, b);
  CREATE TABLE t7(id int primary key, c, d);

  INSERT INTO t7 VALUES(0, 2, 9);
  INSERT INTO t6 VALUES(0, 3, 0);
  INSERT INTO t6 VALUES(1, 4, 1);
  INSERT INTO t7 VALUES(1, 5, 6);
  INSERT INTO t6 VALUES(2, 6, 0);
  INSERT INTO t7 VALUES(2, 7, 6);

  CREATE INDEX i6 ON t6(a);
  CREATE INDEX i7 ON t7(c);
}

do_execsql_test 4.2.2 {
  SELECT c, f(d,c,d,c,d) FROM t7
  UNION ALL
  SELECT a, b FROM t6 
  ORDER BY 1,2
} {/2 . 3 . 4 . 5 . 6 . 7 ./}


proc strip_rnd {explain} {
  regexp -all {sqlite_sq_[0123456789ABCDEF]*} $explain sqlite_sq
}

proc do_same_test {tn q1 args} {
  set r2 [strip_rnd [db eval "EXPLAIN $q1"]]
  set i 1
  foreach q $args {
    set tst [subst -nocommands {strip_rnd [db eval "EXPLAIN $q"]}]
    uplevel do_test $tn.$i [list $tst] [list $r2]
    incr i
  }
}

do_execsql_test 5.0 {
  DROP TABLE IF EXISTS t8;
  DROP TABLE IF EXISTS t9;
  CREATE TABLE t8(id int primary key, a, b);
  CREATE TABLE t9(id int primary key, c, d);
} {}

do_same_test 5.1 {
  SELECT a, b FROM t8 INTERSECT SELECT c, d FROM t9 ORDER BY a;
} {
  SELECT a, b FROM t8 INTERSECT SELECT c, d FROM t9 ORDER BY t8.a;
} {
  SELECT a, b FROM t8 INTERSECT SELECT c, d FROM t9 ORDER BY 1;
} {
  SELECT a, b FROM t8 INTERSECT SELECT c, d FROM t9 ORDER BY c;
} {
  SELECT a, b FROM t8 INTERSECT SELECT c, d FROM t9 ORDER BY t9.c;
}

do_same_test 5.2 {
  SELECT a, b FROM t8 UNION SELECT c, d FROM t9 ORDER BY a COLLATE NOCASE
} {
  SELECT a, b FROM t8 UNION SELECT c, d FROM t9 ORDER BY t8.a COLLATE NOCASE
} {
  SELECT a, b FROM t8 UNION SELECT c, d FROM t9 ORDER BY 1 COLLATE NOCASE
} {
  SELECT a, b FROM t8 UNION SELECT c, d FROM t9 ORDER BY c COLLATE NOCASE
} {
  SELECT a, b FROM t8 UNION SELECT c, d FROM t9 ORDER BY t9.c COLLATE NOCASE
}

do_same_test 5.3 {
  SELECT a, b FROM t8 EXCEPT SELECT c, d FROM t9 ORDER BY b, c COLLATE NOCASE
} {
  SELECT a, b FROM t8 EXCEPT SELECT c, d FROM t9 ORDER BY 2, 1 COLLATE NOCASE
} {
  SELECT a, b FROM t8 EXCEPT SELECT c, d FROM t9 ORDER BY d, a COLLATE NOCASE
} {
  SELECT a, b FROM t8 EXCEPT SELECT c, d FROM t9 ORDER BY t9.d, c COLLATE NOCASE
} {
  SELECT a, b FROM t8 EXCEPT SELECT c, d FROM t9 ORDER BY d, t8.a COLLATE NOCASE
}

do_catchsql_test 5.4 {
  SELECT a, b FROM t8 UNION SELECT c, d FROM t9 ORDER BY a+b COLLATE NOCASE
} {1 {1st ORDER BY term does not match any column in the result set}}


finish_test

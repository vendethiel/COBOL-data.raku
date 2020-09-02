use Test;
use COBOL::Data;


{
  my $simple = parse(q:to/DATA/)[0].klass;
01 datum.
 02 title.
DATA
  say $simple.receive({datum => {title => {}}});
}

is stringify(parse(q:to/DATA/).children).trim, q:to/EXPECT/.trim;
01 A.
 02 AB.
  03 ABC.
 02 AC.
  03 ACC.
   04 ACCD.
01 B.
DATA
- A
 - AB
   - ABC
 - AC
   - ACC
     - ACCD
---
- B
EXPECT

use Test;
use COBOL::Data;

is stringify(parse(q:to/DATA/)).trim, q:to/EXPECT/.trim;
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

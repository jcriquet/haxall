//
// Copyright (c) 2023, SkyFoundry LLC
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Sep 2032  Brian Frank  Create
//

using haystack

**
** HisItemTest
**
@Js
class HisItemTest : HaystackTest
{

  Void testBinaryIO()
  {
    ts := Date("2010-01-03").midnight(TimeZone.cur)

    // empty
    verifyBinaryIO(HisItem[,], 8)

    // each type
    verifyBinaryIO([HisItem(ts, true)], 17)
    verifyBinaryIO([HisItem(ts, false)], 17)
    verifyBinaryIO([HisItem(ts, NA.val)], 17)
    verifyBinaryIO([HisItem(ts, n(1234))], 25)
    verifyBinaryIO([HisItem(ts, n(123456789))], 25)
    verifyBinaryIO([HisItem(ts, "a")], 20)

    // prev value is the same
    verifyBinaryIO([HisItem(ts, n(1234)), HisItem(ts+4min, n(1234))], 30)
    verifyBinaryIO([HisItem(ts, true), HisItem(ts+1day, true)], 22)
    verifyBinaryIO([HisItem(ts, "a"), HisItem(ts+7sec, "a")], 25)

    // with larger timestamp
    verifyBinaryIO([HisItem(ts, n(1234)), HisItem(ts+597hr, n(1234))], 34)

    // strings
    verifyBinaryIO([HisItem(ts, "alpha"), HisItem(ts+1min, "beta")], 35)
    verifyBinaryIO([HisItem(ts, "alpha"), HisItem(ts+1min, "beta"), HisItem(ts+2min, "alpha")], 35+5+4)
  }

  Void verifyBinaryIO(HisItem[] items, Int? expectSize := null)
  {
    buf := Buf()
    HisItem.encode(buf.out, items)
    if (expectSize != null) verifyEq(buf.size, expectSize)

    tz := items.first?.ts?.tz ?: TimeZone.cur
    unit := (items.first?.val as Number)?.unit
    roundtrip := HisItem.decode(buf.flip.in, tz, unit)
    verifyEq(roundtrip.size, items.size)
    roundtrip.each |x, i|
    {
      verifyEq(x.ts, items[i].ts)
      verifyEq(x.val, items[i].val)
    }
  }

}
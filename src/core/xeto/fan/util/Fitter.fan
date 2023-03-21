//
// Copyright (c) 2023, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Jan 2023  Brian Frank  Creation
//

using util
using data

**
** Fitter
**
@Js
internal class Fitter
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make(DataEnv env, DataContext cx, DataDict opts, Bool failFast := true)
  {
    this.env = env
    this.failFast = failFast
    this.opts = opts
    this.cx = cx
  }

//////////////////////////////////////////////////////////////////////////
// Spec Fits
//////////////////////////////////////////////////////////////////////////

  Bool specFits(DataSpec a, DataSpec b)
  {
    // if a is nonimally typed as b, then definitely fits
    if (a.isa(b)) return true

    // scalars are fit only by their nominal types
    if (a.isScalar) return a.type.isa(b.type)

    // dicts are fit by structural typing
    if (b.isDict)
    {
      if (!a.isDict) return false
      return specFitsStruct(a, b)
    }

    // no joy
    return explainNoFit(a, b)
  }

  private Bool specFitsStruct(DataSpec a, DataSpec b)
  {
    r := b.slots.eachWhile |bslot|
    {
      aslot := a.slot(bslot.name, false)
      if (aslot == null) return "nofit"
      return specFits(aslot, bslot) ? null : "nofit"
    }
    return r == null
  }

//////////////////////////////////////////////////////////////////////////
// Instance Fits
//////////////////////////////////////////////////////////////////////////

  Bool valFits(Obj? val, DataSpec type)
  {
    // get type for value
    valType := env.typeOf(val, false)
    if (valType == null) return explainNoType(val)

    // check nominal typing
    if (valType.isa(type)) return true

    // check structurally typing
    if (val is DataDict && type.isa(env.dictSpec))
      return fitsStruct(val, type)

    return explainNoFit(valType, type)
  }

  private Bool fitsStruct(DataDict dict, DataSpec type)
  {
    slots := type.slots
    match := true
    slots.each |slot|
    {
      match = fitsSlot(dict, slot) && match
      if (failFast && !match) return false
    }
    return match
  }

  private Bool fitsSlot(DataDict dict, DataSpec slot)
  {
    slotType := slot.type

    if (slotType.isQuery) return fitsQuery(dict, slot)

    val := dict.get(slot.name, null)

    if (val == null)
    {
      if (slotType.isMaybe) return true
      return explainMissingSlot(slot)
    }

    valFits := Fitter(env, cx, opts).valFits(val, slotType)
    if (!valFits) return explainInvalidSlotType(val, slot)

    return true
  }

  private Bool fitsQuery(DataDict dict, DataSpec query)
  {
    // if no constraints then no additional checking required
    if (query.slots.isEmpty) return true

    // run the query to get matching extent
    extent := Query(env, cx, opts).query(dict, query)

    // use query.of as explain name
    ofDis := (query["of"] as DataSpec)?.name ?: query.name

    // make sure each constraint has exactly one match
    match := true
    query.slots.eachWhile |constraint|
    {
      match = fitQueryConstraint(dict, ofDis, extent, constraint) && match
      if (failFast && !match) return "break"
      return null
    }

    return match
  }

  private Bool fitQueryConstraint(DataDict rec, Str ofDis, DataDict[] extent, DataSpec constraint)
  {
    matches := DataDict[,]
    extent.each |x|
    {
      if (valFits(x, constraint)) matches.add(x)
    }

    if (matches.size == 1) return true

    if (matches.size == 0)
    {
      if (constraint.isMaybe) return true
      return explainMissingQueryConstraint(ofDis, constraint)
    }

    return explainAmbiguousQueryConstraint(ofDis, constraint, matches)
  }

//////////////////////////////////////////////////////////////////////////
// Lint Explain
//////////////////////////////////////////////////////////////////////////

  virtual Bool explainNoType(Obj? val) { false }

  virtual Bool explainNoFit(DataSpec valType, DataSpec type) { false }

  virtual Bool explainMissingSlot(DataSpec slot) { false }

  virtual Bool explainInvalidSlotType(Obj val, DataSpec slot) { false }

  virtual Bool explainMissingQueryConstraint(Str ofDis, DataSpec constraint) { false }

  virtual Bool explainAmbiguousQueryConstraint(Str ofDis, DataSpec constraint, DataDict[] matches) { false }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private const DataEnv env
  private const Bool failFast
  private const DataDict opts
  private DataContext cx
}

**************************************************************************
** ExplainFitter
**************************************************************************

@Js
internal class ExplainFitter : Fitter
{
  new make(DataEnv env,  DataContext cx, DataDict opts, |DataLogRec| cb)
    : super(env, cx, opts, false)
  {
    this.cb = cb
  }

  override Bool explainNoType(Obj? val)
  {
    log("Value not mapped to data type [${val?.typeof}]")
  }

  override Bool explainNoFit(DataSpec valType, DataSpec type)
  {
    log("Type '$valType' does not fit '$type'")
  }

  override Bool explainMissingSlot(DataSpec slot)
  {
    if (slot.type.isMarker)
      return log("Missing required marker '$slot.name'")
    else
      return log("Missing required slot '$slot.name'")
  }

  override Bool explainMissingQueryConstraint(Str ofDis, DataSpec constraint)
  {
    log("Missing required $ofDis $constraint.name")
  }

/*
  override Bool explainAmbiguousQueryConstraint(Str ofDis, DataSpec constraint, DataDict[] matches)
  {
    log("Ambiguous match for $ofDis $constraint.name: " + recsToDis(matches))
  }
*/

  override Bool explainInvalidSlotType(Obj val, DataSpec slot)
  {
    log("Invalid value type for '$slot.name' - '${val.typeof}' does not fit '$slot.type'")
  }

  private Bool log(Str msg)
  {
    cb(XetoLogRec(LogLevel.err, msg, FileLoc.unknown, null))
    return false
  }

/*
  private Str recsToDis(DataDict[] recs)
  {
    s := StrBuf()
    for (i := 0; i<recs.size; ++i)
    {
      rec := recs[i]
      str := "@" + rec->id
      dis := relDis(rec)
      if (dis != null) str += " $dis.toCode"
      s.join(str, ", ")
      if (s.size > 50 && i+1<recs.size)
        return s.add(", ${recs.size - i - 1} more ...").toStr
    }
    return s.toStr
  }
 */

  private |DataLogRec| cb
}


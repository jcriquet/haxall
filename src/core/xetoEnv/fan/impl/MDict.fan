//
// Copyright (c) 2023, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Feb 2023  Brian Frank  Creation (yet again)
//

using xeto

**
** MDict is used to wrap a Dict with a Spec
**
@Js
internal const class MDict : haystack::Dict
{
  new make(Dict wrapped, Spec spec)
  {
    this.wrapped = wrapped
    this.spec = spec
  }

  const override Spec spec
  const Dict wrapped

  @Operator override Obj? get(Str n, Obj? def := null) { wrapped.get(n, def) }
  override Bool isEmpty() { wrapped.isEmpty }
  override Bool has(Str n) { wrapped.has(n) }
  override Bool missing(Str n) { wrapped.missing(n) }
  override Void each(|Obj, Str| f) { wrapped.each(f) }
  override Obj? eachWhile(|Obj, Str->Obj?| f) { wrapped.eachWhile(f) }
  override Obj? trap(Str n, Obj?[]? a := null) { wrapped.trap(n, a) }

}

**************************************************************************
** MDictMerge1
**************************************************************************

** Wrap dict with one extra name/value pair
@NoDoc @Js
const class MDictMerge1 : haystack::Dict
{
  new make(Dict wrapped, Str n0, Obj v0)
  {
    this.wrapped = wrapped
    this.n0 = n0
    this.v0 = v0
  }

  const Dict wrapped
  const Str n0
  const Obj v0

  @Operator override Obj? get(Str n, Obj? def := null)
  {
    if (n == n0) return v0
    return wrapped.get(n, def)
  }

  override Bool isEmpty()
  {
    false
  }

  override Bool has(Str n)
  {
    n == n0 || wrapped.has(n)
  }

  override Bool missing(Str n)
  {
    n != n0 && wrapped.missing(n)
  }

  override Void each(|Obj, Str| f)
  {
    f(v0, n0)
    wrapped.each(f)
  }

  override Obj? eachWhile(|Obj, Str->Obj?| f)
  {
    r := f(v0, n0); if (r != null) return r
    return wrapped.eachWhile(f)
  }

  override Obj? trap(Str n, Obj?[]? a := null)
  {
    if (n == n0) return v0
    return wrapped.trap(n, a)
  }
}
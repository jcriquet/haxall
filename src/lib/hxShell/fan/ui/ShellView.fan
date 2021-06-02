//
// Copyright (c) 2021, SkyFoundry LLC
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Jun 2021  Brian Frank  Creation
//

using dom
using domkit
using haystack
using hx

**
** ShellView is used to display the current grid
**
@Js
internal class ShellView : Box
{
  new make(Shell sh)
  {
    this.sh = sh
    updateText("Try out some Axon!")
  }

  Void update()
  {
    removeAll
    switch (sh.viewType)
    {
      case ShellViewType.csv:   updateGridWriter(CsvWriter#)
      case ShellViewType.json:  updateGridWriter(JsonWriter#)
      case ShellViewType.trio:  updateGridWriter(TrioWriter#)
      case ShellViewType.zinc:  updateGridWriter(ZincWriter#)
      default: add(Label { it.text = "Unsupported: $sh.viewType" })
    }
  }

  private Void updateGridWriter(Type type)
  {
    buf := StrBuf()
    writer := (GridWriter)type.make([buf.out])
    writer.writeGrid(sh.grid)
    updateText(buf.toStr)
  }

  private Void updateText(Str val)
  {
    add(TextArea
    {
      it.style.addClass("mono")
      it.style->whiteSpace = "pre"
      it.val = val
    })
  }

  private Shell sh
}

**************************************************************************
** ShellViewType
**************************************************************************

@Js
internal enum class ShellViewType
{
  table("Table"),
  csv("CSV"),
  json("JSON"),
  trio("Trio"),
  zinc("Zinc")

  private new make(Str dis) { this.dis = dis }

  const Str dis
}

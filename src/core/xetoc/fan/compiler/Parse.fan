//
// Copyright (c) 2022, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Jul 2022  Brian Frank  Creation
//

using util

**
** Parse all source files into AST nodes
**
internal class Parse : Step
{
  override Void run()
  {
    // get input dir/file
    input := compiler.input
    if (input == null) throw err("Compiler input not configured", FileLoc.inputs)
    if (!input.exists) throw err("Input file not found: $input", FileLoc.inputs)

    // parse lib of types or data value
    if (isLib)
      parseLib(input)
    else
      parseData(input)
  }

  private Void parseLib(File input)
  {
    // create ALib as our root object
    lib := ALib(compiler, FileLoc(input), compiler.libName)

    // parse directory into root lib
    parseDir(input, lib)
    bombIfErr

    // remove pragma object from lib slots
    pragma := validateLibPragma(lib)
    bombIfErr

    compiler.ast    = lib
    compiler.lib    = lib
    compiler.pragma = pragma
  }

  private Void parseData(File input)
  {
    // create ADataDoc as our root object
    doc := ADataDoc(compiler, FileLoc(input))

    // parse into root
    parseFile(input, doc)
    bombIfErr

    // remove pragma from root
    // TODO
    pragma := ADict(doc.loc)
//     pragma := validatePragma(root)
//     bombIfErr

    compiler.ast = doc
    compiler.data = doc
    compiler.pragma = pragma
  }

  private ADict? validateLibPragma(ALib lib)
  {
    // remove object named "pragma" from root
    pragma := lib.tops.remove("pragma")

    // if not found
    if (pragma == null)
    {
      // libs must have pragma
      err("Lib '$compiler.libName' missing  pragma", lib.loc)
      return null
    }

    // libs must type their pragma as Lib
    if (isLib)
    {
      if (pragma.typeRef == null || pragma.typeRef.name.name != "Lib") err("Pragma must have 'Lib' type", pragma.loc)
    }

    // must have meta, and no slots
    if (pragma.meta == null) err("Pragma missing meta data", pragma.loc)
    if (pragma.slots != null) err("Pragma cannot have slots", pragma.loc)
    if (pragma.val != null) err("Pragma cannot scalar value", pragma.loc)
    return pragma.meta
  }

  private Void parseDir(File input, ALib lib)
  {
    if (input.ext == "xetolib")
    {
      zip := Zip.read(input.in)
      try
      {
        zip.readEach |f|
        {
          if (f.ext == "xeto") parseFile(f, lib)
        }
      }
      finally zip.close
    }
    else if (input.isDir)
    {
      input.list.each |sub|
      {
        if (sub.ext == "xeto") parseFile(sub, lib)
      }
    }
    else
    {
      parseFile(input, lib)
    }
  }

  private Void parseFile(File input, ADoc doc)
  {
    loc := FileLoc(input)
    try
    {
      Parser(this, loc, input.in, doc).parseFile
    }
    catch (FileLocErr e)
    {
      err(e.msg, e.loc)
      return null
    }
    catch (Err e)
    {
      err(e.toStr, loc, e)
      return null
    }
  }
}
import httpclient, uri, strutils, json, strtabs, os, sequtils, strformat
import localize, fusion/htmlparser, fusion/htmlparser/xmltree, argparse

type
  Chapter* = object
    name*: string
    url*: string

requireLocalesToBeTranslated ("ru", "")

globalLocale = (systemLocale(), LocaleTable.default)

var logEnabled = true

var baseUrl = "https://www.scribblehub.com".parseUri


proc extractBookId*(url: string): string =
  result = url
  if result.startsWith(($baseUrl) & "/" & "series" & "/"):
    result = result[(($baseUrl) & "/" & "series" & "/").len..^1]
  # todo: https://www.scribblehub.com/read/***/chapter/~~~/


proc characters*(bookid: string): seq[Chapter] =
  var n = 1
  while true:
    defer: inc n
    if logEnabled:
      echo tr"Getting: ", (baseUrl/"series"/bookid)?{"toc": $n}

    let html = newHttpClient(
      headers = newHttpHeaders {
        "Cookie": "toc_sorder=asc; toc_show=50"
      }
    ).get((baseUrl/"series"/bookid)?{"toc": $n}).body.parseHtml

    var count = 0
    for x in html.findAll("ol"):
      if not x.attrs.hasKey "class": continue
      if x.attrs["class"] != "toc_ol": continue
      for x in x:
        result.add Chapter(
          name: x[0][0].text,
          url: x[0].attrs["href"],
        )
        inc count
    
    if count < 50: break


proc parseChapter*(html: string): string =
  let html = parseHtml(html)

  for x in html.findAll("div"):
    if x.attr("id") != "chp_raw": continue
    return x.innerText


proc getChapter*(url: string): string =
  result = newHttpClient().get(url).body.parseChapter


when isMainModule:
  template preprocess {.dirty.} =
    if opts.parentOpts.quiet: logEnabled = false

  var p = newParser:
    flag("-q", "--quiet", help="don't display logs")
    command("list"):
      help("list all book chapters")
      arg("book")
      run:
        preprocess
        
        echo opts.book.extractBookId.characters

    command("getChapter"):
      help("get chapter content. outputs text files if output specified, else outputs to stdout")
      arg("chapter", help="chapter url")
      option("-o", "--output", default=some "out.txt", help="set output file")
      run:
        preprocess

        writeFile(opts.output, opts.chapter.getChapter)
    
    command("getBook"):
      help("get book chapters")
      arg("book")
      option("-o", "--output", default=some ".", help="set output directory")
      flag("-n", "--names", help="use chapter names instead of numbers")
      run:
        preprocess

        let bookid = opts.book.extractBookId

        createDir opts.output
        for i, x in bookid.characters:
          if logEnabled:
            echo tr"Getting chapter {x.name}: ", x.url
          let filename =
            if opts.names:
              x.name
            else:
              $(i + 1)
          writeFile(opts.output / (filename & ".txt"), x.url.getChapter)


  try:
    run p
  except UsageError:
    stderr.writeLine getCurrentExceptionMsg()
    quit(1)

  updateTranslations()

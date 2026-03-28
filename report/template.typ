#import "@preview/codly:1.3.0": *

#let codly = codly
#let codly-init = codly-init
#let std-bibliography = bibliography 
#let font-family = ( "CMU Serif", "0xProto Nerd Font", "Latin Modern Roman", "New Computer Modern")
#let font-family-mono = "0xProto Nerd Font Mono"


#let include_code(file, lang, start, end) = {
  let content = read(file).split("\n")
  let snippet = content.slice(start - 1, end).join("\n")
  raw(snippet, lang: lang, block: true)
}

#let font-size = (
  normal: 10pt,
  small: 8pt,
  footnote: 6pt,
  large: 12pt,
  Large: 14.4pt,
  huge: 20pt,
)

#let make-title(title) = {
  align(left, {
    v(0.5pt)
    set text(size: 17.28pt, weight: "bold")
    set par(leading: 8.4pt)
    smallcaps(title)
  })
}

#let make-author-block(author) = {
  let lines = ([*#author.names.join(", ", last: " & ")*],)
  if "affiliation" in author { lines.push(author.affiliation) }
  if "address" in author { lines.push(author.address) }
  if "email" in author { lines.push(link("mailto:" + author.email, raw(author.email))) }
  if "student-id" in author { lines.push("SID: " + author.student-id) }
  
  block(width: 100%, spacing: 4pt, lines.join([\ ]))
}

#let make-authors(authors) = {
  v(15pt)
  set par(first-line-indent: 0pt)

  let items = if type(authors) == array { authors } else { (authors,) }
  grid(
    columns: (1fr,) * calc.min(3, authors.len()),
    column-gutter: 1em,
    row-gutter: 2em,
    ..authors.map(make-author-block)
  )
  v(25pt)
}

#let make-abstract(abstract) = {
  if abstract != none {
    v(10pt)
    block(width: 100%, {
      set align(center)
      set text(size: font-size.large)
      smallcaps[Abstract]
    })
    v(10pt)
    pad(left: 0.5in, right: 0.5in, {
      set text(size: 10pt)
      set par(leading: 4.35pt, justify: true)
      abstract
    })
    v(20pt)
  }
}

#let apa_table(
  columns: (),
  headers: (),
  ..rows
) = {
  let total-rows = calc.ceil(rows.pos().len() / columns.len())
  table(
    columns: columns,
    stroke: (x, y) => (
      // y == 0 is line at very top
      // y == 1 is line under headers
      top: if y == 0 or y == 1 { 1pt + black } else { 0pt },
      // y == total-rows is the line at the very bottom
      bottom: if y == total-rows { 1pt + black } else { 0pt },
      left: 0pt,
      right: 0pt,
    ),    // Map headers and rows
    ..headers.map(it => strong(it)),
    ..rows
  )
}

#let project(
  title: "Document Title",
  authors: (),
  student-id: "123456",
  abstract: none,
  keywords: (),
  date: auto,
  bibliography_file: none,
  appendix: none,
  header_text: [Research Paper Template],
  body,
) = {
  // Document Metadata
  let author_list = if type(authors) == array{authors} else {(authors,)}
  show smallcaps: set text(font: "CMU Serif Caps")
  set document(
    title: title,
    author: author_list.map(
      a => {
        if type(a) == dictionary and "names" in a {
          a.names.join(", ")
        } else { str(a) }
      }
      ),
    keywords: keywords,
    date: date
  )

  // Page Setup
  set page(
    paper: "us-letter",
    margin: (x: 1.5in, y: 1in),
    header: {
      set text(size: font-size.small)
      stack(
        dir: ttb,
        spacing: 4pt,
        header_text,
        line(length: 100%, stroke: 0.4pt)
      )
    },
    footer: context {
      let page_num = counter(page).at(here()).first()
      align(center, text(size: font-size.normal, [#page_num]))
    },
  )

  // Global Styles
  set text(font: font-family, size: font-size.normal)
  set par(justify: true, leading: 4.3pt, spacing: 10pt)
  show raw: set text(font: font-family-mono)

  // Heading Styles
  set heading(numbering: "1.1")
  show heading: it => {
    let number = if it.numbering != none { counter(heading).display(it.numbering) }
    let gap = h(0.6em, weak: true)
    
    v(15pt, weak: true)
    if it.level == 1 {
      text(size: font-size.large, weight: "bold", smallcaps[#number#gap#it.body])
    } else {
      text(size: font-size.normal, weight: "bold", [#number#gap#it.body])
    }
    v(10pt, weak: true)
  }

  // Element Formatting
  show figure.where(kind: image): set figure.caption(position: bottom)
  show figure.where(kind: table): set figure.caption(position: top)
  set math.equation(numbering: "(1)")

  // Final Assembly
  make-title(title)
  make-authors(author_list)
  make-abstract(abstract)

  body

  if bibliography_file != none {
    pagebreak(weak: true)
    std-bibliography(bibliography_file, title: [References], style: "apa")
  }

  if appendix != none {
    pagebreak(weak: true)
    set heading(numbering: "A.1")
    counter(heading).update(0)
    appendix
  }

  show: codly-init
}


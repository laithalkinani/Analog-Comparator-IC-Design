#import "template.typ": *
#import "@preview/codly:1.3.0": *
#show: codly-init

#import "@preview/codly-languages:0.1.10": *
#codly(languages: codly-languages)

#import "@preview/lovelace:0.3.1": *

// Check for the private compile flag
#let use-private = sys.inputs.at("private", default: "false") == "true"

// Conditionally load the array of authors
#let document-authors = if use-private {
  import "authors.typ": private-authors
  private-authors
} else {
  (
    (
      names: ("[REDACTED AUTHOR 1]",),
      affiliation: "[REDACTED AFFILIATION]",
      email: "[REDACTED EMAIL]",
      student-id: "[REDACTED SID]"
    ),
    (
      names: ("[REDACTED AUTHOR 2]",),
      affiliation: "[REDACTED AFFILIATION]",
      email: "[REDACTED EMAIL]",
      student-id: "[REDACTED SID]"
    ),
  )
}

#show: project.with(
  header_text: [ELEC4440 - Analog Integrated Circuit Design],
  title: [Final Project - Comparator Design],
  authors: document-authors,
  date: auto,
  abstract:[ 
    placeholder text
  ],
)

= Theory


= Results 


= Discussion


= Conclusion

#pagebreak()

#include("citations.bib")
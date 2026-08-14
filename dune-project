(lang dune 3.6)

(name burav)

(generate_opam_files true)

(source
 (github dx3mod/burav))

(authors "Mikhail Lopatin <dx3mod@bk.ru>")

(maintainers "Mikhail Lopatin <dx3mod@bk.ru>")

(license MIT)

(package
 (name burav)
 (synopsis "A utility for burning firmware onto AVR MCUs")
 (depends ocaml cmdliner serialport intel_hex)
 (tags
  (avr embedded programmer)))

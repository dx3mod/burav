# stk500.ml 

The [STK500(v1) protocol] implementation written in pure OCaml for program devboards (i.e., starter kits, Arduino) 
via serial communication interfaces (usually). 

It's a simple binary protocol. The main part of it is the *command*. A command is a sequence of bytes starting with a message type byte and ending with a `CRC_EOP` byte. For every command, we expect a response. Usually, the response is `STK500_INSYNC` and `STK500_OK`.

[API references](./lib/v1.mli)

[STK500(v1) protocol]: https://ww1.microchip.com/downloads/aemDocuments/documents/OTH/ApplicationNotes/ApplicationNotes/doc2525.pdf


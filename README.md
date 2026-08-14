# burav

The Bur(N)(A)VR is a tool for burning firmware onto AVR microcontrollers. It is a light-weight reimplementation of the [AVRDUDE] utility, written in [OCaml], aiming to be easy to use and understand.

Supported protocols and devices: 
* Arduino bootloader protocol (STK500v1)

## Installation 

Now, installation is available only from the source code via the [OPAM] package manager. To install (pin) the latest development version of the utility, open your terminal and paste the following:

```console
$ opam pin burvar.dev https://github.com/dx3mod/burvar.git
```

Otherwise, you can clone the repository and use the [Dune] build system to build the project without a package manager, for some reasons such as native system distributions (e.g., `.exe`, `.dmg`, and distro packages).

## Usage

After successfully installing the `burvar`, you can upload your firmware by using the `burvar upload` command on a connected AVR board. For more details see `burvar upload --help`.

Example of burning firmware on an Arduino Uno board using the STK500 serial port protocol:
```console
$ burvar upload -p stk500 -b 11520 -P /dev/cu.usbserial-11230 firmware.hex
```

```
Using firmware file as INTEL HEX source: /tmp/playground/real.hex
Using stk500 programmer
Initialize stage. Entering to programming mode.
Reset the serial port (i.e. your board)
Send [GET_SYNC] command
Send [SET_DEVICE] command
Send |ENTER_PROG_MODE| command. Entering to programming mode.
Start firmware uploading cycle...
   Send [LOAD_ADDRESS 0x0000] command
   Send [LOAD_PAGE (0x78 bytes)] command
   Send [LOAD_ADDRESS 0x0078] command
   Send [LOAD_PAGE (0x38 bytes)] command
Finished firmware uploading cycle
Send [LEAVE_PROG_MODE] command. Leave from programming mode.
Successful uploading done.
```

## References

- [AVRDUDE] is a utility to program AVR microcontrollers;
- [avrman](https://docs.rs/avrman/latest/avrman/)  is a programmer for AVR microcontrollers written natively in Rust;

## License

The project is licensed under [the MIT License](./LICENSE), which allows for all permissions.
Just use it and enjoy yourself without fear. We are always open to pull requests!

[AVRDUDE]: https://github.com/avrdudes/avrdude
[OCaml]: https://ocaml.org
[OPAM]: https://opam.ocaml.org
[Dune]: https://dune.build
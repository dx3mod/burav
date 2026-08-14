open Cmdliner

let serial_port_path =
  let doc = "Serial port path" in
  Arg.(
    value & opt (some path) None & info [ "P"; "port" ] ~docv:"PORT_PATH" ~doc)

let programmer =
  let doc = "Target programmer" in
  Arg.(
    value
    & opt (some string) None
    & info [ "p"; "programmer" ] ~docv:"PROG_NAME" ~doc)

let baud_rate =
  let doc = "Serial baud rate" in
  Arg.(value & opt int 9600 & info [ "b"; "baud" ] ~docv:"BAUD_RATE" ~doc)

let firmware_binary_path =
  let doc = "Firmware binary/ihex path" in
  Arg.(required & pos 0 (some path) None & info [] ~docv:"FIRMWARE_PATH" ~doc)

let upload_cmd f =
  let info = Cmd.info "upload" ~doc:"Upload the firmware to connected board" in
  Cmd.make info
    Term.(
      const f $ serial_port_path $ programmer $ baud_rate $ firmware_binary_path)

let cmd f =
  let handle_upload_cmd serial_port_path firmware_binary_path =
    match serial_port_path with
    | None ->
        prerr_endline "Set the serial port path please!";
        exit 1
    | Some serial_port_path -> f serial_port_path firmware_binary_path
  in

  let info =
    Cmd.info "burav" ~doc:"A utility for burning firmware onto AVR MCUs"
  in
  Cmd.group info [ upload_cmd handle_upload_cmd ]

let run f = if !Sys.interactive then () else exit (Cmdliner.Cmd.eval @@ cmd f)

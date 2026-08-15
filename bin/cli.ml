open Cmdliner

let device_path =
  let doc = "Device path" in
  Arg.(
    value
    & opt (some path) None
    & info [ "d"; "device-path" ] ~docv:"DEVICE_PATH" ~doc)

let programmer_type =
  let doc = "Target programmer type" in
  Arg.(
    value
    & opt (some string) None
    & info [ "c"; "programmer" ] ~docv:"PROGRAMMER_TYPE" ~doc)

let baud_rate =
  let doc = "Serial baud rate" in
  Arg.(value & opt int 9600 & info [ "b"; "baud" ] ~docv:"BAUD_RATE" ~doc)

let firmware_binary_path =
  let doc = "Firmware binary/ihex path" in
  Arg.(required & pos 0 (some path) None & info [] ~docv:"FIRMWARE_PATH" ~doc)

module Commands = struct
  let upload f =
    Cmd.make
      Cmd.(info "upload" ~doc:"Upload the firmware to connected board")
      Term.(
        const f $ device_path $ programmer_type $ baud_rate
        $ firmware_binary_path)

  let handle f =
    Cmd.(
      group
        (info "burav" ~doc:"A utility for burning firmware onto AVR MCUs")
        [
          upload (fun device_path programmer_type baud_rate firmware_path ->
              f ~device_path ~programmer_type ~baud_rate ~firmware_path ());
        ])
end

let run f =
  if !Sys.interactive then ()
  else exit (Cmdliner.Cmd.eval ~catch:false @@ Commands.handle f)

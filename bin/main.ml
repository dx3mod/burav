module Log = Burav.Log

let upload ~device_path ~programmer_type ~baud_rate ~firmware_path () =
  let firmware = Burav.Firmware.Loader.from_file firmware_path in
  let file_size = In_channel.with_open_bin firmware_path In_channel.length in

  Printf.printf "burav: reading %Ld firmware's bytes from input file %S.\n"
    file_size firmware_path;

  match programmer_type with
  | Some ("arduino" | "stk500") ->
      let port_path = Option.get device_path in
      Burav.Programming_device.Arduino_bootloader.burn_firmware ~baud_rate
        ~port_path firmware
  | _ -> failwith "unsupported programmer type"

let () =
  Out_channel.set_buffered stdout false;

  try Cli.run upload with
  | Sys_error msg ->
      Printf.eprintf "burav: system error: %s\n" msg;
      exit 1
  | Failure msg ->
      Printf.eprintf "burav: something went wrong: %s\n" msg;
      exit 1

module Log = Dolog.Log

let upload ~device_path ~programmer_type ~baud_rate ~firmware_path () =
  Log.info "Uploading options:";
  Log.info "  * Firmware file: %s" firmware_path;
  Option.iter (Log.info "  * Programmer: %s") programmer_type;

  let firmware = Burav.Firmware.Loader.from_file firmware_path in

  match programmer_type with
  | Some ("arduino" | "stk500") ->
      let port_path = Option.get device_path in
      Burav.Driver_arduino.upload_firmware ~baud_rate ~port_path firmware
  | _ -> failwith "unsupported programmer type"

let () =
  Out_channel.set_buffered stdout false;

  (match Sys.getenv_opt "LOG" with
  | Some "DEBUG" -> Log.set_log_level DEBUG
  | _ -> Log.set_log_level INFO);

  Log.set_prefix_builder (fun _ -> "burav: ");

  try Cli.run upload with
  | Sys_error msg ->
      Printf.eprintf "\nSystem error: %s!\n" msg;
      exit 1
  | Failure msg ->
      Printf.eprintf "Something went wrong: %s." msg;
      exit 1

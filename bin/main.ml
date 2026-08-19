module Log = Burav.Log

let upload ~device_path ~programmer_type ~baud_rate ~firmware_path () =
  let firmware = Burav.Firmware.Loader.from_file firmware_path in
  let file_size = In_channel.with_open_bin firmware_path In_channel.length in
  Log.info "Reading %Ld bytes for flash from input file %s" file_size
    firmware_path;

  match programmer_type with
  | Some ("arduino" | "stk500") ->
      let port_path = Option.get device_path in
      Burav.Driver_arduino.upload_firmware ~baud_rate ~port_path firmware
  | _ -> failwith "unsupported programmer type"

let () =
  Out_channel.set_buffered stdout false;

  Log.set_level Debug;
  Log.set_application_name "burav";

  let pp_prefix =
    let open Dolog.Prefix_builder in
    make
      Combinator.
        [
          application_name;
          (fun ctx ppf level ->
            match level with
            | Debug ->
                Format.pp_print_string ppf "(";
                level_lower ctx ppf level;
                Format.pp_print_string ppf ")"
            | _ -> ());
          string ": ";
        ]
  in

  Log.set_prefix_builder pp_prefix;

  try Cli.run upload with
  | Sys_error msg ->
      Printf.eprintf "\nSystem error: %s!\n" msg;
      exit 1
  | Failure msg ->
      Printf.eprintf "Something went wrong: %s." msg;
      exit 1

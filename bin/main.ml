let log_using_firmware_source firm_format firm_path =
  Printf.printf "Using firmware file as %s source: %s\n" firm_format firm_path

let main ser_port_path programmer baud_rate firm_bin =
  let firmware_binary_data =
    match Filename.extension firm_bin with
    | ".hex" ->
        log_using_firmware_source "INTEL HEX" firm_bin;
        In_channel.with_open_text firm_bin Burav.Ihex_loader.binary_of_channel
    | "" | ".bin" ->
        log_using_firmware_source "RAW BINARY" firm_bin;
        In_channel.with_open_bin firm_bin In_channel.input_all
    | extension ->
        failwith
        @@ Printf.sprintf "unsupported '%s' format file for burning"
             (String.uppercase_ascii extension)
  in

  let with_open_serial_port_communication =
    let opts = Serialport.Port_options.make ~baud_rate () in
    Serialport_unix.with_open_communication ~opts ser_port_path
  in

  Printf.printf "Using %s programmer\n" (Option.get programmer);

  match programmer with
  | Some ("stk500" | "stk500v1" | "arduino") ->
      with_open_serial_port_communication @@ fun serial_port ->
      Burav.Driver_stk500.upload serial_port firmware_binary_data
  | _ -> raise (Invalid_argument "programmer invalid value")

let () =
  Out_channel.set_buffered stdout false;
  Cli.run main

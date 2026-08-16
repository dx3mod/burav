module Log = Dolog.Log

module Connection = struct
  type t = in_channel * out_channel

  let send_command (_, oc) command = Out_channel.output_string oc command

  exception Not_response
  exception Unexpected_response of { actual : string; expected : string }

  let send_command_with_expected_answer ~expected ((ic, _) as conn) command =
    send_command conn command;

    match In_channel.really_input_string ic (String.length expected) with
    | None -> raise Not_response
    | Some response ->
        if response <> expected then
          raise @@ Unexpected_response { actual = response; expected }

  let expected =
    Stk500.V1.Message.[| resp_stk_in_sync; resp_stk_ok |]
    |> Bytes.of_array |> Bytes.unsafe_to_string

  let send_sync_command conn =
    send_command_with_expected_answer ~expected conn Stk500.V1.Command.sync

  let send_set_options_command conn =
    send_command_with_expected_answer ~expected conn
      Stk500.V1.Command.set_options

  let send_enter_programming_mode_command conn =
    send_command_with_expected_answer ~expected conn
      Stk500.V1.Command.enter_programming_mode

  let send_load_address_command conn address =
    send_command_with_expected_answer ~expected conn
      Stk500.V1.Command.(load_address address)

  let send_load_flash_page_command conn page =
    send_command_with_expected_answer ~expected conn
      Stk500.V1.Command.(load_page page)

  let send_exit_programming_mode_command conn =
    send_command_with_expected_answer ~expected conn
      Stk500.V1.Command.exit_programming_mode
end

let reset_mcu pd =
  Serialport.Descriptor.Modem.set_data_terminal_ready pd false;
  Serialport.Descriptor.Modem.set_request_to_send pd false;

  Unix.sleepf 0.2;

  Serialport.Descriptor.Modem.set_data_terminal_ready pd true;
  Serialport.Descriptor.Modem.set_request_to_send pd true;

  Unix.sleepf 0.25

let upload_firmware ~baud_rate ~port_path firmware =
  Log.info "Selected Arduino bootloader (i.e. STK500v1) protocol";

  Log.debug "Open serial port communication";
  let pd = Serialport.open_communication port_path in
  Serialport.Descriptor.configure' ~baud_rate pd "8N1H";

  let conn = Serialport.Descriptor.to_channels pd in

  Log.debug "Reset MCU";
  reset_mcu pd;

  Log.info "Send SYNC command";
  Connection.send_sync_command conn;

  Log.info "Send SET_DEVICE command";
  Connection.send_set_options_command conn;

  Log.info "Enter into programming mode";
  Connection.send_enter_programming_mode_command conn;

  Log.info "Start firmware uploading...";

  let write address page =
    Log.info "  Send LOAD_ADDRESS 0x%04X command\n" address;
    Connection.send_load_address_command conn address;

    Log.info "  Send LOAD_PAGE (0x%X bytes) command\n" (String.length page);
    Connection.send_load_flash_page_command conn page
  in

  Firmware.write_into_memory ~block_size:120 ~write firmware;

  Log.info "Finished firmware uploading cycle";
  Log.info "Send LEAVE_PROG_MODE command. Leave from programming mode.";

  Connection.send_exit_programming_mode_command conn;

  Log.info "Successful uploading done."

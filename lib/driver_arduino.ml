(* module Log = Dolog.Make *)

module Stk500v1_connection = struct
  type t = [ `Conn of Serialport.Descriptor.t ]

  exception Unexpected_response of { actual : string; expected : string }

  let send_command (`Conn pd) command =
    Serialport_unix.Descriptor.write_string pd command;
    Unix.sleepf 0.01

  and verify_response (`Conn pd) expected =
    let response =
      Serialport_unix.Descriptor.read_string pd String.(length expected)
    in

    if response <> expected then
      raise @@ Unexpected_response { actual = response; expected }

  let send_command_with_expected_answer ~expected conn command =
    send_command conn command;
    verify_response conn expected

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

  let send_chip_erase conn =
    send_command_with_expected_answer ~expected conn
      Stk500.V1.Command.chip_erase
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
  Serialport.Descriptor.configure_with_mode ~baud_rate pd "8N1H";

  let conn : Stk500v1_connection.t = `Conn pd in

  Log.debug "reset microcontolller";
  reset_mcu pd;

  Serialport.Descriptor.drain pd;

  Log.debug "send SYNC command";
  Stk500v1_connection.send_sync_command conn;

  Log.debug "send SET_DEVICE command";
  Stk500v1_connection.send_set_options_command conn;

  Log.debug "enter into programming mode";
  Stk500v1_connection.send_enter_programming_mode_command conn;

  Log.info "Start firmware uploading...";
  Log.debug "send CHIP_ERASE command";
  Stk500v1_connection.send_chip_erase conn;

  let write address page =
    Log.debug "send [LOAD_ADDRESS 0x%04X] command" address;
    Stk500v1_connection.send_load_address_command conn address;

    Log.debug "send [LOAD_PAGE (0x%X bytes)] command" (String.length page);
    Stk500v1_connection.send_load_flash_page_command conn page
  in

  Firmware.write_into_memory ~page_size:128 ~write firmware;

  Log.info "Finished firmware uploading cycle";
  Log.debug "send LEAVE_PROG_MODE command. Leave from programming mode.";

  Stk500v1_connection.send_exit_programming_mode_command conn;

  Log.info "Successful uploading done."

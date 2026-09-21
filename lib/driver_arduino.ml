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
  Printf.printf
    "burav.arduino: selected Arduino bootloader (STK500v1) protocol.\n";
  Printf.printf "burav.arduino: opening serial port.\n";

  let pd = Serialport.open_communication port_path in
  Serialport.Descriptor.configure_with_mode ~baud_rate pd "8N1H";

  Printf.printf "burav.arduino: configured serial port.\n";

  let conn : Stk500v1_connection.t = `Conn pd in

  Printf.printf "burav.arduino: resetting MCU.\n";

  reset_mcu pd;
  Serialport.Descriptor.drain pd;

  Printf.printf "burav.arduino:> sending SYNC command.\n";
  Stk500v1_connection.send_sync_command conn;

  Printf.printf "burav.arduino:> sending SET_DEVICE command.\n";
  Stk500v1_connection.send_set_options_command conn;

  Printf.printf "burav.arduino:> sending ENTER_PROG_MODE command.\n";
  Stk500v1_connection.send_enter_programming_mode_command conn;

  Printf.printf "burav.arduino: entered programming mode.\n";

  Printf.printf "burav.arduino: uploading firmware...\n";

  Printf.printf "burav.arduino: sending CHIP_ERASE command.\n";
  Stk500v1_connection.send_chip_erase conn;

  let write address page =
    Printf.printf "burav.arduino:> sending LOAD_ADDRESS (0x%04X) command.\n"
      address;
    Stk500v1_connection.send_load_address_command conn address;

    Printf.printf "burav.arduino:> sending LOAD_PAGE (%d bytes) command.\n"
      (String.length page);
    Stk500v1_connection.send_load_flash_page_command conn page
  in

  Firmware.write_into_memory ~page_size:128 ~write firmware;

  Printf.printf "burav.arduino: finished uploading firmware.\n";

  Printf.printf "burav.arduino: sending LEAVE_PROG_MODE command.\n";
  Stk500v1_connection.send_exit_programming_mode_command conn;

  Printf.printf "burav.arduino: left programming mode.\n";

  Printf.printf "burav.arduino: firmware uploaded successfully.\n"

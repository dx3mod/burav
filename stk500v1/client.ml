type t = { pd : Serialport.Descriptor.t }

let make pd = { pd }

exception Unexpected_response of { actual : string; expected : string }

let send_command { pd } command =
  Serialport_unix.Descriptor.write_string pd command;
  Unix.sleepf 0.01

and verify_response { pd } expected =
  let response =
    Serialport_unix.Descriptor.read_string pd String.(length expected)
  in

  if response <> expected then
    raise @@ Unexpected_response { actual = response; expected }

let send_command_with_expected_answer ~expected conn command =
  send_command conn command;
  verify_response conn expected

module Bytes = struct
  include Stdlib.Bytes

  let of_array arr =
    let bytes = create (Array.length arr) in
    Array.iteri (set_uint8 bytes) arr;
    bytes
end

let expected =
  Protocol.Message.[| resp_stk_in_sync; resp_stk_ok |]
  |> Bytes.of_array |> Bytes.unsafe_to_string

let send_sync_command conn =
  send_command_with_expected_answer ~expected conn Protocol.Command.sync

let send_set_options_command conn =
  send_command_with_expected_answer ~expected conn Protocol.Command.set_options

let send_enter_programming_mode_command conn =
  send_command_with_expected_answer ~expected conn
    Protocol.Command.enter_programming_mode

let send_load_address_command conn address =
  send_command_with_expected_answer ~expected conn
    Protocol.Command.(load_address address)

let send_load_flash_page_command conn page =
  send_command_with_expected_answer ~expected conn
    Protocol.Command.(load_page page)

let send_exit_programming_mode_command conn =
  send_command_with_expected_answer ~expected conn
    Protocol.Command.exit_programming_mode

let send_chip_erase conn =
  send_command_with_expected_answer ~expected conn Protocol.Command.chip_erase

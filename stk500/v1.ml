(** The implementation of the first version of the STK500 protocol. *)

module Message = struct
  type t = int

  let resp_stk_ok = 0x10
  let resp_stk_in_sync = 0x14
  let sync_crc_eop = 0x20
  let cmnd_stk_get_sync = 0x30
  let cmnd_stk_set_device = 0x42
  let cmnd_stk_enter_prog_mode = 0x50
  let cmnd_stk_leave_prog_mode = 0x51
  let cmnd_stk_load_address = 0x55
  let cmnd_stk_prog_page = 0x64
  let cmnd_stk_read_page = 0x74
  let cmnd_stk_read_sign = 0x75
end

let bytes_of_array arr =
  let bytes = Bytes.create (Array.length arr) in
  Array.iteri (Bytes.set_uint8 bytes) arr;
  bytes

module Command = struct
  type t = bytes

  let make = bytes_of_array
  let sync = make Message.[| cmnd_stk_get_sync; sync_crc_eop |]

  let set_options =
    make
      Message.
        [|
          cmnd_stk_set_device;
          0;
          (* Device code *)
          0;
          (* Revision *)
          0;
          (* ProgType *)
          0;
          (* ParMode *)
          0;
          (* Polling *)
          0;
          (* SelfTimed *)
          0;
          (* LockBytes *)
          0;
          (* FuseBytes *)
          0;
          (* FlashPollVal1 *)
          0;
          (* FlashPollVal2 *)
          0;
          (* eepromPollVal1 *)
          0;
          (* eepromPollVal2 *)
          0;
          (* PageSizeHigh *)
          0;
          (* PageSizeLow *)
          0;
          (* eepromSizeHigh *)
          0;
          (* eepromSizeLow *)
          0;
          (* FlashSize4 *)
          0;
          (* FlashSize3 *)
          0;
          (* FlashSize2 *)
          0;
          (* FlashSize1 *)
          sync_crc_eop;
        |]

  let enter_programming_mode =
    make Message.[| cmnd_stk_enter_prog_mode; sync_crc_eop |]

  and exit_programming_mode =
    make Message.[| cmnd_stk_leave_prog_mode; sync_crc_eop |]

  let load_address addr =
    let command = Bytes.create 4 in
    Bytes.set_uint8 command 0 Message.cmnd_stk_load_address;
    Bytes.set_uint16_le command 1 addr;
    Bytes.set_uint8 command 3 Message.sync_crc_eop;
    command

  let load_page payload =
    let payload_len = String.length payload in
    let command_len = 5 + payload_len in
    (* cmnd_stk_load_address (1 bytes) + payload_len (2 bytes) 
       + magic (1 bytes) + payload (payload_len bytes) + sync_crc_eop  *)
    let command = Bytes.create command_len in
    Bytes.set_uint8 command 0 Message.cmnd_stk_prog_page;
    Bytes.set_uint16_be command 1 payload_len;
    Bytes.set_uint8 command 3 0x46;
    Bytes.blit_string payload 0 command 4 payload_len;
    Bytes.set_uint8 command (4 + payload_len) Message.sync_crc_eop;
    command

  and read_page page_size =
    let command = Bytes.create 5 in
    Bytes.set_uint8 command 0 Message.cmnd_stk_read_page;
    Bytes.set_uint16_be command 1 page_size;
    Bytes.set_uint8 command 3 0x46;
    Bytes.set_uint8 command 4 Message.sync_crc_eop;
    command
end

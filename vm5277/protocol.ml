let handshake_code = 0x00

let calculate_checksum bytes =
  Bytes.fold_left (fun acc ch -> int_of_char ch lxor acc land 0xff) 0 bytes

module Request = struct
  type t = { code : code; payload : string }

  and code =
    | Get_info
    | Reboot
    | Erase_page
    | Verify_page
    | Write_page
    | Everify_page
    | Ewrite_page
    | Read_fuse
    | Write_fuse

  let make code payload = { code; payload }

  let int_of_code = function
    | Get_info -> 0x00
    | Reboot -> 0x01
    | Erase_page -> 0x10
    | Verify_page -> 0x11
    | Write_page -> 0x12
    | Everify_page -> 0x20
    | Ewrite_page -> 0x21
    | Read_fuse -> 0x30
    | Write_fuse -> 0x31

  let encode_into_buffer request buffer =
    Buffer.add_uint8 buffer 0x77;
    Buffer.add_uint8 buffer (int_of_code request.code);
    Buffer.add_uint16_be buffer (String.length request.payload);
    Buffer.add_string buffer request.payload;
    Buffer.add_uint8 buffer (Buffer.to_bytes buffer |> calculate_checksum)
end

module Response = struct
  type t = { code : code; payload : string }

  and code =
    | Ok
    | Pages_identical
    | Pages_not_identical
    | Wrong_request
    | Wrong_page_number
    | Wrong_page_size
    | Denied

  let code_of_int = function
    | 0x80 -> Ok
    | 0x81 -> Pages_identical
    | 0x82 -> Pages_not_identical
    | 0x88 -> Wrong_request
    | 0x89 -> Wrong_page_number
    | 0x8a -> Wrong_page_size
    | 0x8b -> Denied
    | _ -> invalid_arg "illegal response code"
end

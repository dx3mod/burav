type t = {
  request_buffer : Buffer.t;
  response_buffer : bytes;
  pd : Serialport.Descriptor.t;
}

let make pd =
  { pd; request_buffer = Buffer.create 100; response_buffer = Bytes.create 10 }

let send_handshake client =
  Serialport_unix.Descriptor.write_string client.pd "\x12"

let send_request client request =
  Buffer.clear client.request_buffer;
  Protocol.Request.encode_into_buffer request client.request_buffer;

  Buffer.to_bytes client.request_buffer
  |> Bytes.unsafe_to_string
  |> Serialport_unix.Descriptor.write_string client.pd

let receive_response client =
  let receive_response_magic client =
    Serialport_unix.Descriptor.read_exact client.pd client.response_buffer 0 1;

    match Bytes.get_uint8 client.response_buffer 0 with
    | 0x77 -> ()
    | _ -> failwith "invalid response magic code"
  and receive_response_code client =
    Serialport_unix.Descriptor.read_exact client.pd client.response_buffer 0 1;
    Bytes.get_uint8 client.response_buffer 0 |> Protocol.Response.code_of_int
  and receive_response_payload_length client =
    Serialport_unix.Descriptor.read_exact client.pd client.response_buffer 0 2;
    Bytes.get_uint16_be client.response_buffer 0
  and receive_response_payload client length =
    Serialport_unix.Descriptor.read_string client.pd length
  and receive_response_checksum client =
    Serialport_unix.Descriptor.read_exact client.pd client.response_buffer 0 1;
    Bytes.get_uint8 client.response_buffer 0
  in

  receive_response_magic client;
  let code = receive_response_code client in
  let length = receive_response_payload_length client in
  let payload = receive_response_payload client length in
  let _ = receive_response_checksum client in

  Protocol.Response.{ code; payload }

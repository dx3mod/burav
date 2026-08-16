type t = [ `Ihex of Intel_hex.Object.t | `Binary of string ]

let write_into_memory ~block_size ~write = function
  | `Binary binary ->
      Intel_hex.Object.from_string ~block_size binary
      |> Intel_hex.Object.into_blob ~write
  | `Ihex ihex_object ->
      let page_data = Buffer.create block_size and page_addr = ref 0 in

      let rec write' addr payload =
        let payload_length = String.length payload
        and page_length = Buffer.length page_data in

        if page_length = block_size then begin
          write !page_addr Buffer.(contents page_data);
          Buffer.clear page_data;
          page_addr := addr
        end;

        let crop_len = block_size - page_length in

        if payload_length <= crop_len then Buffer.add_string page_data payload
        else if payload_length > crop_len then (
          Buffer.add_substring page_data payload 0 crop_len;
          write' addr String.(drop_first crop_len payload))
      in

      Intel_hex.Object.into_blob ~write:write' ihex_object;
      write !page_addr Buffer.(contents page_data)

module Loader = struct
  let from_file filename =
    match Filename.extension filename with
    | ".hex" ->
        `Ihex (In_channel.with_open_text filename Intel_hex.Decode.from_channel)
    | ".bin" -> `Binary (In_channel.with_open_bin filename In_channel.input_all)
    | _ -> failwith "unsupported firmware format"
end

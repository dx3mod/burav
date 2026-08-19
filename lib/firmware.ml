type t = [ `Ihex of Intel_hex.Object.t | `Binary of string ]

let write_into_memory ~page_size ~write = function
  | `Binary binary ->
      Intel_hex.Object.from_string ~block_size:page_size binary
      |> Intel_hex.Object.into_blob ~write
  | `Ihex ihex_object -> begin
      let page_buffer = Buffer.create page_size in
      let page_addr = ref 0 in

      let write_page_buffer_if_needed () =
        if Buffer.length page_buffer = page_size then begin
          write !page_addr Buffer.(contents page_buffer);
          Buffer.clear page_buffer;
          page_addr := !page_addr + page_size
        end
      in

      let rec write' _current_addr payload =
        write_page_buffer_if_needed ();

        let remaining_page_bytes = page_size - Buffer.length page_buffer in

        if remaining_page_bytes >= String.length payload then
          Buffer.add_string page_buffer payload
        else if remaining_page_bytes < String.length payload then (
          Buffer.add_substring page_buffer payload 0 remaining_page_bytes;
          write' _current_addr @@ String.drop_first remaining_page_bytes payload)
        else failwith "impossible write state"
      in

      Intel_hex.Object.into_blob ~write:write' ihex_object;
      if Buffer.length page_buffer <> 0 then
        write !page_addr Buffer.(contents page_buffer)
    end

module Loader = struct
  let from_file filename =
    match Filename.extension filename with
    | ".hex" ->
        `Ihex (In_channel.with_open_text filename Intel_hex.Decode.from_channel)
    | ".bin" -> `Binary (In_channel.with_open_bin filename In_channel.input_all)
    | _ -> failwith "unsupported firmware format"
end

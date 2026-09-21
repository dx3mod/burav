open Printf

let enter_to_bootloader pd =
  Serialport.Descriptor.Modem.set_data_terminal_ready pd false;
  Serialport.Descriptor.Modem.set_request_to_send pd false;

  Unix.sleepf 0.2;

  Serialport.Descriptor.Modem.set_data_terminal_ready pd true;
  Serialport.Descriptor.Modem.set_request_to_send pd true;

  Unix.sleepf 0.25

let open_stk500v1_communication ~baud_rate port =
  let pd = Serialport.open_communication port in
  Serialport.Descriptor.configure_with_mode ~baud_rate pd "8N1H";

  enter_to_bootloader pd;
  Stk500v1.Client.make pd

let synchronize_board stk500_client =
  Stk500v1.Client.send_sync_command stk500_client;
  Stk500v1.Client.send_set_options_command stk500_client

and enter_to_programming_mode stk500_client =
  printf "burav.arduino: entering bootloader programming mode.\n";
  Stk500v1.Client.send_enter_programming_mode_command stk500_client

and leave_from_programming_mode stk500_client =
  printf "burav.arduino: leaving bootloader programming mode.\n";
  Stk500v1.Client.send_exit_programming_mode_command stk500_client

let write_cycle_flush_memory stk500_client firmware =
  let write address page =
    Stk500v1.Client.send_load_address_command stk500_client address;
    Stk500v1.Client.send_load_flash_page_command stk500_client page;

    printf "burav.arduino: | burned %d bytes at address 0x%04X.\n"
      String.(length page)
      address
  in

  printf "burav.arduino: starting the firmware burning cycle...\n";
  Firmware.write_into_memory ~page_size:128 ~write firmware

let burn_firmware ~baud_rate ~port_path firmware =
  printf "burav.arduino: selected Arduino bootloader (STK500v1) protocol,\n";
  printf "               serial port = %S, baud rate = %d.\n" port_path
    baud_rate;

  let stk500_client = open_stk500v1_communication ~baud_rate port_path in

  synchronize_board stk500_client;
  enter_to_programming_mode stk500_client;
  write_cycle_flush_memory stk500_client firmware;
  leave_from_programming_mode stk500_client;

  printf "burav.arduino: the firmware burned successfully!\n"

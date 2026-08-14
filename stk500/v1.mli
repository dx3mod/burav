(** Different types of incoming and outgoing messages. *)
module Message : sig
  type t = int

  val resp_stk_ok : t
  val resp_stk_in_sync : t
  val sync_crc_eop : t
  val cmnd_stk_get_sync : t
  val cmnd_stk_set_device : t
  val cmnd_stk_enter_prog_mode : t
  val cmnd_stk_leave_prog_mode : t
  val cmnd_stk_load_address : t
  val cmnd_stk_prog_page : t
  val cmnd_stk_read_page : t
  val cmnd_stk_read_sign : t
end

(** Commands for sending. *)
module Command : sig
  type t = bytes

  val sync : t
  val set_options : t
  val enter_programming_mode : t
  val exit_programming_mode : t
  val load_address : int -> t
  val load_page : string -> t
  val read_page : int -> t
end

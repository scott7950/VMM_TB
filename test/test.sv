`ifndef __TEST_SV__
`define __TEST_SV__

`include "env.sv"

program test(cpu_interface.master cpu_intf, pkt_interface.master pkt_intf);

class pkt_trans_ext extends pkt_trans;

//constraint con_pkt_len_test {
//    payload.size() == 100;
//    pkt_head_type == GOOD;
//}

endclass

cpu_trans     cpu_tr;
cpu_trans     cpu_tr_cpy;
pkt_trans_ext pkt_tr;
env e;

initial begin
    cpu_tr = new();
    pkt_tr = new();
    e = new(cpu_intf, pkt_intf);
    e.build();

    //if stop_after_n_insts is 0, the generator will generate transaction forever
    //e.cpu_e.cpu_gen.stop_after_n_insts = 0;
    e.pkt_e.pkt_gen.randomized_obj = pkt_tr;

    e.start();
    e.cpu_e.cpu_gen.stop_xactor();
    e.pkt_e.pkt_gen.stop_xactor();

    cpu_tr.randomize() with {addr == 'h4; rw == 1'b0; dout == 'd65;};
    $cast(cpu_tr_cpy, cpu_tr.copy());
    e.cpu_e.gen2drv_chan.put(cpu_tr_cpy);

    cpu_tr.randomize() with {addr == 'h8; rw == 1'b0; dout == 'd500;};
    $cast(cpu_tr_cpy, cpu_tr.copy());
    e.cpu_e.gen2drv_chan.put(cpu_tr_cpy);

    cpu_tr.randomize() with {addr == 'h0; rw == 1'b0; dout == 'h1;};
    $cast(cpu_tr_cpy, cpu_tr.copy());
    e.cpu_e.gen2drv_chan.put(cpu_tr_cpy);

    repeat(100) begin
        @(cpu_intf.cb);
    end

    e.pkt_e.pkt_scb.min_pkt_size = 65;
    e.pkt_e.pkt_scb.max_pkt_size = 500;
    e.pkt_e.pkt_gen.stop_after_n_insts = 100;
    e.pkt_e.pkt_gen.start_xactor();

    e.pkt_e.wait_for_end();
    repeat(10000) begin
        @(pkt_intf.cb);
    end
    e.report();
    $finish();
end

endprogram
`endif


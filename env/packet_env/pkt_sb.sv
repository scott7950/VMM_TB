`ifndef __PKT_sb_SV__
`define __PKT_sb_SV__

`include "vmm.sv"
`include "vmm_sb.sv"
`include "pkt_trans.sv"
`include "pkt_driver.sv"
`include "pkt_monitor.sv"

class pkt_sb extends vmm_sb_ds;

logic [9:0] min_pkt_size;
logic [9:0] max_pkt_size;

extern function new();
extern virtual function bit compare(vmm_data actual, vmm_data expected);
extern function void report(int exp_stream_id = -1, int inp_stream_id = -1);

endclass

class pkt_driver_to_sb extends pkt_driver_callbacks;
   pkt_sb pkt_scb;

   function new(pkt_sb pkt_scb);
      this.pkt_scb = pkt_scb;
   endfunction: new

   virtual task driver_pre_tx (pkt_driver xactor, ref pkt_trans trans, ref bit drop);
       if(trans.pkt_head_type == pkt_trans::GOOD) begin
           if(trans.payload.size() >= (pkt_scb.min_pkt_size - 2) && trans.payload.size() <= (pkt_scb.max_pkt_size - 2)) begin
               pkt_scb.insert(trans, vmm_sb_ds::INPUT, .exp_stream_id(0));
           end
       end
   endtask

endclass

class pkt_monitor_to_sb extends pkt_monitor_callbacks;
    pkt_sb pkt_scb;

    function new(pkt_sb pkt_scb);
        this.pkt_scb = pkt_scb;
    endfunction: new

    virtual task monitor_post_tx (pkt_monitor xactor, pkt_trans trans);
        pkt_scb.expect_in_order(trans, 0);
    endtask

endclass

function pkt_sb::new();
      super.new("Packet Scoreboard");

      this.define_stream(0, "Master",  INPUT);
      this.define_stream(0, "Slave 0", EXPECT);

endfunction


function bit pkt_sb::compare(vmm_data actual, vmm_data expected);
    pkt_trans act, exp;
    string diff;

    $cast(act, actual);
    $cast(exp, expected);

    return act.compare(exp, diff);

endfunction

function void pkt_sb::report(int exp_stream_id = -1, int inp_stream_id = -1);
    super.report(exp_stream_id, inp_stream_id);
endfunction

`endif


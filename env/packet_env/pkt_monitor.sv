`ifndef __PKT_MONITOR_SV__
`define __PKT_MONITOR_SV__

`include "vmm.sv"
`include "pkt_interface.svi"
`include "pkt_trans.sv"

class pkt_monitor extends vmm_xactor;

string name;
virtual pkt_interface.master pkt_intf;

extern function new(
    string instance,
    integer stream_id = -1, 
    virtual pkt_interface.master pkt_intf
);
extern virtual task main() ; 

endclass

//callback class
virtual class pkt_monitor_callbacks extends vmm_xactor_callbacks;

   virtual task monitor_pre_tx (
       pkt_monitor   xactor,
       ref pkt_trans trans,
       ref bit       drop
   );
   endtask

   virtual task monitor_post_tx (
       pkt_monitor xactor,
       pkt_trans   trans
   );
   endtask

endclass

function pkt_monitor::new (
    string instance,
    integer stream_id = -1, 
    virtual pkt_interface.master pkt_intf
);

    super.new("Packet Monitor", instance, stream_id) ;

    this.pkt_intf = pkt_intf;

endfunction

task pkt_monitor::main();
    logic [7:0] rxd[$];
    logic [7:0] rxd_1[];
    pkt_trans tr;
    bit drop;

    fork
        super.main();
    join_none

    while (1) begin
        tr = new();

        `vmm_callback(pkt_monitor_callbacks, monitor_pre_tx(this, tr, drop));
        if (drop == 1) begin
            `vmm_note(log, tr.psdisplay("Dropped"));
            continue;
        end

        @(pkt_intf.cb);
        while(pkt_intf.cb.rx_vld == 1'b0) begin
            @(pkt_intf.cb);
        end

        while(pkt_intf.cb.rx_vld == 1'b1) begin
            rxd.push_back(pkt_intf.cb.rxd);
            @(pkt_intf.cb);
        end

        rxd_1 = new[rxd.size()];
        foreach(rxd[i]) begin
            rxd_1[i] = rxd[i];
        end
        tr.byte_pack(rxd_1, 0);

        rxd.delete();
        rxd_1.delete();

        `vmm_callback(pkt_monitor_callbacks, monitor_post_tx(this, tr));

        `vmm_debug(log, tr.psdisplay("Packet monitor ==>"));

    end

endtask

`endif


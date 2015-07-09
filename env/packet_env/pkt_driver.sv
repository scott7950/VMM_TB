`ifndef __PKT_DRIVER_SV__
`define __PKT_DRIVER_SV__

`include "vmm.sv"
`include "pkt_interface.svi"
`include "pkt_trans.sv"

class pkt_driver extends vmm_xactor;

string name;
virtual pkt_interface.master pkt_intf;
pkt_trans_channel gen2drv_chan;

extern function new(
    string instance,
    integer stream_id = -1, 
    virtual pkt_interface.master pkt_intf,
    pkt_trans_channel gen2drv_chan = null
);
extern virtual task main() ; 
extern virtual task reset() ;

endclass

//callback class
virtual class pkt_driver_callbacks extends vmm_xactor_callbacks;

   virtual task driver_pre_tx (
       pkt_driver    xactor,
       ref pkt_trans trans,
       ref bit        drop
   );
   endtask

   virtual task driver_post_tx (
       pkt_driver xactor,
       pkt_trans  trans
   );
   endtask

endclass

function pkt_driver::new(
    string instance,
    integer stream_id = -1, 
    virtual pkt_interface.master pkt_intf,
    pkt_trans_channel gen2drv_chan = null
 );

    super.new("Packet Driver", instance, stream_id) ;

    this.pkt_intf = pkt_intf;

    if(gen2drv_chan == null)
        gen2drv_chan = new("Packet generator to driver channel", instance);
    this.gen2drv_chan = gen2drv_chan;

endfunction

task pkt_driver::main();
    integer delay = 0;
    pkt_trans tr;
    pkt_trans tr_cpy;
    bit drop;

    fork
        super.main();
    join_none

    while (1) begin
        this.wait_if_stopped_or_empty(this.gen2drv_chan) ;
        gen2drv_chan.get(tr);

        $cast(tr_cpy, tr.copy());

        `vmm_callback(pkt_driver_callbacks, driver_pre_tx(this, tr_cpy, drop));
        if (drop == 1) begin
            `vmm_note(log, tr.psdisplay("Dropped"));
            continue;
        end

        @(pkt_intf.cb);
        pkt_intf.cb.tx_vld <= 1'b1;
        pkt_intf.cb.txd    <= tr.header[15:8];
        @(pkt_intf.cb);
        pkt_intf.cb.txd    <= tr.header[7:0];

        foreach(tr.payload[i]) begin
            @(pkt_intf.cb);
            pkt_intf.cb.txd <= tr.payload[i];
        end

        delay = tr.payload.size() + 2;
        repeat(delay) begin
            @(pkt_intf.cb);
            pkt_intf.cb.tx_vld <= 1'b0;
        end

        `vmm_callback(pkt_driver_callbacks, driver_post_tx(this, tr));

        `vmm_debug(log, tr.psdisplay("Packet Driver ==>"));

    end
endtask

task pkt_driver::reset();
    @(pkt_intf.cb);
    pkt_intf.cb.txd <= 8'h0;
    pkt_intf.cb.tx_vld <= 1'b0;

    @(pkt_intf.cb);
    pkt_intf.rst_n = 1'b0;
    @(pkt_intf.cb);
    pkt_intf.rst_n = 1'b1;
    @(pkt_intf.cb);
endtask

`endif


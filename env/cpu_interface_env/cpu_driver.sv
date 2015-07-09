`ifndef __CPU_DRIVER_SV__
`define __CPU_DRIVER_SV__

`include "vmm.sv"
`include "cpu_interface.svi"
`include "cpu_trans.sv"
`include "cpu_sb.sv"

class cpu_driver extends vmm_xactor;

string name;
virtual cpu_interface.master cpu_intf;
cpu_trans_channel gen2drv_chan  ;

extern function new (
    string instance,
    integer stream_id = -1, 
    virtual cpu_interface.master cpu_intf,
    cpu_trans_channel gen2drv_chan = null
);

extern virtual task main() ; 
extern virtual task reset() ;

endclass

//callback class
virtual class cpu_driver_callbacks extends vmm_xactor_callbacks;

   virtual task driver_pre_tx (
       cpu_driver    xactor,
       ref cpu_trans trans,
       ref bit        drop
   );
   endtask

   virtual task driver_post_tx (
       cpu_driver xactor,
       cpu_trans  trans
   );
   endtask

endclass

class cpu_driver_to_sb extends cpu_driver_callbacks;
    cpu_sb cpu_scb;

    function new(cpu_sb cpu_scb);
        this.cpu_scb = cpu_scb;
    endfunction: new

    virtual task driver_post_tx (cpu_driver xactor, cpu_trans trans);
        cpu_scb.compare(trans);
    endtask

endclass

function cpu_driver::new(
    string instance,
    integer stream_id,
    virtual cpu_interface.master cpu_intf,
    cpu_trans_channel gen2drv_chan
);

    super.new("CPU Driver", instance, stream_id) ;

    this.cpu_intf = cpu_intf;

    if(gen2drv_chan == null)
        gen2drv_chan = new("CPU generator to driver channel", instance);
    this.gen2drv_chan = gen2drv_chan;

endfunction

task cpu_driver::main() ; 
    cpu_trans tr;
    cpu_trans cpy_tr;
    bit drop;

    fork
        super.main();
    join_none

    while (1) begin
        this.wait_if_stopped_or_empty(this.gen2drv_chan) ;
        gen2drv_chan.get(tr);

        `vmm_callback(cpu_driver_callbacks, driver_pre_tx(this, tr, drop));
        if (drop == 1) begin
            `vmm_note(log, tr.psdisplay("Dropped"));
            continue;
        end

        @(cpu_intf.cb);
        cpu_intf.cb.addr <= tr.addr;
        cpu_intf.cb.dout <= tr.dout;
        cpu_intf.cb.rw   <= tr.rw;
        if(tr.rw == 1'b1) begin
            @(cpu_intf.cb);
            tr.din  = cpu_intf.cb.din;
        end

        $cast(cpy_tr, tr.copy());
        `vmm_callback(cpu_driver_callbacks, driver_post_tx(this, cpy_tr));

        `vmm_debug(log, tr.psdisplay("CPU Driver ==>"));

    end
endtask

task cpu_driver::reset() ;
    @(cpu_intf.cb);
    cpu_intf.rst_n = 1'b0;
    @(cpu_intf.cb);
    cpu_intf.rst_n = 1'b1;
    @(cpu_intf.cb);
endtask

`endif


`ifndef __PKT_ENV_SV__
`define __PKT_ENV_SV__

`include "pkt_interface.svi"
`include "pkt_trans.sv"
`include "pkt_driver.sv"
`include "pkt_sb.sv"
`include "pkt_monitor.sv"

class pkt_env extends vmm_env;

virtual pkt_interface.master pkt_intf;
vmm_log log;

pkt_trans_channel  gen2drv_chan;

pkt_trans_atomic_gen pkt_gen;
pkt_driver           pkt_drv;
pkt_sb               pkt_scb;
pkt_monitor          pkt_mon;
pkt_driver_to_sb     pkt_drv_cbs_scb;
pkt_monitor_to_sb    pkt_mon_cbs_scb;

extern function new(virtual pkt_interface.master pkt_intf);

extern virtual function void gen_cfg();
extern virtual function void build();
extern virtual task reset_dut();
extern virtual task cfg_dut();
extern virtual task start();
extern virtual task wait_for_end();
extern virtual task stop();
extern virtual task cleanup();
extern virtual task report();

endclass

function pkt_env::new(virtual pkt_interface.master pkt_intf);
    super.new("Packet ENV");

    this.pkt_intf = pkt_intf;

    log = new("packet", "env");

endfunction

function void pkt_env::gen_cfg();
    super.gen_cfg();
endfunction

function void pkt_env::build();
    super.build();

    gen2drv_chan = new("Packet Generator to Driver Channel", "channel");
    pkt_gen = new("Packet Generator", 1, gen2drv_chan);
    pkt_drv = new("Packet Driver", 1, pkt_intf, gen2drv_chan);
    pkt_mon = new("Packet Monitor", 1, pkt_intf);
    pkt_scb  = new();

    pkt_drv_cbs_scb = new(pkt_scb);
    pkt_drv.append_callback(pkt_drv_cbs_scb);

    pkt_mon_cbs_scb = new(pkt_scb);
    pkt_mon.append_callback(pkt_mon_cbs_scb);

endfunction

task pkt_env::reset_dut();
    super.reset_dut();

    pkt_drv.reset();

endtask

task pkt_env::cfg_dut();
    super.cfg_dut();

endtask

task pkt_env::start();
    super.start();

    pkt_gen.start_xactor();
    pkt_drv.start_xactor();
    pkt_mon.start_xactor();
endtask

task pkt_env::wait_for_end();
    super.wait_for_end();

    fork
        pkt_gen.notify.wait_for(pkt_trans_atomic_gen::DONE);
    join_any

endtask

task pkt_env::stop();
    super.stop();

    pkt_gen.stop_xactor();
    pkt_drv.stop_xactor();
    pkt_mon.stop_xactor();

endtask

task pkt_env::cleanup();
    super.cleanup();

endtask

task pkt_env::report();
    super.report();

endtask

`endif


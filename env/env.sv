`ifndef __ENV_SV__
`define __ENV_SV__

`include "cpu_interface.svi"
`include "pkt_interface.svi"
`include "cpu_env.sv"
`include "pkt_env.sv"

class env extends vmm_env;
vmm_log log;

cpu_env cpu_e;
pkt_env pkt_e;

extern function new(virtual cpu_interface.master cpu_intf, virtual pkt_interface.master pkt_intf);

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

function env::new(virtual cpu_interface.master cpu_intf, virtual pkt_interface.master pkt_intf);
    super.new("Packet ENV");

    cpu_e = new(cpu_intf);
    pkt_e = new(pkt_intf);

    log = new("env", "env");
endfunction

function void env::gen_cfg();
    super.gen_cfg();
endfunction

function void env::build();
    super.build();

    cpu_e.build();
    pkt_e.build();

endfunction

task env::reset_dut();
    super.reset_dut();

    cpu_e.reset_dut();
    pkt_e.reset_dut();

endtask

task env::cfg_dut();
    super.cfg_dut();

endtask

task env::start();
    super.start();

    cpu_e.start();
    pkt_e.start();
endtask

task env::wait_for_end();
    super.wait_for_end();

    cpu_e.wait_for_end();
    pkt_e.wait_for_end();

endtask

task env::stop();
    super.stop();

    cpu_e.stop();
    pkt_e.stop();

endtask

task env::cleanup();
    super.cleanup();

endtask

task env::report();
    super.report();

endtask

`endif


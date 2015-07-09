`ifndef __CPU_ENV_SV__
`define __CPU_ENV_SV__

`include "cpu_interface.svi"
`include "cpu_trans.sv"
`include "cpu_driver.sv"
`include "cpu_sb.sv"

class cpu_env extends vmm_env;

virtual cpu_interface.master cpu_intf;
vmm_log log;

cpu_trans_channel     gen2drv_chan;
cpu_trans_atomic_gen  cpu_gen;
cpu_driver            cpu_drv;
cpu_sb                cpu_scb;
cpu_driver_to_sb      cpu_drv_cbs_scb;

extern function new(virtual cpu_interface.master cpu_intf);

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

function cpu_env::new(virtual cpu_interface.master cpu_intf);
    super.new("CPU ENV");

    this.cpu_intf = cpu_intf;

    log = new("cpu", "env");

endfunction

function void cpu_env::gen_cfg();
    super.gen_cfg();
endfunction

function void cpu_env::build();
    super.build();

    gen2drv_chan = new("CPU Generator to Driver Channel", "channel");
    cpu_gen = new("CPU Generator", 1, gen2drv_chan);
    cpu_drv = new("CPU Driver", 1, cpu_intf, gen2drv_chan);
    cpu_scb  = new("CPU Scoreboard");

    cpu_drv_cbs_scb = new(cpu_scb);
    cpu_drv.append_callback(cpu_drv_cbs_scb);

endfunction

task cpu_env::reset_dut();
    super.reset_dut();

    cpu_drv.reset();

endtask

task cpu_env::cfg_dut();
    super.cfg_dut();

endtask

task cpu_env::start();
    super.start();

    cpu_gen.start_xactor();
    cpu_drv.start_xactor();
endtask

task cpu_env::wait_for_end();
    super.wait_for_end();

    fork
        cpu_gen.notify.wait_for(cpu_trans_atomic_gen::DONE);
    join_any

endtask

task cpu_env::stop();
    super.stop();

    cpu_gen.stop_xactor();
    cpu_drv.stop_xactor();

endtask

task cpu_env::cleanup();
    super.cleanup();

endtask

task cpu_env::report();
    super.report();

endtask

`endif


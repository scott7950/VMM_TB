`ifndef __CPU_TRANS_SV__
`define __CPU_TRANS_SV__

class cpu_trans extends vmm_data;

static  vmm_log log = new("cpu_trans", "class");

rand logic [7:0] addr;
rand logic rw;
rand logic [31:0] dout;
logic [31:0] din = 32'h0;

extern function new();
extern virtual function vmm_data copy(vmm_data to);
extern virtual function string psdisplay(string prefix );

endclass

function cpu_trans::new();
    super.new(this.log);
endfunction

function vmm_data cpu_trans::copy(vmm_data to = null);
    cpu_trans cpy;

    if(to == null)
        cpy = new();
    else if(!$cast(cpy, to)) begin
        `vmm_fatal(this.log, "Cannot cast to to cpy in cpu_trans");
        copy = null;
        return copy;
    end

    super.copy_data(cpy);

    cpy.addr = this.addr;
    cpy.rw   = this.rw;
    cpy.dout = this.dout;
    cpy.din  = this.din;

    copy = cpy;
endfunction

function string cpu_trans::psdisplay(string prefix = "Note");
  $write(psdisplay, "[%s]%t addr = %0h, dout = %0h, rw = %d, din = %0h", prefix, $realtime, addr, dout, rw, din);
endfunction

`vmm_channel(cpu_trans)
`vmm_atomic_gen(cpu_trans, "CPU Transaction Atomic")
`vmm_scenario_gen(cpu_trans, "CPU Transaction Scenario")

`endif


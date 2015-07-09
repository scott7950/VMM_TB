`ifndef __CPU_SB_SV__
`define __CPU_SB_SV__

`include "vmm.sv"
`include "cpu_trans.sv"
`include "cpu_driver.sv"

class cpu_sb;

string name;

logic [31:0] cpu_reg [7:0];
integer error_no = 0;
integer total_no = 0;

extern function new(string name = "CPU Scoreboard");
extern virtual function bit compare(vmm_data data);
extern virtual function report(string prefix);

endclass

//class cpu_driver_to_sb extends cpu_driver_callbacks;
//    cpu_sb cpu_scb;
//
//    function new(cpu_sb cpu_scb);
//        this.cpu_scb = cpu_scb;
//    endfunction: new
//
//    virtual task driver_post_tx (cpu_driver xactor, cpu_trans trans);
//        cpu_scb.compare(trans);
//    endtask
//
//endclass

function cpu_sb::new(string name);
    this.name = name;

    for(int i=0; i<128; i++) begin
        cpu_reg[i] = 32'h0;
    end
endfunction

function bit cpu_sb::compare(vmm_data data);
    cpu_trans tr;
    string message;

    $cast(tr, data);

    if(tr.rw == 1'b0) begin
        cpu_reg[tr.addr] = tr.din;
    end
    else if(tr.rw == 1'b1) begin
        if(cpu_reg[tr.addr] != tr.din) begin
            message = $psprintf("[Error] %t Comparision result is not correct\n", $realtime);
            message = { message, $psprintf("cpu_reg[%d] = %0h, tr.din = %0h\n", tr.addr, cpu_reg[tr.addr], tr.din) };
            $display(message);
            error_no++;
        end
        else begin
            $display("[Note] %t comparison correct", $realtime);
        end
    end
    else begin
        $display("[Error] tr.rw can only be 0 or 1");
        error_no++;
    end
endfunction

function cpu_sb::report(string prefix);
    $display("Total: %d, Error: %d", total_no, error_no);
endfunction

`endif


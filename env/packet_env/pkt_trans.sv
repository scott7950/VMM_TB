`ifndef __PKT_TRANS_SV__
`define __PKT_TRANS_SV__

`include "vmm.sv"

class pkt_trans extends vmm_data;

static  vmm_log log = new("pkt_trans", "class");

typedef enum {GOOD, BAD} head_type;
typedef enum {LONG, SHORT, NORMAL} packet_length;
rand head_type     pkt_head_type     ;
rand packet_length pkt_packet_length ;
rand logic [15:0] header     ;
rand logic [7:0 ] payload[$] ;

extern function new();
extern virtual function vmm_data copy(vmm_data to);
extern virtual function string psdisplay(string prefix );
extern function bit compare(vmm_data to, output string diff, input int kind = -1);
extern function int unsigned byte_pack(ref logic [7:0] bytes[], input int unsigned offset, input int kind = -1);

constraint con_head_type {
    solve pkt_head_type before header;
    pkt_head_type dist {GOOD := 5, BAD := 1};
    (pkt_head_type == GOOD) -> (header == 16'h55d5);
    (pkt_head_type == BAD) -> (header inside {[0:16'h55d4], [16'h55d6:16'hffff]});
}

constraint con_pkt_len {
    solve pkt_packet_length before payload;
    pkt_packet_length dist {LONG := 1, SHORT := 1, NORMAL := 5};
    (pkt_packet_length == LONG) -> (payload.size() inside {[0:49]});
    (pkt_packet_length == SHORT) -> (payload.size() inside {[50:500]});
    (pkt_packet_length == NORMAL) -> (payload.size() inside {[501:600]});
}

endclass

function pkt_trans::new();
     super.new(this.log);
endfunction

function bit pkt_trans::compare(vmm_data to, output string diff, input int kind = -1);
    pkt_trans tr;

    $cast(tr, to);

    if(header != tr.header) begin
        diff = "Header Mismatch:\n";
        diff = { diff, $psprintf("Header Sent:  %p\nHeader Received: %p", header, tr.header) };
        return 0;
    end

    if (payload.size() != tr.payload.size()) begin
        diff = "Payload Size Mismatch:\n";
        diff = { diff, $psprintf("payload.size() = %0d, tr.payload.size() = %0d\n", payload.size(), tr.payload.size()) };
        return 0;
    end

    if (payload == tr.payload) ;
    else begin
        diff = "Payload Content Mismatch:\n";
        diff = { diff, $psprintf("Packet Sent:  %p\nPkt Received: %p", payload, tr.payload) };
        return 0;
    end

    diff = "Successfully Compared";
    return 1;
endfunction

function string pkt_trans::psdisplay(string prefix);
    $write(psdisplay, "[%s]%t", prefix, $realtime);
    $write(psdisplay, "    [%s]%t header = %0h, payload size = %0d", prefix, $realtime, header, payload.size());
    foreach(payload[i])
        $display(psdisplay, "    [%s]%t payload[%0d] = %0d", prefix, $realtime, i, payload[i]);
endfunction

function int unsigned pkt_trans::byte_pack(ref logic [7:0] bytes[], input int unsigned offset, input int kind = -1);
    if(bytes.size() >= 2) begin
        header[15:8] = bytes[0];
        header[7:0]  = bytes[1];
    end

    for(int i=2; i<bytes.size(); i++) begin
        payload.push_back(bytes[i]);
    end

    return 1;

endfunction

function vmm_data pkt_trans::copy(vmm_data to = null);
    pkt_trans cpy;

    if(to == null)
        cpy = new();
    else if(!$cast(cpy, to)) begin
        `vmm_fatal(this.log, "Cannot cast to to cpy in pkt_trans");
        copy = null;
        return copy;
    end

    super.copy_data(cpy);

    cpy.pkt_head_type     = this.pkt_head_type ;
    cpy.pkt_packet_length = this.pkt_packet_length ;
    cpy.header = this.header;
    foreach(this.payload[i]) begin
        cpy.payload.push_back(this.payload[i]);
    end

    copy = cpy;
endfunction

`vmm_channel(pkt_trans)
`vmm_atomic_gen(pkt_trans, "Packet Transaction Atomic")
`vmm_scenario_gen(pkt_trans, "Packet Transaction Scenario")

`endif


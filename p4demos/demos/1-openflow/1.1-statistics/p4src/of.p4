
#include "includes/headers.p4"
#include "includes/parser.p4"
#include "includes/counters.p4"

action _no_op() {
    drop();
}
action _drop() {
    drop();
}

// Action and table to count packets and bytes. Also load the start_ts to be matched against next table.
action do_count(entry_index) {
    modify_field(my_metadata.register_index, entry_index); // Save the register index
    modify_field(my_metadata.pkt_ts, intrinsic_metadata.ingress_global_timestamp); // Load packet timestamp in custom metadata

    // Update packet counter (read + add + write)
    register_read(my_metadata.pkt_count, my_packet_counter, my_metadata.register_index);
    add_to_field(my_metadata.pkt_count, 1);
    register_write(my_packet_counter, my_metadata.register_index, my_metadata.pkt_count);

    // Update byte counter (read + add + write)
    register_read(my_metadata.byte_count, my_byte_counter, my_metadata.register_index);
    add_to_field(my_metadata.byte_count, standard_metadata.packet_length);
    register_write(my_byte_counter, my_metadata.register_index, my_metadata.byte_count);
    
    // Cant do the following if register start_ts is associated to another table (eg: duration_table)...
    // Semantic error: "static counter start_ts assigned to table duration_table cannot be referenced in an action called by table counter_table"
    register_read(my_metadata.tmp_ts, start_ts, entry_index); // Read the start ts for the flow

}
table counter_table {
    reads {
        ipv4.srcAddr : exact;
        ipv4.dstAddr : exact;
    }
    actions {
        do_count;
        _no_op;
    }
    size : 1024;
}

// Action and table to update the start and end timestamp of the flow.
// Optionally, the duration can as well be stored in a register.

// Action is called only when start_ts=0 (value loaded in my_metadata from my_count action)
action update_start_ts(){
    register_write(start_ts, my_metadata.register_index, my_metadata.pkt_ts); // Update start_ts
    update_duration();
}
// Default action: only update the timestamp for the last matched packet and the duration
action update_duration(){
    register_write(last_ts, my_metadata.register_index, my_metadata.pkt_ts); // Update ts of the last seen packet  
    subtract_from_field(my_metadata.pkt_ts, my_metadata.tmp_ts); // Calculate duration
    register_write(flow_duration, my_metadata.register_index, my_metadata.pkt_ts); // Optional: save duration in stateful register
}
table duration_table{
    reads{
        my_metadata.tmp_ts : exact;
    }
    actions{
        update_start_ts;
        update_duration;
    }
}

control ingress { 
  apply(counter_table);
  apply(duration_table);
}


table table_drop {
    actions { 
        _drop;
    }
}
control egress {
    apply(table_drop);
}

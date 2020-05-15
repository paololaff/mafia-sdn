
#include "includes/headers.p4"
#include "includes/parser.p4"
#include "includes/counters.p4"

#define NOTIFICATION_SESSION_ID 999
#define NOTIFICATION_REASON_THRESHOLD_PKT   1
#define NOTIFICATION_REASON_THRESHOLD_BYTE  2

action _drop() { drop(); }
action _no_op(){ no_op(); }

/*action packet_counter_reset(){
    register_write(my_byte_counter, devoflow_metadata.register_index_bytes, 0);
}*/
action do_count_bytes(entry_index, byte_threshold){
    modify_field(devoflow_metadata.register_index_bytes, entry_index); // Save the register index...
    register_read(devoflow_metadata.byte_count, my_byte_counter, devoflow_metadata.register_index_bytes); // Read byte counter
    add_to_field(devoflow_metadata.byte_count, standard_metadata.packet_length);
    register_write(my_byte_counter, devoflow_metadata.register_index_bytes, devoflow_metadata.byte_count);

    modify_field(devoflow_metadata.byte_threshold, byte_threshold); // To check in the control loop
}
table byte_counter_table {
    reads {
        ipv4.srcAddr : exact;
        ipv4.dstAddr : exact;
        tcp.dstPort : exact;
    }
    actions {
        do_count_bytes;
        _no_op;
    }
    size : N_FLOWS_ENTRIES;
}

/*action packet_counter_reset(){
    register_write(my_packet_counter, devoflow_metadata.register_index_packets, 0);
}*/
action do_count_packets(entry_index, packet_threshold) {
    modify_field(devoflow_metadata.register_index_packets, entry_index); // Save the register index...
    register_read(devoflow_metadata.packet_count, my_packet_counter, devoflow_metadata.register_index_packets); // Read packet counter
    add_to_field(devoflow_metadata.packet_count, 1);
    register_write(my_packet_counter, devoflow_metadata.register_index_packets, devoflow_metadata.packet_count);

    modify_field(devoflow_metadata.packet_threshold, packet_threshold); // To check in the control loop
}
table packet_counter_table {
    reads {
        ipv4.srcAddr : exact;
        ipv4.dstAddr : exact;
        tcp.dstPort : exact;
    }
    actions {
        do_count_packets;
        _no_op;
    }
    size : N_FLOWS_ENTRIES;
}


field_list clone_fields_copy {
    devoflow_metadata;
    standard_metadata; // For "instance_type" field!
}
action do_clone_reason_threshold_bytes() {
    modify_field(devoflow_metadata.notification_counter_val, devoflow_metadata.byte_count);
    modify_field(devoflow_metadata.notification_reason, NOTIFICATION_REASON_THRESHOLD_BYTE);
    clone_ingress_pkt_to_egress(NOTIFICATION_SESSION_ID, clone_fields_copy); // Clone packet and send to CPU for notification
    register_write(my_byte_counter, devoflow_metadata.register_index_bytes, 0); // Reset the counter: concurrency bug if another packet is in action do_count?!?!?
}
table clone_bytes {
    actions { do_clone_reason_threshold_bytes; }
}

action do_clone_reason_threshold_packets() {    
    modify_field(devoflow_metadata.notification_counter_val, devoflow_metadata.packet_count);
    modify_field(devoflow_metadata.notification_reason, NOTIFICATION_REASON_THRESHOLD_PKT);
    clone_ingress_pkt_to_egress(NOTIFICATION_SESSION_ID, clone_fields_copy); // Clone packet and send to CPU for notification
    register_write(my_packet_counter, devoflow_metadata.register_index_packets, 0); // Reset the counter
}
table clone_packets {
    actions { do_clone_reason_threshold_packets; }
}

control ingress {
    apply(byte_counter_table){
        hit{
            if(devoflow_metadata.byte_count > devoflow_metadata.byte_threshold){ apply(clone_bytes); }
        }
    }
    apply(packet_counter_table){
        hit{
            if(devoflow_metadata.packet_count > devoflow_metadata.packet_threshold){ apply(clone_packets); }
        }
    }
}




action do_notification() {
    add_header(notification_header);
    modify_field(notification_header.device, 0);
    modify_field(notification_header.reason, devoflow_metadata.notification_reason);
    modify_field(notification_header.counter_val, devoflow_metadata.notification_counter_val);

    truncate(SIZEOF_NOTIFICATION_PACKET);
}

table notification {
    reads{ standard_metadata.instance_type: exact; }
    actions { do_notification; _no_op; }
    size : N_FLOWS_ENTRIES;
}

table table_drop {
    actions { _drop; }
}
control egress {
    apply(notification){
        miss{ apply(table_drop); }
    }
}

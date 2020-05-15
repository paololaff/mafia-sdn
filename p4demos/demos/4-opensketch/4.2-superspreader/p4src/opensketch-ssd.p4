
#include "includes/headers.p4"
#include "includes/parser.p4"
#include "includes/sketch-ssd.p4"

action _drop() { drop(); }
action _no_op(){ no_op(); }

action do_ssd_sketch(){
    modify_field_with_hash_based_offset(ssd_metadata.bitmap_idx, 0, bitmap_hash, 64);
    modify_field_with_hash_based_offset(ssd_metadata.countmin_idx_1, 0, countmin_hash_1, COUNTMIN_SIZE_M); 
    modify_field_with_hash_based_offset(ssd_metadata.countmin_idx_2, 0, countmin_hash_2, COUNTMIN_SIZE_M); 
    modify_field_with_hash_based_offset(ssd_metadata.countmin_idx_3, 0, countmin_hash_3, COUNTMIN_SIZE_M); 
    modify_field_with_hash_based_offset(ssd_metadata.countmin_idx_4, 0, countmin_hash_4, COUNTMIN_SIZE_M); 
    
    register_write(ssd_sketch, (0 * COUNTMIN_SIZE_M) + (ssd_metadata.countmin_idx_1 * BITMAP_SIZE) + ssd_metadata.bitmap_idx, 1);
    register_write(ssd_sketch, (1 * COUNTMIN_SIZE_M) + (ssd_metadata.countmin_idx_2 * BITMAP_SIZE) + ssd_metadata.bitmap_idx, 1);
    register_write(ssd_sketch, (2 * COUNTMIN_SIZE_M) + (ssd_metadata.countmin_idx_3 * BITMAP_SIZE) + ssd_metadata.bitmap_idx, 1);
    register_write(ssd_sketch, (3 * COUNTMIN_SIZE_M) + (ssd_metadata.countmin_idx_4 * BITMAP_SIZE) + ssd_metadata.bitmap_idx, 1);
    
}
table table_ssd{
    actions{do_ssd_sketch; _no_op;}
}

control ingress {
    if(valid(tcp)){
        if(ipv4.protocol == IPPROTO_TCP){
            apply(table_ssd);
        }
    }
}

table table_drop {
    actions { _drop; }
}
control egress {
    apply(table_drop);
}

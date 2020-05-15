
#include "hash.p4"

register sketch_path_tags{
    width: VERIDP_BF_SIZE;
    instance_count: SKETCH_SIZE;
}

register sketch_path_changes{
    width: 32;
    instance_count: SKETCH_SIZE;
}

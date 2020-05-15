# Program using MAFIA API as of documentation:
# 
# declare bloomfilter bf<1>[16]
# declare hash_set bf_hash_set (H=3): {metadata.input_port | metadata.switch_id | metadata.output_port } 
#                                      -> {index<4>}
# 
# declare sketch paths_sketch<16>[6][128]
# declare sketch n_changes_sketch<16>[6][128]
# declare hash_set countmin_hash_set (H=4, countmin_hash): {ipv4.src, ipv4.dst, ipv4.protocol, tcp.src, tcp.dst} 
#                                                          -> {h<3>, index<7>}
# 
# ( 
#   BloomFilter( lambda(bf_hash_set):{ bf[index] = 1 }, bf) 
#   >> Tag( bf[] | tcp.checksum, tcp.checksum ) 
#   >> BloomFilter( lambda(bf_hash_set):{ bf[index] = 0 }, bf)
# )
# + 
# ( 
#   Match(metadata.is_last_hop == 1)
#   >>
#   (
#     Match( all(countmin_hash_set):{ paths_sketch[h][index] != tcp.checksum } )
#     (
#       Sketch( lambda(countmin_hash_set)):{ paths_sketch[h][index] = tcp.checksum }, paths_sketch))
#       >>
#       Sketch( lambda(countmin_hash_set)):{ n_changes_sketch[h][index] = n_changes_sketch[h][index] + 1 }, n_changes_sketch))
#     )
#   )
# )
# 

from mafia_lang.primitives import *

bf = BloomFilter("bf", 16, 1)
bf_hash_set = HashFunction( \
                            "bf_hash_set", \
                            "veridp_hash", \
                            3, \
                            [ "standard_metadata.ingress_port", "mafia_metadata.switch_id", "standard_metadata.egress_port"], \
                            [ HashOutputVar("index", 4) ] \
                          )

paths_sketch = Sketch("paths_sketch", 6, 128, 16)
n_changes_sketch = Sketch("n_changes_sketch", 6, 128, 16)

countmin_hash_set = HashFunction( \
                                    "countmin_hash_set", \
                                    "countmin_hash", \
                                    6, \
                                    [ "ipv4.src", "ipv4.dst", "tcp.src", "tcp.dst", "ipv4.protocol"], \
                                    [ HashOutputVar("h", 3), HashOutputVar("index", 7) ] \
                                )

# In the below Tag primitive, the notation bf[] indicates serialization of the whole data structure.
location_bf = BloomFilter_op("location_bf", "lambda(bf_hash_set): { bf[index] = 1 }", bf) \
              >> Tag("tag_location_bf", "bf[] | tcp.checksum", "tcp.checksum") \
              >> BloomFilter_op("reset_location_bf", "lambda(bf_hash_set): { bf[index] = 0 }", bf)


sketches = Match("is_exit_switch", "metadata.is_last_hop == 1", None) \
           >> ( \
                  Match("check_path_change", " all(countmin_hash_set):{ paths_sketch[h][index] } != tcp.checksum ", None) \
                  >> \
                  (
                    Sketch_op("paths_sketch", "lambda(countmin_hash_set): { paths_sketch[h][index] = tcp.checksum }", paths_sketch) \
                    + \
                    Sketch_op("n_changes_sketch", "lambda(countmin_hash_set): { n_changes_sketch[h][index] = n_changes_sketch[h][index] + 1 }", n_changes_sketch) \
                  )
              ) 

measurement = (location_bf + sketches)





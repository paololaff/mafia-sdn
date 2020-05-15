# Program using MAFIA API as of documentation:
# declare sketch countmin_sketch<32>[4][256]
# declare hash_set countmin_hash (H=4): {ipv4.src, ipv4.dst, ipv4.protocol, tcp.src, tcp.dst} -> {h<2>, key<8>}
# Sketch( lambda(countmin_hash): {countmin_sketch[h][key] = countmin_sketch[h][key] + 1}, countmin_sketch) 


# Corresponding Python code for the compiler:

from mafia_lang.primitives import *

countmin_sketch = Sketch('countmin_sketch', 4, 256, 32)

# IMPORTANT NOTICE: hash function  'countmin_hash' must pre-exist
# (i.e,  one of the hash functions that is known *BY THE COMPILER*)
# also the max number of hash functions is known to the compiler

countmin_hash = HashFunction( \
                                'countmin_hash', \
                                4, \
                                [ "ipv4.src", "ipv4.dst", "ipv4.protocol", "tcp.src", "tcp.dst"], \
                                [ HashOutputVar('h', 2), HashOutputVar('key', 8) ] \
                            )

s = Sketch_op('countmin_sketch', 'lambda(countmin_hash): countmin_sketch[h][key] = countmin_sketch[h][key] + 1', countmin_sketch)

measurement = s

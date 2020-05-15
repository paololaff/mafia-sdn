import importlib

from examples_toy           import toy#, sumyyah
# from measurements           import \
#                                     m01_openflow, \
#                                     m06_sampling_stochastic, \
#                                     m07_sampling_deterministic, \
#                                     m02_sketch_countmin, \
#                                     m03_sketch_pcsa, \
#                                     m04_sketch_hll, \
#                                     m05_devoflow, \
#                                     m08_netsight, \
#                                     m09_veridp, \
#                                     m10_mafia_hh, \
#                                     m11_mafia_topk_congested, \
#                                     m12_mafia_pathchanges, \
#                                     m13_mafia_pathlatency, \
#                                     m14_mafia_tm

from mafia_lang.operators              import *
from mafia_lang.primitives             import *
from mafia_lang.p4objects.p4hash       import *
from mafia_lang.p4objects.p4headers    import *
from mafia_lang.p4objects.p4objects    import *
from mafia_lang.p4objects.p4state      import *
from mafia_lang.util.log               import _log_level, _LOG_LEVEL_STRINGS
# from mafia_lang.observer               import Observable, Observer

import os, sys, inspect
import argparse, logging

#### EXAMPLE SELECT ####
# example = sumyyah
# example = toy
# example = tags
# example = m01_openflow
# example = m06_sampling_stochastic
# example = m07_sampling_deterministic
# example = m02_sketch_countmin
# example = m03_sketch_pcsa
# example = m04_sketch_hll
# example = m05_devoflow
# example = m08_netsight
# example = m09_veridp
# example = m10_mafia_hh
# example = m11_mafia_topk_congested
# example = m12_mafia_pathchanges
# example = m13_bala_measurement
# example = m13_mafia_pathlatency
# example = m14_mafia_tm
#### EXAMPLE SELECT ####

parser = argparse.ArgumentParser(description="Mafia P4 Compiler")
parser.add_argument('--measurement', '-u', type=str, help='Measurement to be compiled.', required=True, default=None, dest='measurement', nargs='?')
parser.add_argument('--log', '-l', type=_log_level, help='Logging level. {0}'.format(_LOG_LEVEL_STRINGS), required=False, default='DEBUG', dest='loglevel', nargs='?')

args = parser.parse_args()

logging.basicConfig(level=args.loglevel, format='%(name)-12s: Line %(lineno)-4d - %(levelname)-8s - %(message)s')
logger = logging.getLogger(__name__)

example = importlib.import_module('measurements.'+args.measurement)

(build_dir, build_filename, build_commands_filename, build_topology_filename) = mafia_create_build_dir(example)
p4measurement_file = open(build_filename,"w")
p4headers_file = open(build_dir+'/headers.p4', "w")
p4tables_file = open(build_dir+'/tables.p4', "w")
p4commands_file = open(build_commands_filename,"w")
p4measurement_file.write("\n#include \"headers.p4\"\n#include \"tables.p4\"\n#include \"../../routing.p4\"\n#include \"../../parser.p4\"\n\n\n")

# if args.measurement is not None:
#     measurement = args.measurement
# else:
#     measurement = example.measurement

measurement = example.measurement

logging.debug("Measurement AST\n%s\n" % measurement)

p4_ast_root = P4ObjectAST("ingress")
p4_program = P4Program()

p4_program.headers.declare_ethernet()
p4_program.headers.declare_vlan()
p4_program.headers.declare_ipv4()
p4_program.headers.declare_udp()
p4_program.headers.declare_tcp()
p4_program.headers.declare_icmp()
p4_program.headers.declare_standard_metadata()
p4_program.headers.declare_intrinsic_metadata()
p4_program.headers.declare_queueing_metadata()
p4_program.headers.declare_forwarding_metadata()
p4_program.headers.declare_mafia_metadata()
p4_program.headers.declare_rng_fake_metadata()

# hash_count_min = P4HashCountMin("countmin_hash", { ("h", HashOutputVar('h', 2)), ("index", HashOutputVar('index', 8))})
hash_count_min = P4HashCountMin("countmin_hash", 2)
hash_pcsa = P4HashPCSA("pcsa_hash", 2)
hash_hll = P4HashHLL("hll_hash", 2)
hash_veridp = P4HashVeriDP("veridp_hash", 1)
p4_program.register_hash(hash_count_min)
p4_program.headers.register_mafia_metadata_field(hash_count_min.declare_internal_metadata())
p4_program.register_hash(hash_pcsa)
p4_program.headers.register_mafia_metadata_field(hash_pcsa.declare_internal_metadata())
p4_program.register_hash(hash_hll)
p4_program.headers.register_mafia_metadata_field(hash_hll.declare_internal_metadata())
p4_program.register_hash(hash_veridp)
p4_program.headers.register_mafia_metadata_field(hash_veridp.declare_internal_metadata())

p4_program.headers.register_mafia_metadata_field([("flow_index", 64)])

example_vars = vars(example)
for var in example_vars:
    s = example_vars[var]
    if isinstance(s, P4StateVariable):
        p4_program.register_state(s)
p4_program.register_state(HashFieldList("sample_copy_fields", ["mafia_metadata", "standard_metadata", "intrinsic_metadata"]))
p4_program.register_state(HashFieldList("rng_input", ["rng_metadata"]))
p4_program.register_state(HashFunctionImpl("uniform_probability_hash", "my_uniform_probability", ["rng_input"], 32 ))
# measurement._notify_next(p)
# measurement.on_compile(p4_ast)

logging.debug("Compiling...")
(p4_ast_in, p4_ast_out) = measurement.on_compile(p4_ast_root, p4_program, 0, measurement.get_combinator_type())

p4_program.ingress_loop = p4ctrl_in % ('ingress', '\n'.join(p.generate_code(p4_program, None, 1) for p in p4_ast_in))
p4_program.egress_loop = p4ctrl_out % ('egress', '\n'.join(p.generate_code(p4_program, None, 1) for p in p4_ast_out))

# p4measurement_file = open("build//measurement.p4","w")
# p4commands_file = open("build//commands.txt","w")
# p4measurement_file.write("#include \"../../parser.p4\"\n")


logging.debug("Header definitions:\n\n")
print(p4_program.headers)
# p4headers_file.write("\n#include <tofino/intrinsic_metadata.p4>\n\n")
p4headers_file.write(p4_program.headers.to_string() + "\n")

print()
p4measurement_file.write("\n")
logging.debug("State and hash declaration:\n")
print(p4_program.state)
p4measurement_file.write(p4_program.state.to_string() + "\n")
print()
p4measurement_file.write("\n")
logging.debug("Ingress pipeline:\n")
print(p4_program.ingress_loop)
p4measurement_file.write(p4_program.ingress_loop + "\n")
print()
p4measurement_file.write("\n")
p4measurement_file.write("\n")
logging.debug("Egress pipeline:\n")
print(p4_program.egress_loop)
p4measurement_file.write(p4_program.egress_loop + "\n")
print()
p4measurement_file.write("\n")
logging.debug("Table definition:\n")
for a,b in p4_program.tables.items():
    print(b)
    p4tables_file.write(b + "\n")
print()
p4measurement_file.write("\n")
logging.debug("Action definition:\n")
for a,b in p4_program.actions.items():
    print(b)
    p4measurement_file.write(b + "\n")
print()
p4measurement_file.write("\n")
# table_set_default   table_src_mac_overwrite _drop
# table_add           table_src_mac_overwrite             do_src_mac_overwrite                                   1         => 00:00:00:00:00:01
# table_add           table_src_mac_overwrite             do_src_mac_overwrite                                   2         => 00:00:00:00:00:02
# table_add           table_src_mac_overwrite             do_src_mac_overwrite                                   3         => 00:00:00:00:00:03

fwd_commands = """

table_set_default   table_route_next_hop _drop
table_add           table_route_next_hop                do_route_next_hop                            10.0.0.1/32     => 00:00:00:00:00:01 1
table_add           table_route_next_hop                do_route_next_hop                            10.0.0.2/32     => 00:00:00:00:00:02 2
table_add           table_route_next_hop                do_route_next_hop                            10.0.0.3/32     => 00:00:00:00:00:03 3"""

for c in p4_program.commands:
    print(c)
    p4commands_file.write(c + "\n")
p4commands_file.write(fwd_commands + "\n")
print()


p4measurement_file.close()
p4headers_file.close()
p4tables_file.close()
p4commands_file.close()

# realpath() will make your script run, even if you symlink it :)
# cmd_folder = os.path.realpath(os.path.abspath(os.path.split(inspect.getfile( inspect.currentframe() ))[0]))
# if cmd_folder not in sys.path:
#     sys.path.insert(0, cmd_folder)

# # Use this if you want to include modules from a subfolder
# cmd_subfolder = os.path.realpath(os.path.abspath(os.path.join(os.path.split(inspect.getfile( inspect.currentframe() ))[0],"mafia_lang")))
# if cmd_subfolder not in sys.path:
#     sys.path.insert(0, cmd_subfolder)
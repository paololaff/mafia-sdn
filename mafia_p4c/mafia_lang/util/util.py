
import os, errno

def indent_str(s, indent=4):
    return "\n".join(indent * " " + i for i in s.splitlines())


def repr_plus(ss, indent=4, sep="\n", prefix=""):
    if isinstance(ss, str):
        ss = [ss]
    return indent_str(sep.join(prefix + repr(s) for s in ss), indent)

def traverse(o, tree_types=(list, tuple)):
    if isinstance(o, tree_types):
        for value in o:
            for subvalue in traverse(value, tree_types):
                yield subvalue
    else:
        yield o

def unpack_list(l):
    [op, term, *rest] = l
    return [op, term, *rest]

def mafia_create_build_dir(code):
    name = code.__name__
    directory = 'build/'+name.replace('.', '/')
    try:
        os.makedirs(directory)
    except OSError as e:
        if e.errno != errno.EEXIST:
            raise
        else:
            pass
    build_dir = directory
    build_filename = directory+'/'+name.split('.')[1]+'.p4'
    build_commands_filename = directory+'/'+'commands.txt'
    build_topology_filename = directory+'/'+'topology.txt'
    return (build_dir, build_filename, build_commands_filename, build_topology_filename)

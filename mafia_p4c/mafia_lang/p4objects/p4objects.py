
# from abc import ABCMeta, abstractmethod
from anytree    import NodeMixin
from .p4code    import *
from .p4state   import *
from .p4headers import *
from .p4actions import *
from ..util.log import *

_SCOPE_TYPE = ['PARALLEL', 'SEQUENTIAL']


class P4Program(object):

    def __init__(self, tables = {}, hashes = {}, actions = {}):
        self.state = P4MeasurementState()
        self.headers = P4Headers()
        self.tables = dict(tables)
        self.hashes = dict(hashes)
        self.actions = dict(actions)
        self.commands = list()
        self.ctrl_loop = ''
        self.egress_loop = ''
        self.ingress_loop = ''

    def register_hash(self, h):
        self.hashes[h.name] = h

    def lookup_hash(self, h):
        hash_fun = None
        try:
            hash_fun = self.hashes[h.family]
        except:
            raise MafiaSemanticError("Semantic error: %s" % h.family, "Hash function family is not defined")
        return hash_fun

    def register_state(self, s):
        self.state.add_p4statevariable(s)
        state_metadata = s.declare_metadata()
        if state_metadata: self.headers.register_mafia_metadata_field(state_metadata)

    def add_command(self, command):
        self.commands.append(command)

class P4Scope(NodeMixin):

    def __init__(self, parent = None):
        self._parent = parent
        self.p4object = None

# class P4Program(object):
#     def __init__(self):
#         self.scopes = list()
#         self.current_scope = None

#     def scope_open(self, scope_type):
#         if(scope_type == 'SEQUENTIAL'):
#             self.current_scope = P4Scope(self.current_scope)
#         elif(scope_type == 'PARALLEL'):
#             self.current_scope = P4Scope(self.current_scope.parent)
#         return self.current_scope

#     def scope_close(self):
#         if(not self.current_scope):
#             raise RuntimeError('No P4Scope to close')
#         else:
#             if(not self.current_scope.parent):
#                 self.scopes.append(self.current_scope)
#                 self.current_scope = None
#             else:
#                 self.current_scope = self.current_scope.parent
#         return self.current_scope

#     def add_table(self, table):
#         if(self.current_scope.table is None):
#             self.current_scope.table = table
#         else:
#             if(not self.current_scope.actions):
#                 self.current_scope.table += table
#             else:
#                 self.scope_open()



class P4ObjectASTBase(object):
    def __init__(self, name, parent = None):
        self.name = name
        self.logger = logging.getLogger(__name__)
        self.objects = list()

    def generate_code(self, p4_program, p4_scope, indent = 0):
        pass

    def to_string(self):
        pass

    def __str__(self):
        return self.to_string()

class P4ObjectAST(P4ObjectASTBase, NodeMixin):

    def __init__(self, name, parent = None):
        self.name = name
        self.parent = parent

    def set_parent(self, parent):
        if parent is None:
            raise TypeError
        self.parent = parent

    def inner_child(self):
        if(not self.children):
            return self
        else:
            cur = self.children[len(self.children)-1]
            while(cur is not None and cur.children):
                cur = cur.children[len(cur.children)-1]
            return cur

    def generate_code(self, p4_program, p4_scope, indent = 0):
        return '\n\n'.join("%s" % c.compile() for c in self.children)

    def to_string(self):
        s = ""
        for o in self.children:
            s += o.to_string() + "\n\n"
        return s

    def __str__(self):
        return self.to_string()

class P4Table(P4ObjectAST):

    def __init__(self, name, condition, reads, actions, parent = None):
        super(P4Table, self).__init__(name, parent)
        self.condition = condition
        self.reads = reads
        self.actions = actions
        # self.add_action('_no_op;')

    def add_action(self, action):
        self.actions.append(action)

    def generate_code(self, p4_program, p4_scope, indent = 0):
        logging.debug("%s: compile", self.name)
        p4_program.tables[self.name] = self.to_string()
        for a in self.actions:
            p4_program.actions[a.name] = a.to_string()

        children_str = '\n\n'.join("%s" % c.generate_code(p4_program, p4_scope, indent + 1) for c in self.children)# super.compile(p4_program)

        if(self.condition is not None):
            if(self.reads or self.actions):
                # ctrl_loop = indent_str((p4table_apply % self.name) + (p4table_block % (indent_str(p4table_hit % indent_str(p4ctrl_cond % (self.condition, children_str), indent + 2), indent + 1))), indent)
                ctrl_loop = indent_str(p4ctrl_cond % (self.condition, indent_str( p4table_apply % self.name, indent + 1) + ';' + children_str) , indent)
            else:
                ctrl_loop = indent_str(p4ctrl_cond % (self.condition, children_str), indent)
        else:
            if(self.children):
                if self.reads:
                    ctrl_loop = indent_str((p4table_apply % self.name) + (p4table_block % indent_str(p4table_hit % children_str, indent + 1)), indent)
                else: 
                    ctrl_loop = indent_str((p4table_apply % self.name) + (p4table_block % indent_str(p4table_miss % children_str, indent + 1)), indent)
            else:
                ctrl_loop = indent_str((p4table_apply % self.name) + ';', indent)

        # if(self.condition is not None):
        #     ctrl_loop = indent_str((p4table_apply % self.name) + (p4table_block % (p4table_hit % p4ctrl_cond % (self.condition, children_str))), indent)
        # else:
        #     if(self.children):
        #         ctrl_loop = indent_str((p4table_apply % self.name) + (p4table_block % (p4table_hit % children_str)), indent)
        #     else:
        #         ctrl_loop = indent_str((p4table_apply % self.name) + ';', indent)
        return ctrl_loop

    def to_string(self):
        if(self.reads or self.actions):
            return p4table % (self.name, "%s%s" % \
                                                ( "" if (not self.reads) else indent_str(p4table_reads % ''.join("%s: %s;" % (f, m[0]) for f,m in self.reads.items()), 1) + "\n", \
                                                  indent_str(p4table_actions % (';'.join("%s" % a.name for a in self.actions) + ';'), 1) \
                                                ) \
                             )
        else:
            return ""

    def __str__(self):
        return self.to_string()

    def __add__(self, other):
        res = None
        if(isinstance(other, P4Table)):
            res = P4Table(self.name + '_' + other.name, self.condition + '&&' + other.condition, {**self.reads, **other.reads}, self.actions + other.actions)
        elif(isinstance(other, P4ActionBase) ): #or isinstance(other, P4ActionBundle)):
            res = P4Table(self.name, self.condition, {**self.reads}, self.actions + [other])
        else:
            raise RuntimeError
        return res


from ..util.log import *
from ..util.util import indent_str
from .p4code    import *
# from .p4objects import P4ObjectAST

class P4ActionBase():
    def __init__(self, name, params):
        # super(P4ActionBase, self).__init__(name)
        self.name = name
        self.params = list(params)
        self.instructions = list()

    def add_instruction_as_str(self, instruction):
        self.instructions.append(indent_str(instruction,2))

    def __add__(self, other):
        if(isinstance(other, P4ActionBase)):
            for p in other.params:
                if p not in self.params:
                    self.params += other.params
            self.instructions += other.instructions
        else:
            raise RuntimeError
        return self

    # def __add__(self, other):
    #     if(isinstance(other, P4ActionsSequence)):
    #         res = P4ActionsSequence(self.name + '_' + other.name, self.condition + '&&' + other.condition, {**self.reads, **other.reads}, self.actions + other.actions)
    #     elif(isinstance(other, P4ActionBase) or isinstance(other, P4ActionBundle)):
    #         res = P4Table(self.name, self.condition, {**self.reads}, self.actions + [other])
    #         # other.set_parent(res)
    #     else:
    #         raise RuntimeError
    #     # self.set_parent(p4table)
    #     # other.set_parent(p4table)
    #     return res

    # def compile(self):
    #     logging.debug("%s: compile", self.name)
    #     self.p4_prog.actions[self.name] = self.to_string()
    #     return self.p4_prog
    # def __add__(self, other):
    #     res = None
    #     if(isinstance(other, P4ActionsSequence)):
    #         res = P4ActionsSequence(self.name + '_' + other.name, self.condition + '&&' + other.condition, {**self.reads, **other.reads}, self.actions + other.actions)
    #     elif(isinstance(other, P4ActionBase) or isinstance(other, P4ActionBundle)):
    #         res = P4Table(self.name, self.condition, {**self.reads}, self.actions + [other])
    #         # other.set_parent(res)
    #     else:
    #         raise RuntimeError
    #     # self.set_parent(p4table)
    #     # other.set_parent(p4table)
    #     return res

    def to_string(self):
        if self.params:# and self.params[0] == "index":
            return p4action % (self.name, ','.join("%s" % p for p in self.params), '\n'.join("%s" % i for i in self.instructions))
        else:
            return p4action % (self.name, "", '\n'.join("%s" % i for i in self.instructions))

    def __str__(self):
        return self.to_string()

    # def __add__(self, other):
    #     res = None
    #     if(isinstance(other, P4Action)):
    #         res = P4ActionBundle(self.name + '_' + other.name, \
    #                              self.params + other.params, \
    #                              [ \
    #                                  p4action_call % (self.name, ','.join("%s" % p for p in self.params)), \
    #                                  p4action_call % (other.name, ','.join("%s" % p for p in other.params)) \
    #                              ])
    #     elif(isinstance(other, P4ActionBundle)):
    #         res = P4ActionBundle(self.name + '_' + other.name, \
    #                              self.params + other.params, \
    #                              other.instructions + \
    #                              [ \
    #                                  p4action_call % (self.name, ','.join("%s" % p for p in self.params)) \
    #                              ])
    #     else:
    #         raise RuntimeError
    #     self.set_parent(res)
    #     other.set_parent(res)
    #     return res

class P4ActionNoOp(P4ActionBase):
    def __init__(self, name):
        super(P4ActionNoOp, self).__init__(name, [])
        self.name = name
        self.instructions = list()
        self.add_instruction_as_str("no_op();")

class P4ActionAddHeader(P4ActionBase):
    def __init__(self, name, header):
        super(P4ActionAddHeader, self).__init__(name, [])
        self.name = name
        self.instructions = list()
        self.add_instruction_as_str("add_header(%s);" % header)

class P4ActionGetTimestamp(P4ActionBase):
    def __init__(self, name, target, index, params):
        super(P4ActionGetTimestamp, self).__init__(name, params)
        self.add_instruction_as_str(p4action_modify_field % ('mafia_metadata.' + target, 'intrinsic_metadata.ingress_global_timestamp'))
        self.add_instruction_as_str(p4action_register_write % (target, index, 'mafia_metadata.' + target))

class P4ActionRegisterRead(P4ActionBase):
    def __init__(self, name, target, src, index, params):
        super(P4ActionRegisterRead, self).__init__(name, params)
        self.add_instruction_as_str(p4action_register_read % (target, src, index))

class P4ActionRegisterWrite(P4ActionBase):
    def __init__(self, name, target, value, index, params):
        super(P4ActionRegisterWrite, self).__init__(name, params)
        self.add_instruction_as_str(p4action_register_write % (target, index, value))

class P4ActionModifyField(P4ActionBase):
    def __init__(self, name, target, value, params):
        super(P4ActionModifyField, self).__init__(name, params)
        self.add_instruction_as_str(p4action_modify_field % (target, value))

class P4ActionAdd(P4ActionBase):
    def __init__(self, name, target, value_1, value_2):
        super(P4ActionAdd, self).__init__(name, [])
        self.add_instruction_as_str(p4action_add % (target, value_1, value_2))

class P4ActionSub(P4ActionBase):
    def __init__(self, name, target, value_1, value_2):
        super(P4ActionSub, self).__init__(name, [])
        self.add_instruction_as_str(p4action_subtract % (target, value_1, value_2))

class P4ActionFieldAdd(P4ActionBase):
    def __init__(self, name, target, value):
        super(P4ActionFieldAdd, self).__init__(name, [])
        self.add_instruction_as_str(p4action_add_to_field % (target, value))

class P4ActionFieldSub(P4ActionBase):
    def __init__(self, name, target, value):
        super(P4ActionFieldSub, self).__init__(name, [])
        self.add_instruction_as_str(p4action_subtract_from_field % (target, value))

class P4ActionFieldShiftLeft(P4ActionBase):
    def __init__(self, name, target, base, value):
        super(P4ActionFieldShiftLeft, self).__init__(name, [])
        self.add_instruction_as_str(p4action_shift_left % (target, base, value))

class P4ActionFieldShiftRight(P4ActionBase):
    def __init__(self, name, target, base, value):
        super(P4ActionFieldShiftRight, self).__init__(name, [])
        self.add_instruction_as_str(p4action_shift_right % (target, base, value))

class P4ActionFieldBitOr(P4ActionBase):
    def __init__(self, name, target, base, value):
        super(P4ActionFieldBitOr, self).__init__(name, [])
        self.add_instruction_as_str(p4action_bit_or % (target, base, value))

class P4ActionFieldBitAnd(P4ActionBase):
    def __init__(self, name, target, base, value):
        super(P4ActionFieldBitAnd, self).__init__(name, [])
        self.add_instruction_as_str(p4action_bit_and % (target, base, value))

class P4ActionTag(P4ActionBase):
    def __init__(self, name, target, params):
        super(P4ActionTag, self).__init__(name, target, params)
        self.add_instruction_as_str(p4action_modify_field % (target, 'mafia_metadata.' + target, self.params[0]))

class P4ActionHash(P4ActionBase):
    def __init__(self, name, target, hash_fun, upper, params):
        super(P4ActionHash, self).__init__(name, params)
        self.add_instruction_as_str(p4action_hash % (target, 0, hash_fun, upper))

class P4ActionDuplicate(P4ActionBase):
    def __init__(self, name, target, clone_fields, params):
        super(P4ActionDuplicate, self).__init__(name, params)
        self.add_instruction_as_str(p4action_duplicate % (target, clone_fields))

# class P4ActionCollect(P4ActionBase):
#     def __init__(self, name, target, params):
#         super(P4ActionCollect, self).__init__(name, params)
        # self.add_instruction_as_str(p4action_collect % (target, 0, hash_fun, upper))

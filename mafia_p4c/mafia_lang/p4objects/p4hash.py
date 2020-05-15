
from .p4state import *
from .p4objects import *
from .p4actions import *
from ..exception import *

class P4Hash(object):
    def __init__(self, name, outputs):
        self.name = name
        self.outputs = outputs
        # self.configuration = dict()

    # def configure_outputs(self, config):
    #     if len(self.configuration) != len(config):
    #         raise TypeError
    #     self.configuration = config

    def declare_internal_metadata(self):
        return []

    def compile(self, p4_program, name, n, inputs, outputs):
        raise MafiaSemanticError("Semantic error", "Code generation of P4Hash must be implemented by subclasses")



class P4HashCountMin(P4Hash):
    def __init__(self, name, outputs):
        super(P4HashCountMin, self).__init__(name, outputs)

    def compile(self, p4_program, name, n, inputs, outputs):
        if len(outputs) != self.outputs:
            raise MafiaSemanticError("Semantic error: hash signature mismatch", "Hash function %s does not produce %s outputs" % (self.name, len(outputs)))

        nh = 0
        table_name = 't_'+self.name+'_'+name
        action_name = 'a_'+self.name+'_'+name
        hash_fun_table = P4Table(table_name, None, {}, [])
        hash_actions = P4ActionBase(action_name, [])
        p4_program.add_command("table_set_default " + table_name + " " + action_name)
        p4_program.register_state(HashFieldList(self.name + "_fields", inputs))
        while nh < n:
            p4_program.register_state(HashFunctionImpl(self.name + "_" + str(nh+1), "murmur_"+str(nh+1), [self.name + "_fields"], outputs[1].width ))
            hash_actions += P4ActionModifyField('', "mafia_metadata."+self.name+"_"+outputs[0].name+"_"+str(nh), str(nh), []) \
                            + \
                            P4ActionHash('', "mafia_metadata."+self.name+"_"+outputs[1].name+"_"+str(nh), self.name + "_" + str(nh+1), pow(2,outputs[1].width), [])
            nh+=1
        hash_fun_table += hash_actions
        return [hash_fun_table]

class P4HashPCSA(P4Hash):
    def __init__(self, name, outputs):
        super(P4HashPCSA, self).__init__(name, outputs)

    def compile(self, p4_program, name, n, inputs, outputs):
        if len(outputs) != self.outputs:
            raise MafiaSemanticError("Semantic error: hash signature mismatch", "Hash function %s does not produce %s outputs" % (self.name, len(outputs)))

        nh = 0
        table_name = 't_'+self.name+'_'+name
        action_name = 'a_'+self.name+'_'+name
        table_pcsa_hash = P4Table(table_name, None, {}, [])
        hash_actions = P4ActionBase(action_name, [])
        p4_program.add_command("table_set_default " + table_name + " " + action_name)
        p4_program.register_state(HashFieldList(self.name + "_fields", inputs))
        while nh < n:
            mask = pow(2,(pow(2, outputs[1].width) - outputs[0].width))
            mask_str = "0x%0.8X" % (mask-1)
            p4_program.register_state(HashFunctionImpl(self.name + "_" + str(nh+1), "hash_ex", [self.name + "_fields"], pow(2,outputs[1].width) ))
            hash_actions += P4ActionHash('', "mafia_metadata."+self.name+"_"+str(nh), self.name + "_" + str(nh+1), pow(2, pow(2,outputs[1].width)) - 1, []) \
                            + \
                            P4ActionFieldShiftRight('', "mafia_metadata."+self.name+"_"+outputs[0].name+"_"+str(nh), "mafia_metadata."+self.name+"_"+str(nh), str(32-outputs[0].width)) \
                            + \
                            P4ActionFieldBitAnd('', "mafia_metadata."+self.name+"_"+str(nh), "mafia_metadata."+self.name+"_"+str(nh), mask_str)
            nh+=1
            table_pcsa_hash += hash_actions
        nh = 0
        table_pcsa_hash_lookup_zeroes = []
        while nh < n:
            table_name = 't_'+self.name+'_tcam_lookup_zeroes'+'_'+name
            action_name = 'a_'+self.name+'_tcam_lookup_zeroes'+'_'+name
            tmp = P4Table(table_name, None, {"mafia_metadata."+self.name+"_"+str(nh):("exact",'')}, []) \
                  + \
                  P4ActionModifyField(action_name, "mafia_metadata."+self.name+"_"+outputs[1].name+"_"+str(nh), "zeroes", ["zeroes"])
            p4_program.add_command("table_set_default " + table_name + " " + action_name)
            table_pcsa_hash_lookup_zeroes += [tmp]
            nh += 1
        # print(mask)
        # print(mask_str)
        # table_pcsa_hash_zeroes = P4Table('t_'+self.name+'_lookup_zeroes', None, {}, ["zeroes_run"]) + \
        #                          P4ActionModifyField()
        return [table_pcsa_hash] + table_pcsa_hash_lookup_zeroes

    def declare_internal_metadata(self):
        internal_metadata = []
        nh = 0
        while nh < self.outputs:
            # internal_metadata += [(self.name+"_value_"+str(nh), 32)]
            internal_metadata += [(self.name+"_"+str(nh), 32)]
            nh = nh+1
        return internal_metadata

class P4HashHLL(P4Hash):
    def __init__(self, name, outputs):
        super(P4HashHLL, self).__init__(name, outputs)

    def compile(self, p4_program, name, n, inputs, outputs):
        if len(outputs) != self.outputs:
            raise MafiaSemanticError("Semantic error: hash signature mismatch", "Hash function %s does not produce %s outputs" % (self.name, len(outputs)))

        nh = 0
        table_name = 't_'+self.name+'_'+name
        action_name = 'a_'+self.name+'_'+name
        table_hll_hash = P4Table(table_name, None, {}, [])
        hash_actions = P4ActionBase(action_name, [])
        p4_program.add_command("table_set_default " + table_name + " " + action_name)
        p4_program.register_state(HashFieldList(self.name + "_fields", inputs))
        while nh < n:
            mask = pow(2,(pow(2, outputs[1].width) - outputs[0].width))
            mask_str = "0x%0.8X" % (mask-1)
            p4_program.register_state(HashFunctionImpl(self.name + "_" + str(nh+1), "hash_ex", [self.name + "_fields"], pow(2,outputs[1].width) ))
            hash_actions += P4ActionHash('', "mafia_metadata."+self.name+"_"+str(nh), self.name + "_" + str(nh+1), pow(2, pow(2,outputs[1].width)) - 1, []) \
                            + \
                            P4ActionFieldShiftRight('', "mafia_metadata."+self.name+"_"+outputs[0].name+"_"+str(nh), "mafia_metadata."+self.name+"_"+str(nh), str(32-outputs[0].width)) \
                            + \
                            P4ActionFieldBitAnd('', "mafia_metadata."+self.name+"_"+str(nh), "mafia_metadata."+self.name+"_"+str(nh), mask_str)
            nh+=1
            table_hll_hash += hash_actions
        nh = 0
        table_pcsa_hash_lookup_zeroes = []
        while nh < n:
            table_name = 't_'+self.name+'_tcam_lookup_zeroes'+'_'+name
            action_name = 'a_'+self.name+'_tcam_lookup_zeroes'+'_'+name
            tmp = P4Table(table_name, None, {"mafia_metadata."+self.name+"_"+str(nh):("exact",'')}, []) \
                  + \
                  P4ActionModifyField(action_name, "mafia_metadata."+self.name+"_"+outputs[1].name+"_"+str(nh), "zeroes", ["zeroes"])
            table_pcsa_hash_lookup_zeroes += [tmp]
            p4_program.add_command("table_set_default " + table_name + " " + action_name)
            nh += 1
        return [table_hll_hash] + table_pcsa_hash_lookup_zeroes

    def declare_internal_metadata(self):
        internal_metadata = []
        nh = 0
        while nh < self.outputs:
            # internal_metadata += [(self.name+"_value_"+str(nh), 32)]
            internal_metadata += [(self.name+"_"+str(nh), 32)]
            nh = nh+1
        return internal_metadata

class P4HashVeriDP(P4Hash):
    def __init__(self, name, outputs):
        super(P4HashVeriDP, self).__init__(name, outputs)

    def compile(self, p4_program, name, n, inputs, outputs):
        if len(outputs) != self.outputs:
            raise MafiaSemanticError("Semantic error: hash signature mismatch", "Hash function %s does not produce %s outputs" % (self.name, len(outputs)))

        nh = 0
        table_name = 't_'+self.name+'_'+name
        action_name = 'a_'+self.name+'_'+name
        hash_fun_table = P4Table(table_name, None, {}, [])
        hash_actions = P4ActionBase(action_name, [])
        p4_program.add_command("table_set_default " + table_name + " " + action_name)
        p4_program.register_state(HashFieldList(self.name + "_fields", inputs))
        while nh < n:
            p4_program.register_state(HashFunctionImpl(self.name + "_" + str(nh+1), "murmur_"+str(nh+1), [self.name + "_fields"], outputs[0].width ))
            hash_actions += P4ActionHash('', "mafia_metadata."+self.name+"_"+outputs[0].name+"_"+str(nh), self.name + "_" + str(nh+1), pow(2,outputs[0].width), [])
            nh+=1
        hash_fun_table += hash_actions
        return [hash_fun_table]

# class P4HashVeriDP(P4Hash):
#     def __init__(self, name, outputs):
#         super(P4HashVeriDP, self).__init__(name, outputs)

#     def compile(self, p4_program, n, inputs, outputs):
#         if len(outputs) != self.outputs:
#             raise MafiaSemanticError("Semantic error: hash signature mismatch", "Hash function %s does not produce %s outputs" % (self.name, len(outputs)))

#         return []

#     def declare_internal_metadata(self, n):
#         internal_metadata = []
#         nh = 0
#         internal_metadata += [(),("h1_x", 16),("h2_x", 16)]
#         return internal_metadata

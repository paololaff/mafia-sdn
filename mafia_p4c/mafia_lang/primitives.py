
from .p4objects.p4ast       import *
from .p4objects.p4syntax    import *
from .p4objects.p4code      import *
from .p4objects.p4hash      import *
from .p4objects.p4state     import *
from .p4objects.p4objects   import *
from .p4objects.p4actions   import *
from .operators             import Operator
from .util.util             import *
from functools              import reduce
# from .util.lambdacode       import get_lambda_source


class Match(Operator):

    def __init__(self, name, lambda_f, obj = None):
        super(Match, self).__init__()
        self.name = name
        # self.lambda_f = lambda_f
        # self.lambda_str = get_lambda_source(self.lambda_f)
        self.lambda_str = lambda_f
        self.obj = obj
        self.p4object = None

    def on_next(self, item):
        if self.lambda_f(item):
            self._notify_next(item) 
            return True
        return False

    def on_compile(self, root, p4_program, ingress_egress_flag, parent_type):
        (lhs, bool_op, rhs) = mafia_syntax_parse_match(self.lambda_str)
        lhs_symbol = mafia_syntax_interpret_symbol(lhs)
        rhs_symbol = mafia_syntax_interpret_symbol(rhs)
        bool_op = mafia_syntax_interpret_bool_op(bool_op)
        if isinstance(lhs_symbol, (MafiaSymbolStateVarBF, MafiaSymbolStateVarSketch)):
            raise MafiaSemanticError("Semantic Error: %s" % self.lambda_str, "Sketch and Bloom filters need to be accessed with aggregation functions")
        elif isinstance(lhs_symbol, (MafiaSymbolStateVar)):
            (name, state) = p4_program.state.lookup(lhs_symbol.id)
            if isinstance(state, (Counter, Timestamp)):
                table_load_state = P4Table("t_load_" + lhs_symbol.id, None, { }, []) \
                                    + \
                                   P4ActionRegisterRead("a_load_"+lhs_symbol.id, 'mafia_metadata.'+lhs_symbol.id, lhs_symbol.id, "mafia_metadata.flow_index", [])
                table_match = P4Table("t_" + self.name, 'mafia_metadata.'+lhs_symbol.id + '' + bool_op + '' + rhs_symbol.id, {}, [])
                self.p4object = [table_load_state, table_match]
                p4_program.add_command("table_set_default " + "t_load_" + lhs_symbol.id + " " + "a_load_" + lhs_symbol.id)
            elif isinstance(state, Random):
                table_match = P4Table("t_" + self.name, 'mafia_metadata.'+lhs_symbol.id + '' + bool_op + '' + rhs_symbol.id, {}, [])
                self.p4object = [table_match]
            else:
                raise MafiaSemanticError("Semantic Error", self.lambda_str)
        elif isinstance(lhs_symbol, MafiaSymbolAggregateFunction):
            (fun, hashset, var) = mafia_syntax_parse_aggregate(lhs_symbol.id)
            (_, h) = p4_program.state.lookup(hashset)
            hash_fun = p4_program.lookup_hash(h)
            table_hash = hash_fun.compile(p4_program, self.name, h.n, h.inputs, h.outputs)
            
            var_symbol = mafia_syntax_interpret_symbol(var)
            if isinstance(var_symbol, MafiaSymbolStateVarBF):
                (bf, index) = mafia_syntax_parse_bf_ref(var)
                (name, bf_obj) = p4_program.state.lookup(bf)
                table_load_cells = P4Table("t_" + self.name + "_read_"+name, None, {}, [])
                i = 0
                actions = []
                conds = []
                while i < h.n:
                    p4_program.headers.register_mafia_metadata_field([(self.name+'_'+name+'_cell_'+str(i), bf_obj.width)])
                    symbol_index = mafia_syntax_interpret_symbol(index)
                    if isinstance(symbol_index, MafiaSymbolDecimal) or isinstance(symbol_index, MafiaSymbolHeaderField) or isinstance(symbol_index, MafiaSymbolMetadata):
                        param_index = symbol_index.id
                    elif isinstance(symbol_index, MafiaSymbolStateVar):
                        param_index = "mafia_metadata."+h.family+"_"+symbol_index.id+"_"+str(i)
                    actions += [P4ActionRegisterRead("a_"+self.name, "mafia_metadata."+self.name+'_'+name+'_cell_'+str(i), name, param_index, [])]
                    conds += ["mafia_metadata."+self.name+'_'+name+'_cell_'+str(i) + bool_op + rhs_symbol.id]
                    i = i+1

                table_load_cells += (reduce((lambda x, y: x + y), actions))
                p4_program.add_command("table_set_default " + "t_" + self.name + " " + "a_" + self.name)
                if fun == 'all':
                    table_match = P4Table("t_" + self.name, ' and '.join(c for c in conds), {}, [])
                    self.p4object = table_hash + [table_load_cells, table_match]
                elif fun == 'any':
                    table_match = P4Table("t_" + self.name, ' or '.join(c for c in conds), {}, [])
                    self.p4object = table_hash + [table_load_cells, table_match]
                else:
                    raise MafiaSemanticError("Semantic error", "Invalid aggregation function for bloom filter object")
            
            elif isinstance(var_symbol, MafiaSymbolStateVarSketch):
                (sketch, row, col) = mafia_syntax_parse_sketch_ref(var)
                (name, sketch_obj) = p4_program.state.lookup(sketch)
                table_load_cells = P4Table("t_" + self.name + "_read_"+name, None, {}, [])
                i = 0
                actions = []
                conds = []
                while i < h.n:
                    p4_program.headers.register_mafia_metadata_field([(self.name+'_'+name+'_cell_'+str(i), sketch_obj.width)])
                    symbol_row = mafia_syntax_interpret_symbol(row)
                    symbol_col = mafia_syntax_interpret_symbol(col)
                    if isinstance(symbol_row, MafiaSymbolDecimal) or isinstance(symbol_row, MafiaSymbolHeaderField) or isinstance(symbol_row, MafiaSymbolMetadata):
                        param_row = symbol_row.id
                    elif isinstance(symbol_row, MafiaSymbolStateVar):
                        param_row = "mafia_metadata."+h.family+"_"+symbol_row.id+"_"+str(i)
                    if isinstance(symbol_col, MafiaSymbolDecimal) or isinstance(symbol_col, MafiaSymbolHeaderField) or isinstance(symbol_col, MafiaSymbolMetadata):
                        param_col = symbol_col.id
                    elif isinstance(symbol_col, MafiaSymbolStateVar):
                        param_col = "mafia_metadata."+h.family+"_"+symbol_col.id+"_"+str(i)
                    param_index = param_row  + "*" + str(sketch_obj.m) + "+" + param_col
                    actions += [P4ActionRegisterRead("a_"+self.name, "mafia_metadata."+self.name+'_'+name+'_cell_'+str(i), name, param_index, [])]
                    conds += ["mafia_metadata."+self.name+'_'+name+'_cell_'+str(i) + bool_op + rhs_symbol.id]
                    i = i+1
                table_load_cells += (reduce((lambda x, y: x + y), actions))
                p4_program.add_command("table_set_default " + "t_" + self.name + " " + "a_" + self.name)
                if fun == 'all':
                    table_match = P4Table("t_" + self.name, '\n and '.join(c for c in conds), {}, [])
                    self.p4object = table_hash + [table_load_cells, table_match]
                elif fun == 'any':
                    table_match = P4Table("t_" + self.name, '\n or '.join(c for c in conds), {}, [])
                    self.p4object = table_hash + [table_load_cells, table_match]
                elif fun == 'min':
                    p4_program.headers.register_mafia_metadata_field([(self.name+'_'+name+'_min', sketch_obj.width)])
                    table_min = []
                    min_conds = []
                    i = 0
                    while i < h.n:
                        j = 0
                        min_conds = []
                        while j < h.n:
                            if i!=j:
                                min_conds += ["mafia_metadata."+self.name+'_'+name+'_cell_'+str(i) + " <= " + "mafia_metadata."+self.name+'_'+name+'_cell_'+str(j)]
                            j = j+1
                        # table_min += [P4Table("t_" + self.name+"_update_min_"+str(i), '\n and '.join(c for c in min_conds), {}, [])]
                        table_min += [P4Table("t_" + self.name+"_update_min_"+str(i), '\n and '.join(c for c in min_conds), {}, []) + P4ActionModifyField("a_"+self.name+"_update_min_"+str(i), "mafia_metadata."+self.name+'_'+name+'_min', "mafia_metadata."+self.name+'_'+name+'_cell_'+str(i), [])]
                        
                        i = i+1
                    table_match = P4Table("t_" + self.name, "mafia_metadata."+self.name+'_'+name+'_min ' + bool_op + ' ' + rhs_symbol.id, {}, [])
                    self.p4object = table_hash + [table_load_cells] + table_min + [table_match]
                elif fun == 'max':
                    p4_program.headers.register_mafia_metadata_field([(self.name+'_'+name+'_max', sketch_obj.width)])
                    table_max = []
                    max_conds = []
                    i = 0
                    j = 0
                    while i < h.n:
                        while j < h.n:
                            if i!=j:
                                max_conds += ["mafia_metadata."+self.name+'_'+name+'_cell_'+str(i) + " <= " + "mafia_metadata."+self.name+'_'+name+'_cell_'+str(j)]
                            j = j+1
                        table_min += [P4Table("t_" + self.name+"_update_max", '\n and '.join(c for c in max_conds), {}, []) + P4ActionModifyField("a_"+self.name+"_update_max_"+str(i), "mafia_metadata."+self.name+'_'+name+'_max', "mafia_metadata."+self.name+'_'+name+'_cell_'+str(i), [])]
                        p4_program.add_command("table_set_default " + "t_" + self.name+"_update_max" + " " + "a_"+self.name+"_update_max_"+str(i))
                        i = i+1
                    table_match = P4Table("t_" + self.name, "mafia_metadata."+self.name+'_'+name+'_max ' + bool_op + ' ' + rhs_symbol.id, {}, [])
                    self.p4object = table_hash + [table_load_cells] + table_max + [table_match]
                elif fun == 'sum':
                    table_sum = P4Table("t_" + self.name, None, {}, [])
                    table_sum += P4ActionModifyField('', "mafia_metadata."+self.name+'_'+name+'_sum', 0, [])
                    i = 0
                    p4_program.headers.register_mafia_metadata_field([(self.name+'_'+name+'_sum', sketch_obj.width)])
                    while i < h.n:
                        table_sum += P4ActionFieldAdd('', self.name+'_'+name+'_sum', "mafia_metadata."+self.name+'_'+name+'_cell_'+str(i))
                    table_match = P4Table("t_" + self.name, "mafia_metadata."+self.name+'_'+name+'_min' + bool_op + rhs_symbol.id, {}, [])
                    self.p4object = table_hash + [table_load_cells, table_sum, table_match]
            else:
                raise MafiaSemanticError("Semantic Error: %s" % lhs_symbol.id, "Aggregate function can be used only with sketch or bloom filters objects")
            # raise MafiaSemanticError("Semantic Error: %s" % self.lambda_str, "Not implemented")
        elif isinstance(lhs_symbol, (MafiaSymbolHeaderField, MafiaSymbolMetadata)):
            # address = mafia_syntax_check_ip_address(rhs)
            # table_load_state = P4Table("t_" + self.name, None, { "ipv4.src": ('exact', ""), "ipv4.dst": ('exact', "") }, []) \
            if lhs_symbol.id == 'ipv4.src':
                table_match = P4Table("t_match_ip_src", None, { "ipv4.src": ('lpm', "") }, []) \
                            + \
                            P4ActionModifyField("a_set_flow_index", "mafia_metadata.flow_index", "flow_index", ["flow_index"]) \
                            + \
                            P4ActionNoOp("_no_op")
                p4_program.add_command("table_set_default " + "t_match_ip_src" + " " + "_no_op")
                self.p4object = [table_match]
            elif lhs_symbol.id == 'ipv4.dst':
                table_match = P4Table("t_match_ip_dst", None, { "ipv4.dst": ('lpm', "") }, []) \
                            + \
                            P4ActionModifyField("a_set_flow_index", "mafia_metadata.flow_index", "flow_index", ["flow_index"]) \
                            + \
                            P4ActionNoOp("_no_op")
                p4_program.add_command("table_set_default " + "t_match_ip_dst" + " " + "_no_op")
                self.p4object = [table_match]
            elif lhs_symbol.id == 'mafia_metadata.is_first_hop' or lhs_symbol.id == 'mafia_metadata.is_last_hop':
                table_hop = None
                if lhs_symbol.id == 'mafia_metadata.is_first_hop':
                    table_hop = P4Table("t_check_" + self.name, None, { "ipv4.src": ('exact', ""), "ipv4.dst": ('exact', "") }, []) \
                                + \
                                P4ActionModifyField("a_" + self.name, "mafia_metadata.is_first_hop", "is_first_hop", ["is_first_hop"])
                    p4_program.add_command("table_set_default " + "t_" + self.name + " " + "a_" + self.name)
                elif lhs_symbol.id == 'mafia_metadata.is_last_hop':
                    table_hop = P4Table("t_check_" + self.name, None, { "ipv4.src": ('exact', ""), "ipv4.dst": ('exact', "") }, []) \
                                + \
                                P4ActionModifyField("a_" + self.name, "mafia_metadata.is_last_hop", "is_last_hop", ["is_last_hop"])
                    p4_program.add_command("table_set_default " + "t_" + self.name + " " + "a_" + self.name)
                table_match = P4Table("t_" + self.name, lhs_symbol.id + '' + bool_op + '' + rhs, {}, [])
                self.p4object = [table_hop, table_match]
            else:
                table_match = P4Table("t_" + self.name, lhs_symbol.id + '' + bool_op + '' + rhs, {}, [])
                self.p4object = [table_match]
        elif isinstance(lhs_symbol, (MafiaSymbolDecimal)):
            table_match = P4Table("t_" + self.name, lhs_symbol.id + '' + bool_op + '' + rhs, {}, [])
            self.p4object = [table_match]
        else:
            raise MafiaSemanticError("Semantic Error", self.lambda_str)

        if not ingress_egress_flag:
            return (self.p4object, [])
        else:
            return ([], self.p4object)

    def __repr__(self):
        return "Match [ %s ]" % self.lambda_str

class Counter_op(Operator):
    def __init__(self, name, lambda_f, counter):
        super(Counter_op, self).__init__()
        self.name = name
        self.table_name = "t_" + self.name
        self.action_name = "a_" + self.name
        # self.lambda_f = lambda_f
        # self.lambda_str = get_lambda_source(self.lambda_f)
        self.lambda_str = lambda_f
        self.p4object = None
        if(not isinstance(counter, Counter)):
            raise TypeError('Counter_op works only on Counter object types')
        self.counter = counter

    def on_next(self, item):
        # self.counter.add(self.lambda_f(item))
        # self.lambda_f(item)
        self._notify_next(item)
        return True

    def on_compile(self, root, p4_program, ingress_egress_flag, parent_type):
        self.p4object = P4Table(self.table_name, None, { }, [])
        counter_ast = MafiaASTCounter(self.name, self.lambda_str)
        self.p4object +=  ( \
                            P4ActionBase(self.action_name, []) \
                            + \
                            (reduce((lambda x, y: x + y), counter_ast.compile(p4_program))) \
                          )
        p4_program.add_command("table_set_default" + " " + self.table_name + " "  + self.action_name)
        # p4_program.headers.register_mafia_metadata_field([(self.name+'_lambda_val', self.counter.width)])
        # tmp_lambda_result = "mafia_metadata."+self.name+"_lambda_val"

        # (lhs, [term, *expr]) = mafia_syntax_parse_counter(self.lambda_str)
        # lhs_symbol = mafia_syntax_interpret_symbol(lhs)
        # if not isinstance(lhs_symbol, MafiaSymbolStateVar):
        #     raise MafiaSemanticError("Semantic error: %s" % lhs, "Left-hand side of expression in Counter primitive is not referenceable")
        # p4_program.state.lookup(lhs_symbol.id)

        # action = P4ActionBase(self.action_name, [])
        # symbol = mafia_syntax_interpret_symbol(term)
        # if isinstance(symbol, MafiaSymbolDecimal) or isinstance(symbol, MafiaSymbolHeaderField) or isinstance(symbol, MafiaSymbolMetadata):
        #     action += P4ActionModifyField(self.action_name, tmp_lambda_result, symbol.id, [])
        # elif isinstance(symbol, MafiaSymbolStateVar):
        #     action += P4ActionRegisterRead(self.action_name, "mafia_metadata."+symbol.id, symbol.id, "mafia_metadata.flow_index", [])
        #     action += P4ActionModifyField(self.action_name, tmp_lambda_result, "mafia_metadata."+symbol.id, [])

        # while (expr):
        #     [op, term, *rest] = unpack_list(expr)

        #     expr = rest
        #     symbol = mafia_syntax_interpret_symbol(term)
        #     if isinstance(symbol, MafiaSymbolDecimal) or isinstance(symbol, MafiaSymbolHeaderField) or isinstance(symbol, MafiaSymbolMetadata):
        #         if op == "+":
        #             action += P4ActionFieldAdd(self.action_name, tmp_lambda_result, symbol.id)
        #         elif op == "-":
        #             action += P4ActionFieldSub(self.action_name, tmp_lambda_result, symbol.id)
        #         elif op == ">>":
        #             action += P4ActionFieldShiftRight(self.action_name, tmp_lambda_result, tmp_lambda_result, symbol.id)
        #         elif op == "<<":
        #             action += P4ActionFieldShiftLeft(self.action_name, tmp_lambda_result, tmp_lambda_result, symbol.id)
        #         else:
        #             raise MafiaSyntaxError("Syntax error: %s" % op, "Unknown arithmetic operation")
        #     elif isinstance(symbol, MafiaSymbolStateVar):
        #         p4_program.state.lookup(symbol.id)
        #         action += P4ActionRegisterRead(self.action_name, "mafia_metadata."+symbol.id, symbol.id, "mafia_metadata.flow_index", [])
        #         if op == "+":
        #             action += P4ActionFieldAdd(self.action_name, tmp_lambda_result, "mafia_metadata."+symbol.id)
        #         elif op == "-":
        #             action += P4ActionFieldSub(self.action_name, tmp_lambda_result, "mafia_metadata."+symbol.id)
        #         elif op == ">>":
        #             action += P4ActionFieldShiftRight(self.action_name, tmp_lambda_result, tmp_lambda_result, "mafia_metadata."+symbol.id)
        #         elif op == "<<":
        #             action += P4ActionFieldShiftLeft(self.action_name, tmp_lambda_result, tmp_lambda_result, "mafia_metadata."+symbol.id)
        #         else:
        #             raise MafiaSyntaxError("Syntax error: %s" % op, "Unknown arithmetic operation")
        # action += P4ActionRegisterWrite(self.action_name, lhs, tmp_lambda_result, "mafia_metadata.flow_index", [])
        # self.p4object += action

        return self.on_compile_return(ingress_egress_flag)

    def on_compile_return(self, flag):
        if not flag:
            return ([self.p4object], [])
        else:
            return ([], [self.p4object])

    def configure_table_commands(self, p4_program):
        p4_program.add_command("table_set_default " + self.table_name + " " + self.action_name)

    def __repr__(self):
        return "Counter_op [ %s, %s ]" % (self.lambda_str, self.counter.name)


class Timestamp_get(Operator):

    def __init__(self, name, timestamp):
        super(Timestamp_get, self).__init__()
        self.name = name
        self.table_name = "t_" + self.name
        self.action_name = 'a_' + self.name
        self.p4object = None
        if(not isinstance(timestamp, Timestamp)):
            raise TypeError('Timestamp_get works only on Timestamp object types')
        self.timestamp = timestamp

    def on_next(self, item):
        self._notify_next(item)
        return True

    def on_compile(self, root, p4_program, ingress_egress_flag, parent_type):
        
        self.p4object = P4Table(self.table_name, None, { }, []) \
                        + \
                        P4ActionGetTimestamp(self.action_name, self.timestamp.name, "mafia_metadata.flow_index", [])
        # self.p4object = P4Table(self.table_name, None, { }, []) \
        #                 + \
        #                 self.timestamp.write(self.action_name, "mafia_metadata."+self.timestamp.name)
        self.configure_table_commands(p4_program)
        return self.on_compile_return(ingress_egress_flag)

    def on_compile_return(self, flag):
        if not flag:
            return ([self.p4object], [])
        else:
            return ([], [self.p4object])

    def configure_table_commands(self, p4_program):
        p4_program.add_command("table_set_default " + self.table_name + " " + self.action_name)

    def _compile(self):
        pass

    def __repr__(self):
        return "Timestamp_get [ %s ]" % self.timestamp.name

class Sketch_op(Operator):
    def __init__(self, name, lambda_f, sketch):
        super(Sketch_op, self).__init__()
        self.name = name
        # self.lambda_f = lambda_f
        # self.lambda_str = get_lambda_source(self.lambda_f)
        self.lambda_str = lambda_f
        self.p4object = None
        if(not isinstance(sketch, Sketch)):
            raise TypeError('Sketch_op works only on Sketch object types')
        self.sketch = sketch

    def on_next(self, item):
        # self.counter.add(self.lambda_f(item))
        # self.lambda_f(item)
        self._notify_next(item)
        return True

    def compile_hash_function(self, p4_program, h):
        hash_fun = p4_program.lookup_hash(h)
        return hash_fun.compile(p4_program, self.name, h.n, h.inputs, h.outputs)

    def generate_sketch_index(self, h, row, col, nh):
        symbol_row = mafia_syntax_interpret_symbol(row)
        symbol_col = mafia_syntax_interpret_symbol(col)
        if isinstance(symbol_row, MafiaSymbolDecimal) or isinstance(symbol_row, MafiaSymbolHeaderField) or isinstance(symbol_row, MafiaSymbolMetadata):
            param_row = symbol_row.id
        elif isinstance(symbol_row, MafiaSymbolStateVar):
            param_row = "mafia_metadata."+h.family+"_"+symbol_row.id+"_"+str(nh)
        if isinstance(symbol_col, MafiaSymbolDecimal) or isinstance(symbol_col, MafiaSymbolHeaderField) or isinstance(symbol_col, MafiaSymbolMetadata):
            param_col = symbol_col.id
        elif isinstance(symbol_col, MafiaSymbolStateVar):
            param_col = "mafia_metadata."+h.family+"_"+symbol_col.id+"_"+str(nh)

        return (param_row, param_col)

    def on_compile(self, root, p4_program, ingress_egress_flag, parent_type):
        table_name = "t_" + self.name
        action_name = "a_" + self.name
        self.p4object = P4Table(table_name, None, {}, [])
        tmp = mafia_syntax_parse_sketch(self.lambda_str)
        (hashfun, [lhs, [term, *expr]]) = tmp
        (name, h) = p4_program.state.lookup(hashfun)
        if not isinstance(h, HashFunction):
            raise MafiaSemanticError("Semantic error: %s" % h, "Supplied function in lambda parameter is not an hash")

        table_hash = self.compile_hash_function(p4_program, h)

        (sketch, row, col) = mafia_syntax_parse_sketch_ref(lhs)
        (name, sketch_obj) = p4_program.state.lookup(sketch)
        p4_program.headers.register_mafia_metadata_field([(self.name+'_lambda_val', sketch_obj.width)])
        tmp_lambda_result = "mafia_metadata."+self.name+"_lambda_val"

        nh = 0
        action = P4ActionBase(action_name, [])
        while nh < h.n:
            # param = "mafia_metadata."+row+"_"+str(nh) + "*" + str(sketch_obj.m) + "+" + "mafia_metadata."+col+"_"+str(nh)
            (param_row, param_col) = self.generate_sketch_index(h, row, col, nh)
            param = param_row  + "*" + str(sketch_obj.m) + "+" + param_col
            # action += P4ActionRegisterRead(action_name, "mafia_metadata."+sketch_obj.name, sketch_obj.name, param, [])
            (hashfun, [lhs, [term, *expr]]) = tmp
            symbol = mafia_syntax_interpret_symbol(term)
            if isinstance(symbol, MafiaSymbolDecimal) or isinstance(symbol, MafiaSymbolHeaderField) or isinstance(symbol, MafiaSymbolMetadata):
                action += P4ActionModifyField(action_name, tmp_lambda_result, symbol.id, [])
            elif isinstance(symbol, MafiaSymbolStateVar):
                (name, var) = p4_program.state.lookup(symbol.id)
                if isinstance(var, HashOutputVar):
                    action += P4ActionModifyField(action_name, tmp_lambda_result, "mafia_metadata."+h.family+"_"+var.name+"_"+str(nh), [])
                else:
                    action += P4ActionRegisterRead(action_name, tmp_lambda_result, name, "mafia_metadata.flow_index", [])
            elif isinstance(symbol, MafiaSymbolStateVarSketch):
                # p4_program.state.lookup(symbol.id)
                action += P4ActionRegisterRead(action_name, tmp_lambda_result, self.sketch.name, param, [])
            else:
                raise MafiaSemanticError("Semantic error: \"%s\"", "Invalid symbol in BloomFilter primitive")

            while (expr):
                [op, term, *rest] = unpack_list(expr)
                expr = rest
                symbol = mafia_syntax_interpret_symbol(term)
                if isinstance(symbol, MafiaSymbolDecimal) or isinstance(symbol, MafiaSymbolHeaderField) or isinstance(symbol, MafiaSymbolMetadata):
                    if op == "+":
                        action += P4ActionFieldAdd(action_name, tmp_lambda_result, symbol.id)
                    elif op == "-":
                        action += P4ActionFieldSub(action_name, tmp_lambda_result, symbol.id)
                    elif op == ">>":
                        action += P4ActionFieldShiftRight(action_name, tmp_lambda_result, tmp_lambda_result, symbol.id)
                    elif op == "<<":
                        action += P4ActionFieldShiftLeft(action_name, tmp_lambda_result, tmp_lambda_result, symbol.id)
                    elif op == "&":
                        action += P4ActionFieldBitAnd(action_name, tmp_lambda_result, tmp_lambda_result, symbol.id)
                    elif op == "|":
                        action += P4ActionFieldBitOr(action_name, tmp_lambda_result, tmp_lambda_result, symbol.id)
                    else:
                        raise TypeError("Unknown arithmetic operation %s" % op)
                elif isinstance(symbol, MafiaSymbolStateVar):
                    p4_program.state.lookup(symbol.id)
                    if isinstance(var, HashOutputVar):
                        action += P4ActionModifyField(action_name, tmp_lambda_result, "mafia_metadata."+h.family+"_"+var.name+"_"+str(nh), [])
                    else:
                        action += P4ActionRegisterRead(action_name, "mafia_metadata."+symbol.id, symbol.id, "mafia_metadata.flow_index", [])

                    if op == "+":
                        action += P4ActionFieldAdd(action_name, tmp_lambda_result, "mafia_metadata."+symbol.id)
                    elif op == "-":
                        action += P4ActionFieldSub(action_name, tmp_lambda_result, "mafia_metadata."+symbol.id)
                    elif op == ">>":
                        action += P4ActionFieldShiftRight(action_name, tmp_lambda_result, tmp_lambda_result, "mafia_metadata."+symbol.id)
                    elif op == "<<":
                        action += P4ActionFieldShiftLeft(action_name, tmp_lambda_result, tmp_lambda_result, "mafia_metadata."+symbol.id)
                    elif op == "&":
                        action += P4ActionFieldBitAnd(action_name, tmp_lambda_result, tmp_lambda_result, "mafia_metadata."+symbol.id)
                    elif op == "|":
                        action += P4ActionFieldBitOr(action_name, tmp_lambda_result, tmp_lambda_result, "mafia_metadata."+symbol.id)
                    else:
                        raise TypeError("Unknown arithmetic operation %s" % op)
            action += P4ActionRegisterWrite(action_name, sketch_obj.name, tmp_lambda_result, param, [])
            nh += 1
        self.p4object += action

        p4_program.add_command("table_set_default " + table_name + " " + action_name)
        if not ingress_egress_flag:
            return (table_hash + [self.p4object], [])
        else:
            return ([], table_hash + [self.p4object])

    def __repr__(self):
        return "Sketch_op [ %s, %s ]" % (self.lambda_str, self.sketch.name)

class BloomFilter_op(Operator):
    def __init__(self, name, lambda_f, bf):
        super(BloomFilter_op, self).__init__()
        self.name = name
        # self.lambda_f = lambda_f
        # self.lambda_str = get_lambda_source(self.lambda_f)
        self.lambda_str = lambda_f
        self.p4object = None
        if(not isinstance(bf, BloomFilter)):
            raise TypeError('BloomFilter_op works only on BloomFilter object types')
        self.bf = bf

    def on_next(self, item):
        # self.counter.add(self.lambda_f(item))
        # self.lambda_f(item)
        self._notify_next(item)
        return True

    def compile_hash_function(self, p4_program, h):
        hash_fun = p4_program.lookup_hash(h)
        return hash_fun.compile(p4_program, self.name, h.n, h.inputs, h.outputs)

    def generate_bf_index(self, h, index, nh):
        symbol_index = mafia_syntax_interpret_symbol(index)
        if isinstance(symbol_index, MafiaSymbolDecimal) or isinstance(symbol_index, MafiaSymbolHeaderField) or isinstance(symbol_index, MafiaSymbolMetadata):
            param_index = symbol_index.id
        elif isinstance(symbol_index, MafiaSymbolStateVar):
            param_index = "mafia_metadata."+h.family+"_"+symbol_index.id+"_"+str(nh)

        return param_index

    def on_compile(self, root, p4_program, ingress_egress_flag, parent_type):
        table_name = "t_" + self.name
        action_name = "a_" + self.name
        self.p4object = P4Table(table_name, None, {}, [])
        tmp = mafia_syntax_parse_bf(self.lambda_str)
        (hashfun, [lhs, [term, *expr]]) = tmp
        (name, h) = p4_program.state.lookup(hashfun)
        if not isinstance(h, HashFunction):
            raise MafiaSemanticError("Semantic error: %s" % h, "Supplied function in lambda parameter is not an hash")

        table_hash = self.compile_hash_function(p4_program, h)

        (bf, index) = mafia_syntax_parse_bf_ref(lhs)
        (name, bf_obj) = p4_program.state.lookup(bf)
        p4_program.headers.register_mafia_metadata_field([(self.name+'_lambda_val', bf_obj.width)])
        tmp_lambda_result = "mafia_metadata."+self.name+"_lambda_val"

        nh = 0
        action = P4ActionBase(action_name, [])
        while nh < h.n:
            param = self.generate_bf_index(h, index, nh)
            (hashfun, [lhs, [term, *expr]]) = tmp
            symbol = mafia_syntax_interpret_symbol(term)
            if isinstance(symbol, MafiaSymbolDecimal) or isinstance(symbol, MafiaSymbolHeaderField) or isinstance(symbol, MafiaSymbolMetadata):
                action += P4ActionModifyField(action_name, tmp_lambda_result, symbol.id, [])
            elif isinstance(symbol, MafiaSymbolStateVar):
                (name, var) = p4_program.state.lookup(symbol.id)
                if isinstance(var, HashOutputVar):
                    action += P4ActionModifyField(action_name, tmp_lambda_result, 'mafia_metadata.'+name, [])
                else:
                    action += P4ActionRegisterRead(action_name, tmp_lambda_result, 'mafia_metadata.'+name, "mafia_metadata.flow_index", [])
            elif isinstance(symbol, MafiaSymbolStateVarBF):
                # p4_program.state.lookup(symbol.id)
                action += P4ActionRegisterRead(action_name, tmp_lambda_result, self.bf.name, param, [])
            else:
                raise MafiaSemanticError("Semantic error: \"%s\"", "Invalid symbol in BloomFilter primitive")

            while (expr):
                [op, term, *rest] = unpack_list(expr)
                expr = rest
                symbol = mafia_syntax_interpret_symbol(term)
                if isinstance(symbol, MafiaSymbolDecimal) or isinstance(symbol, MafiaSymbolHeaderField) or isinstance(symbol, MafiaSymbolMetadata):
                    if op == "+":
                        action += P4ActionFieldAdd(action_name, tmp_lambda_result, symbol.id)
                    elif op == "-":
                        action += P4ActionFieldSub(action_name, tmp_lambda_result, symbol.id)
                    elif op == ">>":
                        action += P4ActionFieldShiftRight(action_name, tmp_lambda_result, tmp_lambda_result, symbol.id)
                    elif op == "<<":
                        action += P4ActionFieldShiftLeft(action_name, tmp_lambda_result, tmp_lambda_result, symbol.id)
                    elif op == "&":
                        action += P4ActionFieldBitAnd(action_name, tmp_lambda_result, tmp_lambda_result, "mafia_metadata."+symbol.id)
                    elif op == "|":
                        action += P4ActionFieldBitOr(action_name, tmp_lambda_result, tmp_lambda_result, "mafia_metadata."+symbol.id)
                    else:
                        raise TypeError("Unknown arithmetic operation %s" % op)
                elif isinstance(symbol, MafiaSymbolStateVar):
                    p4_program.state.lookup(symbol.id)
                    (name, var) = p4_program.state.lookup(symbol.id)
                    if isinstance(var, HashOutputVar):
                        name = name+"_"+str(nh)
                        action += P4ActionModifyField(action_name, tmp_lambda_result, "mafia_metadata."+h.family+"_"+var.name+"_"+str(nh), [])
                    else:
                        action += P4ActionRegisterRead(action_name, "mafia_metadata."+name, name, "mafia_metadata.flow_index", [])
                    if op == "+":
                        action += P4ActionFieldAdd(action_name, tmp_lambda_result, "mafia_metadata."+name)
                    elif op == "-":
                        action += P4ActionFieldSub(action_name, tmp_lambda_result, "mafia_metadata."+name)
                    elif op == ">>":
                        action += P4ActionFieldShiftRight(action_name, tmp_lambda_result, tmp_lambda_result, "mafia_metadata."+name)
                    elif op == "<<":
                        action += P4ActionFieldShiftLeft(action_name, tmp_lambda_result, tmp_lambda_result, "mafia_metadata."+name)
                    elif op == "&":
                        action += P4ActionFieldBitAnd(action_name, tmp_lambda_result, tmp_lambda_result, "mafia_metadata."+name)
                    elif op == "|":
                        action += P4ActionFieldBitOr(action_name, tmp_lambda_result, tmp_lambda_result, "mafia_metadata."+name)
                    else:
                        raise TypeError("Unknown arithmetic operation %s" % op)
            action += P4ActionRegisterWrite(action_name, bf_obj.name, tmp_lambda_result, param, [])
            nh += 1
        self.p4object += action

        p4_program.add_command("table_set_default " + table_name + " " + action_name)
        if not ingress_egress_flag:
            return (table_hash + [self.p4object], [])
        else:
            return ([], table_hash + [self.p4object])

    def __repr__(self):
        return "BloomFilter_op [ %s, %s ]" % (self.lambda_str, self.bf.name)


class Tag(Operator):

    def __init__(self, name, lambda_f, field):
        super(Tag, self).__init__()
        self.name = name
        self.table_name = "t_" + self.name
        self.action_name = "a_" + self.name
        self.lambda_str = lambda_f
        self.p4object = None
        # if(not isinstance(field, P4HeaderField)):
        #     raise TypeError('Tag works only on P4HeaderField object types')
        self.field = field

    def on_next(self, item):
        self._notify_next(item)
        return True

    def on_compile(self, root, p4_program, ingress_egress_flag, parent_type):
        self.p4object = P4Table(self.table_name, None, {}, []) #+ P4ActionNoOp('_no_op')

        tmp = mafia_syntax_parse_tag(self.lambda_str)
        (term, *expr) = tmp

        (name, field) = p4_program.headers.lookup(self.field.split('.')[0], self.field.split('.')[1])

        p4_program.headers.register_mafia_metadata_field([(self.name+'_lambda_val', field.width)])
        tmp_lambda_result = "mafia_metadata."+self.name+"_lambda_val"

        nh = 0
        action = P4ActionBase(self.action_name, [])

        symbol = mafia_syntax_interpret_symbol(term)
        if isinstance(symbol, MafiaSymbolDecimal) or isinstance(symbol, MafiaSymbolHeaderField) or isinstance(symbol, MafiaSymbolMetadata):
            action += P4ActionModifyField(self.action_name, tmp_lambda_result, symbol.id, [])
        elif isinstance(symbol, MafiaSymbolStateVar):
            (name, var) = p4_program.state.lookup(symbol.id)
            action += P4ActionRegisterRead(self.action_name, tmp_lambda_result, name, "mafia_metadata.flow_index", [])
        elif isinstance(symbol, MafiaSymbolStateVarBF):
            (name, index) = mafia_syntax_parse_bf_ref(symbol.id)
            (bf_name, var) = p4_program.state.lookup(name)
            # action += P4ActionRegisterRead(action_name, tmp_lambda_result, name, index, [])
            for i in range(0,var.n):
                action += P4ActionRegisterRead(self.action_name, "mafia_metadata."+bf_name+"_serialized", bf_name, i, [])
                action += P4ActionFieldShiftLeft(self.action_name, "mafia_metadata."+bf_name+"_serialized", "mafia_metadata."+bf_name+"_serialized", var.n - 1 - i)
            
            action += P4ActionModifyField(self.action_name, tmp_lambda_result, "mafia_metadata."+bf_name+"_serialized", [])
        elif isinstance(symbol, MafiaSymbolStateVarSketch):
            (name, index_1, index_2) = mafia_syntax_parse_sketch_ref(symbol.id)
            (sketch_name, var) = p4_program.state.lookup(name)
            # action += P4ActionRegisterRead(action_name, tmp_lambda_result, name, index_1*symbol.m+index_2, [])

        while (expr):
            [op, term, *rest] = unpack_list(expr)
            expr = rest
            symbol = mafia_syntax_interpret_symbol(term)
            if isinstance(symbol, MafiaSymbolDecimal) or isinstance(symbol, MafiaSymbolHeaderField) or isinstance(symbol, MafiaSymbolMetadata):
                if op == "+":
                    action += P4ActionFieldAdd(self.action_name, tmp_lambda_result, symbol.id)
                elif op == "-":
                    action += P4ActionFieldSub(self.action_name, tmp_lambda_result, symbol.id)
                elif op == ">>":
                    action += P4ActionFieldShiftRight(self.action_name, tmp_lambda_result, tmp_lambda_result, symbol.id)
                elif op == "<<":
                    action += P4ActionFieldShiftLeft(self.action_name, tmp_lambda_result, tmp_lambda_result, symbol.id)
                elif op == "&":
                    action += P4ActionFieldBitAnd(self.action_name, tmp_lambda_result, tmp_lambda_result, symbol.id)
                elif op == "|":
                    action += P4ActionFieldBitOr(self.action_name, tmp_lambda_result, tmp_lambda_result, symbol.id)
                else:
                    raise TypeError("Unknown arithmetic operation %s" % op)
            elif isinstance(symbol, MafiaSymbolStateVar):
                p4_program.state.lookup(symbol.id)
                (name, var) = p4_program.state.lookup(symbol.id)
                action += P4ActionRegisterRead(self.action_name, "mafia_metadata."+name, name, "mafia_metadata.flow_index", [])
                if op == "+":
                    action += P4ActionFieldAdd(self.action_name, tmp_lambda_result, "mafia_metadata."+name)
                elif op == "-":
                    action += P4ActionFieldSub(self.action_name, tmp_lambda_result, "mafia_metadata."+name)
                elif op == ">>":
                    action += P4ActionFieldShiftRight(self.action_name, tmp_lambda_result, tmp_lambda_result, "mafia_metadata."+name)
                elif op == "<<":
                    action += P4ActionFieldShiftLeft(self.action_name, tmp_lambda_result, tmp_lambda_result, "mafia_metadata."+name)
                elif op == "&":
                    action += P4ActionFieldBitAnd(self.action_name, tmp_lambda_result, tmp_lambda_result, "mafia_metadata."+name)
                elif op == "|":
                    action += P4ActionFieldBitOr(self.action_name, tmp_lambda_result, tmp_lambda_result, "mafia_metadata."+name)
                else:
                    raise TypeError("Unknown arithmetic operation %s" % op)
        action += P4ActionModifyField(self.action_name, self.field, tmp_lambda_result, [])
        self.p4object += action

        self.configure_table_commands(p4_program)
        return self.on_compile_return(ingress_egress_flag)

    def on_compile_return(self, flag):
        if not flag:
            return ([self.p4object], [])
        else:
            return ([], [self.p4object])

    def configure_table_commands(self, p4_program):
        p4_program.add_command("table_set_default " + self.table_name + " " + self.action_name)

    def _compile(self):
        pass

    def __repr__(self):
        return "Tag [ %s ]" % self.field

class Stream_op(Operator):
    def __init__(self, name, stream):
        super(Stream_op, self).__init__()
        self.name = name
        self.table_name = "t_" + self.name
        self.action_name = "a_" + self.name
        self.stream = stream
        self.p4object = None
        if(not isinstance(stream, Stream)):
            raise TypeError('Stream_op works only on Stream object types')

    def on_next(self, item):
        self._notify_next(item)
        return True

    def on_compile(self, root, p4_program, ingress_egress_flag, parent_type):
        # self.p4object = P4Table(self.table_name, "standard_metadata.instance_type == " + str(self.stream.identifier), {}, []) #+ P4ActionNoOp('_no_op')
        self.p4object = P4Table(self.table_name, "standard_metadata.instance_type == 1", {}, [])
        return ([], [self.p4object])

    def _compile(self):
        pass

    def __repr__(self):
        return "Stream_op [ %s ]" % self.stream.name

class Duplicate(Operator):
    def __init__(self, name, stream):
        super(Duplicate, self).__init__()
        self.name = name
        self.table_name = "t_" + self.name
        self.action_name = "a_" + self.name
        self.stream = stream
        self.p4object = None

    def on_next(self, item):
        self._notify_next(item)
        return True

    def on_compile(self, root, p4_program, ingress_egress_flag, parent_type):
        self.p4object = P4Table(self.table_name, None, {}, []) \
                        + \
                        P4ActionDuplicate(self.action_name, str(self.stream.identifier), 'sample_copy_fields', [])
        self.configure_table_commands(p4_program)
        return self.on_compile_return(ingress_egress_flag)


    def on_compile_return(self, flag):
        if not flag:
            return ([self.p4object], [])
        else:
            raise MafiaSemanticError("Semantic error", "Duplicate in egress pipeline not allowed")

    def configure_table_commands(self, p4_program):
        p4_program.add_command("table_set_default " + self.table_name + " " + self.action_name)
        p4_program.add_command("mirroring_add " + str(self.stream.identifier) + " 0")

    def _compile(self):
        pass

    def __repr__(self):
        return "Duplicate [ %s ]" % self.stream.name

class Collect(Operator):
    def __init__(self, name, endpoint_spec):
        super(Collect, self).__init__()
        self.name = name
        self.endpoint_spec = endpoint_spec
        self.table_name = "t_" + self.name
        self.action_name = "a_" + self.name
        self.p4object = None
        if not self.endpoint_spec:
            raise MafiaSemanticError("Semantic error", "Missing endpoint specification in Collect primitive")

    def on_next(self, item):
        self._notify_next(item)
        return True

    def on_compile(self, root, p4_program, ingress_egress_flag, parent_type):
        self.p4object = P4Table(self.table_name, None, {}, [])
        actions = list()
        actions += [P4ActionAddHeader("a_header_vlan", "vlan")]
        for spec in self.endpoint_spec:
            (lhs, rhs) = mafia_syntax_parse_assignment(spec)
            lhs_symbol = mafia_syntax_interpret_symbol(lhs)
            rhs_symbol = mafia_syntax_interpret_symbol(rhs)
            if not isinstance(lhs_symbol, MafiaSymbolHeaderField): #and not isinstance(rhs_symbol, MafiaSymbolConstant):
                raise MafiaSemanticError("Semantic error: %s" % spec, "Invalid endpoint specification parameter")
            actions += [P4ActionModifyField(self.action_name, lhs_symbol.id, rhs, [])]
        self.p4object += (reduce((lambda x, y: x + y), actions))
        self.configure_table_commands(p4_program)
        return self.on_compile_return(ingress_egress_flag)

    def on_compile_return(self, flag):
        if not flag:
            return ([self.p4object], [])
        else:
            return ([], [self.p4object])

    def configure_table_commands(self, p4_program):
        p4_program.add_command("table_set_default " + self.table_name + " " + self.action_name)

    def _compile(self):
        pass

    def __repr__(self):
        return "Collect [ %s ]" % (','.join(spec for spec in self.endpoint_spec))

class Random_op(Operator):
    def __init__(self, name, min_bound, max_bound):
        super(Random_op, self).__init__()
        self.name = name
        self.min_bound = min_bound
        self.max_bound = max_bound
        self.table_name = "t_" + self.name
        self.action_name = "a_" + self.name
        self.p4object = None

    def on_next(self, item):
        self._notify_next(item)
        return True

    def on_compile(self, root, p4_program, ingress_egress_flag, parent_type):
        p4_program.headers.register_mafia_metadata_field([(self.name, 32)])
        self.p4object = P4Table("t_" + self.name, None, {}, []) \
                        + \
                        P4ActionHash(self.action_name, "mafia_metadata."+self.name, "uniform_probability_hash", self.max_bound, [])
        self.configure_table_commands(p4_program)
        return self.on_compile_return(ingress_egress_flag)

    def on_compile_return(self, flag):
        if not flag:
            return ([self.p4object], [])
        else:
            return ([], [self.p4object])

    def configure_table_commands(self, p4_program):
        p4_program.add_command("table_set_default " + self.table_name + " " + self.action_name)

    def _compile(self):
        pass

    def __repr__(self):
        return "Random_op [ {%d:%d} ]" % (self.min_bound, self.max_bound)

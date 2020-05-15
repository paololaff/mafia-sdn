
import re
from ..exception import *

# identifier
regex_var = r'[a-zA-Z_^.^\d]+'
# serialize
regex_serialize = r'serialize\([a-zA-Z_^.^\d]+\)'
# bf identifier
regex_var_bf = r'[a-zA-Z_]+\[.*\]'
regex_var_bf_ref = r'([a-zA-Z_]+)\[(.*)\]'
# sketch identifier
regex_var_sketch = r'[a-zA-Z_]+\[.+\]\[.+\]'
regex_var_sketch_ref = r'([a-zA-Z_]+)\[(.+)\]\[(.+)\]'
# metadata
regex_metadata = r'metadata\.[a-zA-Z_]+'
# header_field
regex_header_field = r'(eth|ipv4|vlan|tcp)\.[a-zA-Z_]+'
regex_header_field_ref = r'[eth|ipv4|vlan|tcp]\.[a-zA-Z_]+'
# regex_id = r'[a-zA-Z\._]+'
# ipv4 address
regex_ip = r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'
regex_ip_cidr = r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/\d'
# decimal constant
regex_binary = r'0[b|B][01]+'
# decimal constant
regex_hexadecimal = r'0[x|X][0-9ABCDEFabcdef]+'
# decimal constant
regex_decimal = r'[0-9]+'
# numeric constant
regex_numeric_const = r''+regex_binary+r'|'+regex_hexadecimal+r'|'+regex_decimal+r''
# arithmetic operation
regex_arithm_op = r'[+|-]|[<|>]{2}|\*|/|\||\&}'
# bool operation
regex_bool_op = r'>|<|>=|<=|[=]{2}|!=}'
# match 
regex_match = r'(.+)\s*([=]{2}|>|<|>=|<=|!=)\s*(.+)\s*'
# trigger
regex_trigger = r'lambda (.*):\s*(.+)\s*([=]{2}|>|<|[!=]|>=|<=)\s*(.+)\s*'
# tag
regex_lambda_tag = r'lambda\s*(.+)'
# lambda_counter
regex_lambda_counter = r'lambda\s*\(\s*\)\s*:\s*{\s*(.+)\s*\}'
# lambda_sketch
regex_lambda_bf = r'lambda\s*\((.+)\)\s*:\s*{\s*(.+)\s*}'
# lambda_sketch
regex_lambda_sketch = r'lambda\s*\((.+)\)\s*:\s*{\s*(.+)\s*}'
# sigma reading function
regex_sigma = r'sigma\s*\((.+)\):\s*{\s*(.+)\s*}'
# aggregate identifier
regex_aggregate_id = r'min|max|sum|avg|all|any'
# aggregate function
regex_aggregate = r'(.+)\s*\((.+)\)\s*:\s*{\s*(.+)\s*}'
# identifier 
regex_identifier = r''+regex_var_sketch+r'|'+regex_var_bf+r'|'+regex_var+r'|'+regex_numeric_const
# regex lhs
regex_lhs = r''+regex_var_sketch+r'|'+regex_var+r'|'+regex_var_bf
# assignment
regex_assign = r'('+regex_lhs+r')\s*=\s*(.+)'
# arithmetic expression
regex_arithm_expr = r''+regex_metadata+r'|'+regex_header_field_ref+r'|'+regex_var_sketch+r'|'+regex_var_bf+r'|'+regex_serialize+r'|'+regex_var+r'|'+regex_numeric_const+r'|'+regex_arithm_op
# regex_arithm_expr = r''+regex_metadata+r'|'+regex_header_field_ref+r'|'+regex_var_sketch+r'|'+regex_var_bf+r'|'+regex_serialize+r'|'+regex_var+r'|'+regex_numeric_const+r'\s*'+regex_arithm_op+r'*'

regex_bool_expr = r'(.+)\s*('+regex_bool_op+r')\s*(.+)'

def mafia_syntax_parse_match(expr):
    if expr is None:
        raise MafiaError("Syntax error", "Match primitive requires a boolean expression")
    if not len(expr):
        raise MafiaSyntaxError("Syntax error", "Empty expression in Match primitive")
    else:
        regex = re.match( regex_match, expr, re.M|re.I)
        if(not regex):
            raise MafiaSyntaxError("Syntax error: %s" % expr, "Malformed boolean expression in Match")
        else:
            lhs = regex.group(1).strip()
            bool_op = regex.group(2).strip()
            rhs = regex.group(3).strip()
            # print((lhs,bool_op,rhs))
            return (lhs, bool_op, rhs)



# def mafia_syntax_parse_counter(counter_lambda):
#     if counter_lambda is None:
#         raise MafiaSyntaxError("Syntax error", "Lambda function for Counter primitive is not provided.")
#     if not len(counter_lambda):
#         raise MafiaSyntaxError("Syntax error", " -> Empty lambda function in Counter primitive")
#     else:
#         regex = re.match( regex_lambda_counter, counter_lambda, re.M|re.I)
#         if(not regex):
#             raise MafiaSyntaxError("Syntax error: %s" % counter_lambda, "Malformed lambda function in Counter primitive")
#         else:
#             assignment = regex.group(1).strip()
#             (lhs, rhs) = mafia_syntax_parse_assignment(assignment)
#             expression = mafia_syntax_parse_arithmetic(rhs)
#             return (lhs, expression)

def mafia_syntax_parse_counter(counter_lambda):
    if counter_lambda is None:
        raise MafiaSyntaxError("Syntax error", "Lambda function for Counter primitive is not provided.")
    if not len(counter_lambda):
        raise MafiaSyntaxError("Syntax error", " -> Empty lambda function in Counter primitive")
    else:
        regex = re.match( regex_lambda_counter, counter_lambda, re.M|re.I)
        if(not regex):
            raise MafiaSyntaxError("Syntax error: %s" % counter_lambda, "Malformed lambda function in Counter primitive")
        else:
            assignment = regex.group(1).strip()
            (lhs, rhs) = mafia_syntax_parse_assignment(assignment)
            return (lhs, rhs)

def mafia_syntax_parse_sketch(sketch_lambda):
    if sketch_lambda is None:
        raise MafiaSyntaxError("Syntax error", "Lambda function for Sketch primitive is not provided.")
    if not len(sketch_lambda):
        raise MafiaSyntaxError("Syntax error", "Empty lambda function in Sketch primitive")
    else:
        regex = re.match( regex_lambda_sketch, sketch_lambda, re.M|re.I)
        if(not regex):
            raise MafiaSyntaxError("Syntax error: %s" % sketch_lambda, "Malformed lambda function for Sketch primitive")
        else:
            hashfun = regex.group(1).strip()
            (lhs, rhs) = mafia_syntax_parse_assignment(regex.group(2))
            expression = mafia_syntax_parse_arithmetic(rhs)
            # print(assignment)
            return (hashfun, (lhs, expression))

def mafia_syntax_parse_sketch_ref(sketch_ref):
    if sketch_ref is None:
        raise MafiaSyntaxError("Syntax error", "Expression to access sketch variable is not provided.")
    if not len(sketch_ref):
        raise MafiaSyntaxError("Syntax error", "Empty expression to access sketch variable")
    else:
        regex = re.match( regex_var_sketch_ref, sketch_ref, re.M|re.I)
        if(not regex):
            raise MafiaSyntaxError("Syntax error: %s" % sketch_ref, "Invalid indexing of sketch variable")
        else:
            var = regex.group(1)
            index_1 = regex.group(2)
            index_2 = regex.group(3)
            return (var, index_1, index_2)

def mafia_syntax_parse_bf(bf_lambda):
    if bf_lambda is None:
        raise MafiaSyntaxError("Syntax error", "Lambda function for BloomFilter primitive is not provided.")
    if not len(bf_lambda):
        raise MafiaSyntaxError("Syntax error", "Empty lambda function in BloomFilter primitive")
    else:
        regex = re.match( regex_lambda_bf, bf_lambda, re.M|re.I)
        if(not regex):
            raise MafiaSyntaxError("Syntax error: %s" % bf_lambda, "Malformed lambda function for BloomFilter primitive")
        else:
            hashfun = regex.group(1).strip()
            assignment = regex.group(2).strip()
            (lhs, rhs) = mafia_syntax_parse_assignment(assignment)
            expression = mafia_syntax_parse_arithmetic(rhs)
            # print(assignment)
            return (hashfun, (lhs, expression))

def mafia_syntax_parse_bf_ref(bf_ref):
    if bf_ref is None:
        raise MafiaSyntaxError("Syntax error", "Expression to access bloom filter variable is not provided.")
    if not len(bf_ref):
        raise MafiaSyntaxError("Syntax error", "Empty expression to access bloom filter variable")
    else:
        regex = re.match( regex_var_bf_ref, bf_ref, re.M|re.I)
        if(not regex):
            raise MafiaSyntaxError("Syntax error: %s" % bf_ref, "Invalid indexing of bloom filter variable")
        else:
            var = regex.group(1)
            index_1 = regex.group(2)
            return (var, index_1)

# def mafia_syntax_parse_tag(tag_lambda):
#     if tag_lambda is None:
#         raise MafiaSyntaxError("Syntax error", "Lambda function for Tag primitive is not provided.")
#     if not len(tag_lambda):
#         raise MafiaSyntaxError("Syntax error", "Empty lambda function in Tag primitive.")
#     else:
#         regex = re.match( regex_identifier, tag_lambda, re.M|re.I)
#         if(not regex):
#             raise MafiaSyntaxError("Syntax error: %s" % tag_lambda, "Malformed lambda function for Tag primitive.")
#         else:
#             return regex.group(0).strip()

def mafia_syntax_parse_tag(tag_lambda):
    if tag_lambda is None:
        raise MafiaSyntaxError("Syntax error", "Lambda function for Tag primitive is not provided.")
    if not len(tag_lambda):
        raise MafiaSyntaxError("Syntax error", "Empty lambda function in Tag primitive.")
    else:
        return mafia_syntax_parse_arithmetic(tag_lambda)

def mafia_syntax_parse_aggregate(aggregate_lambda):
    if aggregate_lambda is None:
        raise MafiaSyntaxError("Syntax error", "Lambda function for aggregate function is not provided.")
    if not len(aggregate_lambda):
        raise MafiaSyntaxError("Syntax error", "Empty lambda function in aggregate function.")
    else:
        regex = re.search( regex_aggregate, aggregate_lambda, re.M|re.I)
        if(not regex):
            raise MafiaSyntaxError("Syntax error: %s" % aggregate_lambda, "Malformed aggregate function")
        else:
            fun = regex.group(1).strip()
            hashset = regex.group(2).strip()
            expr = regex.group(3).strip()
            return (fun, hashset, expr)

def mafia_syntax_parse_assignment(assignment):
    if assignment is None:
        raise MafiaSyntaxError("Syntax error", "Assignment in lambda function is not provided")
    if not len(assignment):
        raise MafiaSyntaxError("Syntax error", "Empty assignement")
    else:
        regex = re.search( regex_assign, assignment, re.M|re.I)
        if(not regex):
            raise MafiaSyntaxError("Syntax error: %s" % assignment, "Malformed assignment")
        else:
            lhs = regex.group(1).strip()
            assignment = regex.group(2).strip()
            return (lhs, assignment)

def  mafia_syntax_parse_arithmetic(arithmetic):
    if arithmetic is None:
        raise MafiaSyntaxError("Syntax error", "Arithmetic expression is not provided.")
    if not len(arithmetic):
        raise MafiaSyntaxError("Syntax error", " Empty arithmetic expression.")
    else:
        regex = re.findall( regex_arithm_expr, arithmetic, re.M|re.I)
        if(not regex):
            raise MafiaSyntaxError("Syntax error: %s" % arithmetic, "Invalid arithmetic expression")
        if((len(regex)%2) != 1):
            raise MafiaSyntaxError("Syntax error: %s" % arithmetic, "Invalid arithmetic expression")
        return regex

def  mafia_syntax_parse_boolean(bool_expr):
    if bool_expr is None:
        raise MafiaSyntaxError("Syntax error", "Arithmetic expression is not provided.")
    if not len(bool_expr):
        raise MafiaSyntaxError("Syntax error", " Empty arithmetic expression.")
    else:
        regex = re.match( regex_bool_expr, bool_expr, re.M|re.I)
        if(not regex):
            raise MafiaSyntaxError("Syntax error: %s" % bool_expr, "Invalid boolean expression")
        lhs = regex.group(1).strip()
        bool_op = regex.group(2).strip()
        rhs = regex.group(3).strip()
        return (lhs, bool_op, rhs)

def mafia_syntax_interpret_bool_op(op):
    if ((op == '==') or (op == '>=') or (op == '>') or (op == '<') or (op == '<=') or (op == '!=')):
        return op
    else:
        raise MafiaSyntaxError("Syntax error: %s" % op, "Invalid boolean operator")

def mafia_syntax_interpret_arithmetic_op(op):
    if ((op != '+') or (op != '-') or (op != '>>') or (op != '<<') or (op != '*') or (op != '/')):
        raise MafiaSyntaxError("Syntax error: %s" % op, "Invalid arithmetic operator")
    else:
        return op

def mafia_syntax_interpret_aggregate_func(func):
    regex = re.match( regex_aggregate_id, func, re.M|re.I)
    if(not regex):
        raise MafiaSyntaxError("Syntax error: %s" % func, "Invalid aggregation function")
    else:
        return regex.group(1)

def mafia_syntax_check_ip_address(addr):
    regex = re.match( regex_ip_cidr, addr, re.M|re.I)
    if(not regex):
        regex = re.match( regex_ip_cidr, addr, re.M|re.I)
        if(not regex):
            regex = re.match( regex_ip, addr, re.M|re.I)
            if(not regex):
                raise MafiaSyntaxError("Syntax error: %s" % addr,"Invalid ip address")
    return regex.group(1)

def mafia_syntax_sanitize_metadata(metadata):
    if metadata == 'metadata.input_port':
        return 'standard_metadata.ingress_port'
    elif metadata == 'metadata.output_port':
        return 'standard_metadata.egress_port'
    elif metadata == 'metadata.switch_id':
        return 'mafia_metadata.switch_id'
    elif metadata == 'metadata.packet_length':
        return 'standard_metadata.packet_length'
    elif metadata == 'metadata.is_first_hop':
        return 'mafia_metadata.is_first_hop'
    elif metadata == 'metadata.is_last_hop':
        return 'mafia_metadata.is_last_hop'
    elif metadata == 'metadata.queue_length':
        return 'queueing_metadata.enq_qdepth'
    elif metadata == 'metadata.enq_qdepth':
        return 'queueing_metadata.enq_qdepth'
    elif metadata == 'metadata.deq_qdepth':
        return 'queueing_metadata.deq_qdepth'
    elif metadata == 'metadata.queue_delay':
        return 'queueing_metadata.deq_timedelta'
    elif metadata == 'metadata.queue_timestamp':
        return 'queueing_metadata.enq_timestamp'
    
    else:
        raise MafiaSemanticError("Semantic error: %s" % metadata, "Invalid metadata identifier")

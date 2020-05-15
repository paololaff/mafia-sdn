
from mafia_lang.primitives import *

borders = Counter('borders', 4, 32)

not_tagged_from_border = Match("is_not_tagged_from_border", "ipv4.identification == 0", None) \
                     >> Tag("set_border_tag", "1", "ipv4.identification")

tagged_from_border = Match("is_tagged_from_border", "ipv4.identification != 0", None)

update_border_counter = Counter_op( 'update_border_counter',   "lambda(): { borders = borders + 1 }", borders )

measurement = Match( 'match_tcp', "ipv4.protocol == 0x06", None) >> (tagged_from_border + not_tagged_from_border + (update_border_counter))



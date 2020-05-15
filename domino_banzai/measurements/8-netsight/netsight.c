


struct Packet {
  int ipv4_src;
  int ipv4_dst;
  int tcp_src;
  int tcp_dst;
  int ipv4_proto;

  int tag_input_port;
  int tag_output_port;
  int tag_switch_id;
  
  int m_input_port;
  int m_output_port;
  int m_switch_id;
};


void func(struct Packet p) {
  p.tag_input_port = p.m_input_port;
  p.tag_output_port = p.m_output_port;
  p.tag_switch_id = p.m_switch_id;
}

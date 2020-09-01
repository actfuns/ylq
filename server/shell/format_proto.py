
import commands
import re

class CFormat(object):
    def __init__(self):
        self.m_defines_c2s = {}
        self.m_defines_s2c = {}
        self.m_proto_c2s = {}
        self.m_proto_s2c = {}


    def process_defines(self, file_name):
        p1 = re.compile("(?P<defines>\S+)\.(?P<collection>\S+)(.*)=(.*){")
        p2 = re.compile("(?P<proto>\S+)(.*)=([^0-9]+)(?P<value>\d+),")
        with open(file_name) as fp:
            for line in fp.readlines():
                line = line.strip()
                group_result = p1.match(line)
                if group_result:
                    define = group_result.group("defines").strip()
                    coll = group_result.group("collection").strip()
                    table = self.get_table(define)
                    self.init_table(table, coll)
                    
                proto_result = p2.match(line)
                if proto_result:
                    proto = proto_result.group("proto").strip()
                    value = proto_result.group("value").strip()
                    table[coll][proto] = int(value)


    def process_proto(self, file_list):
        for file_name in file_list:
            if "base/common.proto" in file_name:
                continue
            if "cs_common" not in file_name:
                continue
            name_list = file_name.split("/")
            define = name_list[-2]
            coll = name_list[-1].split(".")[0]
            table = self.get_table(define)
            self.init_table(table, coll)

            p = re.compile("(message)(.)(?P<func>\S+)(.*){")
            with open(file_name) as fp:
                for line in fp.readlines():
                    func_result = p.match(line)
                    if not func_result: continue

                    func = func_result.group("func")
                    #func = func.split("{")[0]
                    if func in table[coll]: continue

                    if not func.startswith("GS2C") and not func.startswith("C2GS"):
                        continue

                    table[coll][func] = 0


    def get_all_file(self):
        all_file = []
        status, result = commands.getstatusoutput("find . |grep -E 'netdefines\.lua$'")
        if not status:
            all_file.append(result)
        status, result = commands.getstatusoutput("find . |grep -E '\.proto$'")
        if not status:
            all_file.append(result)
        return all_file


    def do_process(self):
        all_file = self.get_all_file()

        file_defines = all_file[0]
        self.process_defines(file_defines)

        proto_file_list = all_file[1].split("\n")
        self.process_proto(proto_file_list)


        self.gen_result(self.m_defines_c2s, self.m_proto_c2s)
        self.gen_result(self.m_defines_s2c, self.m_proto_s2c)

        self.do_output(file_defines)


    def get_table(self, source):
        if source.startswith("C2GS"):
            return self.m_defines_c2s
        elif source.startswith("GS2C"):
            return self.m_defines_s2c
        elif source == "client":
            return self.m_proto_c2s
        elif source == "server":
            return self.m_proto_s2c


    def init_table(self, table, key):
        if key not in table:
            table[key] = {}


    def gen_result(self, defines_table, proto_table):
        new_coll_list = []
        sup_coll_list = []
        sort_coll_table = {}
        for coll, info in proto_table.items():
            if coll not in defines_table:
                new_coll_list.append(coll)
                continue
            for name, value in info.items():
                if name not in defines_table[coll]:
                    sup_coll_list.append((coll, name))
                    continue
                proto_table[coll][name] = defines_table[coll][name]

        for coll, info in defines_table.items():
            for name, value in info.items():
                sort_coll_table[coll] = value/1000
                break

        for coll,name in sup_coll_list:
            range_value = sort_coll_table[coll]
            proto_value = self.choose_proto_val(proto_table, coll, range_value)
            proto_table[coll][name] = proto_value

        for coll in new_coll_list:
            range_value = self.get_range_value(sort_coll_table)
            sort_coll_table[coll] = range_value
            for name, _ in proto_table[coll].items():
                proto_value = self.choose_proto_val(proto_table, coll, range_value)
                proto_table[coll][name] = proto_value
                


    def choose_proto_val(self, proto_table, coll, range_value):
        start_val = range_value*1000 + 1
        while start_val in proto_table[coll].values():
            start_val += 1
        return start_val


    def get_range_value(self, sort_table):
        start_val = 1
        while start_val in sort_table.values():
            start_val += 1
        return start_val


    def format_proto_define(self, type):
        #type = client or server
        table = self.get_table(type)
        pto_value = {}
        for coll, info in table.items():
            for name, value in info.items():
                pto_value[coll] = value/1000
                break
            
        coll_list = sorted(table.keys(), \
                    lambda x,y: pto_value[x] <= pto_value[y] and -1 or 1)

        content_list = []
        for coll in coll_list:
            ret = self.format_table(type, coll, table[coll])
            content_list.append(ret)

        return "\n".join(content_list)


    def format_table(self, type, coll, table):
        if type == "client":
            templ = """C2GS_DEFINES.%s = {\n$content}\n""" % (coll,)
        else:
            templ = "GS2C_DEFINES.%s = {\n$content}\n""" % (coll,)

        proto_list = sorted(table.keys(), lambda x, y: table[x] < table[y] and -1 or 1)
        string_list = []
        string_templ = "    %s = %s,"
        for proto in proto_list:
            string_list.append(string_templ % (proto, table[proto]))
        
        return templ.replace("$content", ("\n".join(string_list)+"\n"))



    def do_output(self, file_name):
        fp = file(file_name, "r")
        all_content = fp.read()
        idx_client_start = all_content.index("--C2GS BEGIN")
        idx_client_end = all_content.index("--C2GS END")
        
        start = all_content[0:idx_client_start+len("--C2GS BEGIN")]
        end = all_content[idx_client_end:]
        content = start + "\n\n" + self.format_proto_define("client") + end
        fp.close()
        fp = file(file_name, "w")
        fp.write(content)
        fp.close()

        fp = file(file_name, "r")
        all_content = fp.read()
        idx_server_start = all_content.index("--GS2C BEGIN")
        idx_server_end = all_content.index("--GS2C END")
        start = all_content[0:idx_server_start+len("--GS2C BEGIN")]
        end = all_content[idx_server_end:]
        content = start + "\n\n" + self.format_proto_define("server") + end
        fp.close()
        fp = file(file_name, "w")
        fp.write(content)
        fp.close()




if __name__ == "__main__":
    obj = CFormat()
    obj.do_process()

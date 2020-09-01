
import string
import pymongo

class CGenShowIdMgr(object):

    def __init__(self):
        self.m_result = {}
        self.m_sHost = "127.0.0.1"
        self.m_iPort = 27017
        self.m_sUser = "root"
        self.m_sPwd = "bCrfAptbKeW8YoZU"
        self.m_db = "game"
        self.m_table = "showid"
    

    def gen_match(self, match_list, pre, tail, filter):
        start, combine_list = 1, []
        for str_match in match_list:
            combine_list.append(self.gen_element(str_match, start))
            start = 0

        self.combine(combine_list, pre, tail, filter)


    def combine(self, combine_list, pre, tail, filter):
        for element_list in combine_list[0]:
            str_tmp = "".join(self.convert_string(element_list))
            source = "%s%s$replace%s" % (pre, str_tmp, tail)
            self.combine1(source, combine_list, 1, filter)


    def combine1(self, source, combine_list, idx, filter):
        if idx >= len(combine_list):
            result = source.replace("$replace", "")
            if self.get_serial_val(result, "4") >= 2: return
            if self.check_all_same(result, filter): return
            if not result.isdigit() or int(result) < 1100: return

            self.m_result[int(result)] = {"status":0, "occupy":0}
            #print result

        else:
            for element_list in combine_list[idx]:
                str_tmp = "".join(self.convert_string(element_list))
                source_tmp = source.replace("$replace", "%s$replace" % (str_tmp,))
                self.combine1(source_tmp, combine_list, idx+1, filter)


    def gen_element(self, match, start):
        if not match: return

        key = match[0]
        char_list =[]
        for char in match:
            char_list.append(ord(char) - ord(key))

        length = len(match)
        result = []
        for i in range(start, 10):
            tmp = [delta + i for delta in char_list if 10 > delta + i >= 0]
            if len(tmp) < length: continue

            result.append(tmp)

        return result


    def convert_string(self, element_list):
        return [str(i) for i in element_list]


    def get_serial_val(self, source, val):
        if not val: return 0

        cnt, max_cnt, last = 0, 0, source[0]
        for char in source:
            if char == val:
                if val != last:
                    cnt = 1
                else:
                    cnt += 1
                max_cnt = max(cnt, max_cnt)
            else:
                cnt = 0
            last = char

        return max_cnt


    def check_all_same(self, source, filter):
        if not filter: return False
        if not source: return False
        return source.count(source[0]) == len(source)


    def insert_data_to_mongo(self):
        conn = pymongo.MongoClient("mongodb://%s:%s@%s:%d/"%(self.m_sUser, self.m_sPwd, self.m_sHost, self.m_iPort))
        coll = conn[self.m_db][self.m_table]
        coll.ensure_index("show_id", unique=True, name="show_id_index")
        for show_id, data in self.m_result.iteritems():
            insert_info = {"show_id":show_id, "data":data}
            coll.insert(insert_info)
        conn.close()

    def check_insert(self):
        conn = pymongo.MongoClient("mongodb://%s:%s@%s:%d/"%(self.m_sUser, self.m_sPwd, self.m_sHost, self.m_iPort))
        coll = conn[self.m_db][self.m_table]
        return coll.count() <= 0


all_match_list = {
    1:{"match_list":["A", "B", "C", "D",], "pre":"", "tail":"", "filter":0},
    2:{"match_list":["A", "BBBB",], "pre":"", "tail":"", "filter":1},
    3:{"match_list":["AAAA", "B",], "pre":"", "tail":"", "filter":1},
    4:{"match_list":["AA", "BBB",], "pre":"", "tail":"", "filter":1},
    5:{"match_list":["AA", "ABC",], "pre":"", "tail":"", "filter":0},
    6:{"match_list":["AA", "CBA",], "pre":"", "tail":"", "filter":0},
    7:{"match_list":["ABCDE",], "pre":"", "tail":"", "filter":0},
    8:{"match_list":["EDCBA",], "pre":"", "tail":"", "filter":0},
    9:{"match_list":["AAAAA",], "pre":"", "tail":"", "filter":0},
    10:{"match_list":["AAA", "BBB",], "pre":"", "tail":"", "filter":1},
    11:{"match_list":["AA", "BBBB",], "pre":"", "tail":"", "filter":1},
    12:{"match_list":["AAAA", "BB",], "pre":"", "tail":"", "filter":1},
    13:{"match_list":["AAAAA", "B",], "pre":"", "tail":"", "filter":1},
    14:{"match_list":["A", "BBBBB",], "pre":"", "tail":"", "filter":1},
    15:{"match_list":["ABC", "ABC",], "pre":"", "tail":"", "filter":0},
    16:{"match_list":["CBA", "CBA",], "pre":"", "tail":"", "filter":0},
    17:{"match_list":["AAAAAA",], "pre":"", "tail":"", "filter":0},
    18:{"match_list":["A", "B",], "pre":"520", "tail":"", "filter":0},
    19:{"match_list":["A",], "pre":"1314", "tail":"", "filter":0},
    20:{"match_list":["A", "B",], "pre":"1314", "tail":"", "filter":0},
    21:{"match_list":["A", "B", "C",], "pre":"520", "tail":"", "filter":0},
    22:{"match_list":["A", "B", "C", "D",], "pre":"520", "tail":"", "filter":0},
    23:{"match_list":["A", "B", "C",], "pre":"1314", "tail":"", "filter":0},
}

if __name__ == "__main__":
    obj = CGenShowIdMgr()
    if obj.check_insert():
        print ("generate showid start")
        for idx, match_info in all_match_list.items():
            match_list = match_info["match_list"]
            pre = match_info["pre"]
            tail = match_info["tail"]
            filter = match_info["filter"]
            obj.gen_match(match_list, pre, tail, filter)
    
        obj.insert_data_to_mongo()
        print ("generate showid end")
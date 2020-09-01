# coding=utf-8
from __future__ import division
from __future__ import absolute_import
from __future__ import print_function
from __future__ import unicode_literals
from future import standard_library
from future.builtins import *
#py3 compatibility

import sys
import codecs
from inspect import currentframe
from locale import getpreferredencoding
from os import (listdir, mkdir,makedirs)
from os.path import (isfile, join, splitext, exists, basename)
from collections import defaultdict

from xlrd import open_workbook, XLRDError
import unicodecsv as csv


if not sys.stdout.encoding:
    reload(sys)
    sys.setdefaultencoding("utf-8")
output_encoding = sys.stdout.encoding
if not output_encoding or output_encoding == 'US-ASCII' or output_encoding == 'ascii':
    output_encoding = 'utf-8'
print('check output encoding', output_encoding)

if sys.stderr.encoding == 'cp936':
    class UnicodeStreamFilter(object):
        def __init__(self, target):
            self.target = target
            self.encoding = 'utf-8'
            self.errors = 'replace'
            self.encode_to = self.target.encoding

        def write(self, s):
            if isinstance(s, bytes):
                s = s.decode('utf-8')
            s = s.encode(self.encode_to, self.errors).decode(self.encode_to)
            self.target.write(s)
    sys.stderr = UnicodeStreamFilter(sys.stderr)

#encoding = getpreferredencoding()


begin_temple = """
return {
"""
row_temple = """
    [%s] = {
"""
cell_temple = """\
        %s = %s,
"""
row_end_temple = """\
    },
"""
end_temple = """
}
"""

def assertx(value, message):
    if __debug__ and not value:
        #tb =
        #f = sys.exc_info()[2].tb_frame.f_back
        #back_frame = currentframe().f_back
        #lineno = back_frame.f_lineno - 1
        #filename = back_frame.f_code.co_filename
        #source = '\n' * lineno + 'assert False'
        try:
            code = compile('1 / 0', '', 'eval')
            exec(code)
        except ZeroDivisionError:
            tb = sys.exc_info()[2].tb_next
            assert tb
            raise AssertionError, str(message).encode('utf-8'), tb
    return value

def csv_from_excel(xls_name):
    workbook = open_workbook(xls_name)#, encoding_override='gbk')
    #sh = wb.sheet_by_name('Sheet1')
    for sheet in workbook.sheets():
        with open(sheet.name + '.csv', 'wb') as csv_file:
            writer = csv.writer(csv_file, quoting=csv.QUOTE_NONNUMERIC)
            for rownum in range(sheet.nrows):
                writer.writerow(sheet.row_values(rownum))

#基础类型
type_tbl = {
    'int': int,
    'float': float,
    'string': str,
    'formula': str,
}


default_tbl = {
    'int': 0,
    'float': 0.0,
    'string': '',
    'formula': '',
}

legal_extra_types = ('default', 'key', 'ignored')

row_keys_ = {}
row_values_ = {}

def cell_to_value(col_type, value):
    if col_type.startswith('struct'):
        templates = col_type.split("(")[1].split(")")[0]
        template_lst = templates.split("|")
        value = str(value)
        values = value.strip()
        value_lst = values.split("|")
        value = {}
        for i, j in enumerate(template_lst):
            if i >= len(value_lst):
                break
            if j.find("[") != -1 and j.find("]") != -1:
                key = j.split("[")[1].split("]")[0]
                sub_col_type = j.split("[")[0]
            else:
                key = i + 1
                sub_col_type = j
            value[key] = cell_to_value(sub_col_type, value_lst[i])

    elif col_type in type_tbl:
        if col_type == 'int':
            try:
                value = int(value)
            except:
                value = int(eval(value))
        elif col_type == 'float':
            try:
                value = float(value)
            except:
                value = eval(value)
        elif col_type == 'string':
            try:
                fv = int(value)
                if fv == value:
                    value = fv
            except:
                pass

            value = str(value)
        else:
            value = type_tbl[col_type](value)

    else:
        try:
            value = int(value)
            value = unicode(value)
        except:
            pass
        enum_name_tbl = enum_tbl[col_type]

        if enum_name_tbl.has_key(value):
            value = enum_name_tbl[value]
        else:
            try:
                value = int(value)
            except:
                assertx(False, '未定义枚举值[%s]' % (value))
            assertx(value in enum_name_tbl.values(), '未定义枚举值[%s]' % (value))

    return value


def sheet_to_dict(sheet,key_name):
    type_row = sheet.row_values(0)
    name_row = sheet.row_values(1)
    col_types = []
    row_key = None
    ignored_names = []
    for i, column in enumerate(type_row):
        try:
            if not column:
                print('info: colume %d is empty, ignore others behind' % (i + 1))
                type_row = type_row[:i]
                break
            col_type = column
            if column.find('@') != -1:
                col_type, extra_type = column.split('@')
                assertx(extra_type in legal_extra_types,
                        '@incorrect suffix after[%s], can only be %s' % (extra_type, ' '.join(legal_extra_types)))
                if extra_type == 'ignored':
                    ignored_names.append(name_row[i])
                elif extra_type == 'key':
                    row_key = name_row[i]
                    row_keys_[key_name] = row_key
            #assertx(name_row[i], '命名不能为空: 列%s' % i)
            if col_type.startswith('list'):
                val_type = col_type.split('<')[1].split('>')[0]
                if val_type not in type_tbl and not val_type.startswith('struct'):
                    assertx(val_type in enum_tbl, 'unknown emum type:[%s]' % val_type)
                col_type = 'list'

            elif col_type.startswith('dict'):
                val_type = col_type.split('<')[1].split('>')[0]
                if val_type not in type_tbl and not val_type.startswith('struct'):
                    assertx(val_type in enum_tbl, 'unknown emum type[%s]' % val_type)
                col_type = 'dict'

            elif col_type not in type_tbl and not col_type.startswith('struct'):
                assertx(col_type in enum_tbl, 'unknown emum type[%s]' % col_type)

            col_types.append(col_type)
        except:
            print('ERROR: row:%s column:[%s] ' % (i + 1, column))
            raise

    normal_name_tbl = {}
    list_name_tbl = defaultdict(list)
    for i, name in enumerate(name_row):
        if name.find('|') != -1:
            #print(name)
            list_name_tbl[name].append(i)
        else:
            normal_name_tbl[name] = i

    title_row = sheet.row_values(2)
    keys_ = {}
    empty_row = set([''])
    for rownum in range(3, sheet.nrows):
        try:
            row = sheet.row_values(rownum)
            if set(row) == empty_row:
                break
            null_index_tbl = {}
            for i, column in enumerate(type_row):
                null_index_tbl[i] = (row[i] == '')

                col_type = col_types[i]

                if col_type == 'list':
                    if row[i] == '':
                        row[i] = []
                    else:
                        row[i] = str(row[i])
                        val_type = column.split('<')[1].split('>')[0]
                        values = [val.strip() for val in row[i].split(',')]
                        row[i] = [cell_to_value(val_type, val) for val in values]

                elif col_type == 'dict':
                    if row[i] == '':
                        row[i] = {}
                    else:
                        row[i] = str(row[i])
                        val_type = column.split('<')[1].split('>')[0]
                        values = [val.strip() for val in row[i].split(',')]
                        lsts = [cell_to_value(val_type, val) for val in values]
                        row[i] = {val['id']:val for val in lsts}

                elif row[i] == '' and (column.endswith('@default') or column.endswith('@ignored')):
                    if col_type in type_tbl:
                        row[i] = default_tbl[col_type]
                    elif col_type.startswith('struct'):
                        row[i] = {}
                    else:
                        row[i] = 0

                else:
                    assertx(row[i] != '', 'line%s column[%s] can not be empty' % (rownum + 1, title_row[i]))
                    row[i] = cell_to_value(col_type, row[i])
                    if name_row[i] == row_key:
                        assertx(row[i] not in keys_,
                                ' DUPLICATE key row:%s vs row:%s' % (title_row[i], row[i]))
                        keys_[row[i]] = True
            data = {}
            for name, index in normal_name_tbl.iteritems():
                if name == '':
                    continue
                if name in ignored_names:
                    continue
                data[name] = row[index]
            list_name_len_tbl = {}
            for name, indexes in list_name_tbl.iteritems():
                choosed_indexs = []
                first = False
                for i in reversed(indexes):
                    if not first and null_index_tbl[i]:
                        continue
                    if not first:
                        first = True
                    choosed_indexs.append(i)
                old_name = name
                name_num, name = name.split('|')
                data[name] = [
                    row[i] for i in reversed(choosed_indexs)]
                if name_num:
                    data_len = list_name_len_tbl.get(name_num)
                    if data_len:
                        assertx(len(data[name]) == data_len,
                        '合并列[%s]的长度[%s]与同组[%s]合并列长度[%s]不一致' %
                                (old_name, len(data[name]), name_num, data_len))
                    else:
                        list_name_len_tbl[name_num] = len(data[name])
        except:
            print('ERROR: row: %s column: %s[%s]' % (rownum + 1, i, title_row[i]))
            raise
        yield data


def format_value(value):
    if isinstance(value, basestring):
        if '\n' in value:
            form = '[=[%s]=]'
        elif '"' in value:
            form = '[[%s]]' if "'" in value else "'%s'"
        else:
            form = '"%s"'

        return form % value
    elif isinstance(value, list):
        value = ', '.join([format_value(v) for v in value])
        value = '{%s}' % value

    elif isinstance(value, dict):
        value = ', '.join(["[%s] = %s"%(format_value(k), format_value(v)) for k, v in value.items()])
        value = '{%s}' % value

    return str(value)

def to_lua(name, data, xls_name, output):
    if not exists(output):
        makedirs(output)
    key_name = xls_name + name
    with open(join(output, name + '.lua'), 'wb') as file:
        comment = '-- %s' % xls_name.replace("\\","/")
        file.write(comment.encode("utf-8"))
        file.write(begin_temple.encode("utf-8"))
        for i, row in enumerate(data):

            row_key_name = row_keys_.get(key_name, 'id')
            key = row.get(row_key_name, i + 1)

            if isinstance(key, basestring):
                key = format_value(key)
            file.write((row_temple % key).encode("utf-8"))

            lrow = row.keys()
            lrow.sort()

            for _, key in enumerate(lrow):
                value = row[key]
                if isinstance(value, basestring):
                    value = format_value(value)
                elif isinstance(value, list):
                    value = ', '.join([format_value(v) for v in value])
                    value = '{%s}' % value
                elif isinstance(value, dict):
                    lvalue = value.keys()
                    lvalue.sort()
                    value = ', '.join(["[%s] = %s"%(format_value(k), format_value(value[k])) for _, k in enumerate(lvalue)])
                    value = '{%s}' % value

                cell = cell_temple % (key, value)
                file.write(cell.encode("utf-8"))
            file.write(row_end_temple.encode("utf-8"))
        file.write(end_temple.encode("utf-8"))

def excel_sheets(*args, **kw):
    with open_workbook(*args, on_demand=True, ragged_rows=True, **kw) as (
    book):
        for i in range(book.nsheets):
            try:
                yield book.sheet_by_index(i)
            finally:
                book.unload_sheet(i)


def sheet_row_values(sheet, rowx):
    return (sheet.cell_value(rowx, colx)
            for colx in range(sheet.row_len(rowx)))


def convet(xls_name, output):
    workbook = open_workbook(xls_name)#, encoding_override='gbk')
    for sheet in workbook.sheets():
        if sheet.nrows == 0:
            continue
        if sheet.name.startswith('_'):
            print('-- ignored:[%s]' % (sheet.name.encode(output_encoding)))
            continue
        try:
            print('converting...: ', xls_name.encode(output_encoding), sheet.name.encode(output_encoding))
            key_name = xls_name + sheet.name
            data = sheet_to_dict(sheet,key_name)

            to_lua(sheet.name, data, xls_name, output)
        except Exception as e:
            print('convert FAILED', xls_name.encode(output_encoding), sheet.name.encode(output_encoding))
            raise


enum_tbl = {}

def convet_enumerate(xls_name, path):
    assertx(isfile(xls_name), 'enumerate.xls is required')
    with open_workbook(xls_name, on_demand=True) as workbook:
        assertx(workbook.nsheets == 1, 'only one sheet for enum')
        sheet = workbook.sheet_by_index(0)
    key_name = xls_name + "enumerate"
    for row in sheet_to_dict(sheet,key_name):
        enum_name = row['enum_name']
        with open_workbook(path + row['file_name'], on_demand=True) as workbook:
            try:
                sheet = workbook.sheet_by_name(row['sheet_name'])
            except XLRDError as e:
                print('convert enum failed')
                print('%s does not contain sheet named: %s' % (row['file_name'], row['sheet_name']))
                raise

        try:
            name_row = sheet.row_values(1)
            id_index = name_row.index('id')
            name_index = name_row.index('name')
            name_to_id = {}
            idx_ = {}
            pre_name_to_id = enum_tbl.get(enum_name)
            if pre_name_to_id:
                pre_idx_ = set(pre_name_to_id.itervalues())
            for rowx in range(3, sheet.nrows):
                idx = sheet.cell_value(rowx, id_index)
                if idx == '':
                   break
                name = sheet.cell_value(rowx, name_index)
                assertx(name not in name_to_id, '枚举名重复[%s]' % name)
                assertx(idx not in idx_, '枚举名ID重复[%s]' % idx)
                if pre_name_to_id:
                    assertx(name not in pre_name_to_id, '与其他同类型表 枚举名重复[%s]' % name)
                    assertx(idx not in pre_idx_, '与其他同类型表 枚举名ID重复[%s]' % idx)

                try:
                    name = int(name)
                    name = unicode(name)
                except:
                    pass

                name_to_id[name] = int(idx)
                idx_[idx] = True
            if pre_name_to_id:
                pre_name_to_id.update(name_to_id)
                name_to_id = pre_name_to_id
            enum_tbl[enum_name] = name_to_id
        except Exception as e:
            print('enum error:', row['file_name'])
            raise

def convet_xls_file(path, output):
    root, ext = splitext(path)
    if ext != '.xlsx' and ext != '.xls':
        return
    head = basename(path)
    if head.startswith('_'):
        return
    convet(path, output)


if __name__ == '__main__':
    PATH = './excel/'
    OUTPUT = 'luadata/'

    convet_enumerate(join(PATH, 'enumerate.xlsx'), PATH)
    def recu(pth, output):
        for name in listdir(pth):
            p = join(pth, name)
            if name[0] != "~":
                if not isfile(p):
                    recu(p, join(output, name))
                    continue
                else:
                    print(p.encode(output_encoding))
                    convet_xls_file(p, output)

    recu(PATH, OUTPUT)
